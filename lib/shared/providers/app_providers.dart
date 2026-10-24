import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/models/models.dart';
import '../../core/network/supabase_service.dart';
import '../../core/utils/dz_locations.dart';

// ============================================================
// 1) BOOTSTRAP
// ============================================================
final bootstrapProvider = FutureProvider<void>((ref) async {
  await SupabaseService.init();
  await DzLocations.instance.load();
  final prefs = await SharedPreferences.getInstance();
  ref.read(roleProvider.notifier).hydrate(prefs.getString('persona'));
});

// ============================================================
// 2) PERSONA (merchant / customer)
// ============================================================
class RoleNotifier extends StateNotifier<String?> {
  RoleNotifier() : super(null);

  void hydrate(String? stored) {
    if (stored != null) state = stored;
  }

  Future<void> pick(String persona) async {
    state = persona;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('persona', persona);
  }

  Future<void> clear() async {
    state = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('persona');
  }
}

final roleProvider = StateNotifierProvider<RoleNotifier, String?>((ref) => RoleNotifier());

// ============================================================
// 3) AUTH
// ============================================================
final authStateProvider = StreamProvider<AuthState>((ref) {
  if (!SupabaseService.instance.isReady) return const Stream.empty();
  return SupabaseService.instance.auth.onAuthStateChange;
});

final currentUserProvider = Provider<User?>((ref) {
  if (!SupabaseService.instance.isReady) return null;
  return SupabaseService.instance.user;
});

final profileProvider = FutureProvider<Profile?>((ref) async {
  final svc = SupabaseService.instance;
  if (!svc.isReady || svc.user == null) return null;
  final data = await svc.client
      .from('profiles')
      .select()
      .eq('id', svc.user!.id)
      .maybeSingle();
  if (data == null) return null;
  return Profile.fromMap(data);
});

// ============================================================
// 4) LOCATIONS
// ============================================================
final wilayasProvider = Provider<List<Wilaya>>((ref) => DzLocations.instance.wilayas);

// ============================================================
// 5) STORE (merchant's own store) / PUBLIC STORE (customer)
// ============================================================
final myStoreProvider = FutureProvider<Store?>((ref) async {
  final svc = SupabaseService.instance;
  if (!svc.isReady || svc.user == null) return null;
  final data = await svc.client
      .from('stores')
      .select()
      .eq('owner_id', svc.user!.id)
      .maybeSingle();
  return data == null ? null : Store.fromMap(data);
});

/// المتجر المعروض في واجهة الزبون (أول متجر مفعّل)
final publicStoreProvider = FutureProvider<Store?>((ref) async {
  final svc = SupabaseService.instance;
  if (!svc.isReady) return null;
  final rows = await svc.client
      .from('stores')
      .select()
      .eq('is_active', true)
      .order('created_at')
      .limit(1);
  if ((rows as List).isEmpty) return null;
  return Store.fromMap((rows.first as Map).cast<String, dynamic>());
});

// ============================================================
// 6) CART (customer) — محلية بالكامل، ما تحتاجش تسجيل
// ============================================================
class CartNotifier extends StateNotifier<Cart> {
  CartNotifier() : super(const Cart());

  void add(Product p, {ProductVariant? variant, int qty = 1}) {
    final key = '${p.id}:${variant?.id ?? ''}';
    final idx = state.lines.indexWhere((l) => l.key == key);
    final List<CartLine> next = List.of(state.lines);
    if (idx >= 0) {
      next[idx] = next[idx].copyWith(qty: next[idx].qty + qty);
    } else {
      next.add(CartLine(product: p, variant: variant, qty: qty));
    }
    state = state.copyWith(lines: next, storeId: p.storeId);
  }

  void setQty(String key, int qty) {
    final next = state.lines
        .map((l) => l.key == key ? l.copyWith(qty: qty) : l)
        .where((l) => l.qty > 0)
        .toList();
    state = state.copyWith(lines: next);
  }

  void remove(String key) {
    state = state.copyWith(lines: state.lines.where((l) => l.key != key).toList());
  }

  void clear() => state = const Cart();

  int qtyOf(String productId, String? variantId) {
    final key = '$productId:${variantId ?? ''}';
    for (final l in state.lines) {
      if (l.key == key) return l.qty;
    }
    return 0;
  }
}

final cartProvider = StateNotifierProvider<CartNotifier, Cart>((ref) => CartNotifier());

// ============================================================
// 7) PRODUCTS (customer catalog)
// ============================================================
class CatalogFilter {
  final String? categoryId;
  final String query;
  final String sort; // newest | price_asc | price_desc | popular
  const CatalogFilter({this.categoryId, this.query = '', this.sort = 'newest'});

  CatalogFilter copyWith({String? categoryId, String? query, String? sort, bool clearCat = false}) =>
      CatalogFilter(
        categoryId: clearCat ? null : (categoryId ?? this.categoryId),
        query: query ?? this.query,
        sort: sort ?? this.sort,
      );
}

final catalogFilterProvider =
    StateProvider<CatalogFilter>((ref) => const CatalogFilter());

final categoriesProvider = FutureProvider<List<Category>>((ref) async {
  final svc = SupabaseService.instance;
  if (!svc.isReady) return const [];
  final store = await ref.watch(publicStoreProvider.future);
  if (store == null) return const [];
  final rows = await svc.client
      .from('categories')
      .select()
      .eq('store_id', store.id)
      .eq('is_active', true)
      .order('position');
  return (rows as List).map((e) => Category.fromMap((e as Map).cast<String, dynamic>())).toList();
});

final productsProvider = FutureProvider<List<Product>>((ref) async {
  final svc = SupabaseService.instance;
  if (!svc.isReady) return const [];
  final store = await ref.watch(publicStoreProvider.future);
  if (store == null) return const [];
  final f = ref.watch(catalogFilterProvider);

  final base = svc.client
      .from('products')
      .select()
      .eq('store_id', store.id)
      .eq('is_active', true);

  final filtered = switch (f.sort) {
    'price_asc' => base.order('price', ascending: true),
    'price_desc' => base.order('price', ascending: false),
    'popular' => base.order('sold_count', ascending: false),
    _ => base.order('created_at', ascending: false),
  };

  var rows = await filtered;

  // فلترة محلية (تجنّباً لتعقيد أنواع Postgrest)
  if (f.categoryId != null) {
    rows = rows.where((r) => (r as Map)['category_id'] == f.categoryId).toList();
  }
  if (f.query.trim().isNotEmpty) {
    final q = f.query.trim().toLowerCase();
    rows = rows.where((r) =>
        ((r as Map)['title'] ?? '').toString().toLowerCase().contains(q)).toList();
  }
  return (rows as List).map((e) => Product.fromMap((e as Map).cast<String, dynamic>())).toList();
});

final featuredProductsProvider = FutureProvider<List<Product>>((ref) async {
  final svc = SupabaseService.instance;
  if (!svc.isReady) return const [];
  final store = await ref.watch(publicStoreProvider.future);
  if (store == null) return const [];
  final rows = await svc.client
      .from('products')
      .select()
      .eq('store_id', store.id)
      .eq('is_active', true)
      .eq('is_featured', true)
      .order('created_at', ascending: false)
      .limit(10);
  return (rows as List).map((e) => Product.fromMap((e as Map).cast<String, dynamic>())).toList();
});

final productProvider = FutureProvider.family<Product?, String>((ref, id) async {
  final svc = SupabaseService.instance;
  if (!svc.isReady) return null;
  final data = await svc.client.from('products').select().eq('id', id).maybeSingle();
  if (data == null) return null;
  final vrows = await svc.client
      .from('product_variants')
      .select()
      .eq('product_id', id)
      .eq('is_active', true);
  final variants = (vrows as List)
      .map((e) => ProductVariant.fromMap((e as Map).cast<String, dynamic>()))
      .toList();
  return Product.fromMap(data, variants: variants);
});

// ============================================================
// 8) ORDERS (merchant) — مع Realtime
// ============================================================
final orderStatusFilterProvider = StateProvider<OrderStatus?>((ref) => null);

final merchantOrdersProvider = FutureProvider<List<Order>>((ref) async {
  final svc = SupabaseService.instance;
  if (!svc.isReady) return const [];
  final store = await ref.watch(myStoreProvider.future);
  if (store == null) return const [];

  final filter = ref.watch(orderStatusFilterProvider);
  var q = svc.client.from('orders').select().eq('store_id', store.id);
  if (filter != null) q = q.eq('status', filter.db);
  final rows = await q.order('created_at', ascending: false).limit(200);

  final orders = (rows as List)
      .map((e) => Order.fromMap((e as Map).cast<String, dynamic>()))
      .toList();
  return orders;
});

final orderDetailProvider = FutureProvider.family<Order?, String>((ref, id) async {
  final svc = SupabaseService.instance;
  if (!svc.isReady) return null;
  final data = await svc.client.from('orders').select().eq('id', id).maybeSingle();
  if (data == null) return null;
  final items = await svc.client.from('order_items').select().eq('order_id', id);
  return Order.fromMap(
    data,
    items: (items as List)
        .map((e) => OrderItem.fromMap((e as Map).cast<String, dynamic>()))
        .toList(),
  );
});

/// يعيد بناء الطلبات لحظياً عند أي تغيير في جدول orders
final ordersRealtimeProvider = StreamProvider<void>((ref) {
  final svc = SupabaseService.instance;
  if (!svc.isReady) return const Stream.empty();
  final store = ref.watch(myStoreProvider).valueOrNull;
  if (store == null) return const Stream.empty();
  return svc.client
      .from('orders')
      .stream(primaryKey: ['id'])
      .eq('store_id', store.id)
      .map((_) {})
      .handleError((_) {});
});

// ============================================================
// 9) LEADS (abandoned carts)
// ============================================================
final leadsProvider = FutureProvider<List<AbandonedLead>>((ref) async {
  final svc = SupabaseService.instance;
  if (!svc.isReady) return const [];
  final store = await ref.watch(myStoreProvider.future);
  if (store == null) return const [];
  final rows = await svc.client
      .from('abandoned_leads')
      .select()
      .eq('store_id', store.id)
      .order('created_at', ascending: false)
      .limit(100);
  return (rows as List)
      .map((e) => AbandonedLead.fromMap((e as Map).cast<String, dynamic>()))
      .toList();
});

// ============================================================
// 10) STATS
// ============================================================
final storeStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final svc = SupabaseService.instance;
  if (!svc.isReady) return const {};
  final store = await ref.watch(myStoreProvider.future);
  if (store == null) return const {};
  final res = await svc.client.rpc('store_stats', params: {
    'p_store_id': store.id,
    'p_days': 30,
  });
  return (res as Map?)?.cast<String, dynamic>() ?? const {};
});

// ============================================================
// 11) NOTIFICATIONS
// ============================================================
final unreadCountProvider = FutureProvider<int>((ref) async {
  final svc = SupabaseService.instance;
  if (!svc.isReady) return 0;
  final store = await ref.watch(myStoreProvider.future);
  if (store == null) return 0;
  final rows = await svc.client
      .from('notifications')
      .select('id')
      .eq('store_id', store.id)
      .eq('is_read', false);
  return (rows as List).length;
});
