import 'package:flutter/foundation.dart';

/// ============================================================
/// نماذج البيانات — تُطابق جداول Supabase حرفياً
/// ============================================================

enum UserRole { merchant, customer }

enum OrderStatus { newOrder, confirmed, canceled, postponed, inDelivery, delivered }

extension OrderStatusX on OrderStatus {
  String get db => switch (this) {
        OrderStatus.newOrder => 'new',
        OrderStatus.confirmed => 'confirmed',
        OrderStatus.canceled => 'canceled',
        OrderStatus.postponed => 'postponed',
        OrderStatus.inDelivery => 'in_delivery',
        OrderStatus.delivered => 'delivered',
      };

  String get ar => switch (this) {
        OrderStatus.newOrder => 'جديد',
        OrderStatus.confirmed => 'تم التأكيد',
        OrderStatus.canceled => 'ملغى',
        OrderStatus.postponed => 'مؤجل',
        OrderStatus.inDelivery => 'قيد التوصيل',
        OrderStatus.delivered => 'تم التوصيل',
      };

  String get icon => switch (this) {
        OrderStatus.newOrder => '🆕',
        OrderStatus.confirmed => '✅',
        OrderStatus.canceled => '✖️',
        OrderStatus.postponed => '⏸️',
        OrderStatus.inDelivery => '🚚',
        OrderStatus.delivered => '📦',
      };

  static OrderStatus fromDb(String? v) => switch (v) {
        'confirmed' => OrderStatus.confirmed,
        'canceled' => OrderStatus.canceled,
        'postponed' => OrderStatus.postponed,
        'in_delivery' => OrderStatus.inDelivery,
        'delivered' => OrderStatus.delivered,
        _ => OrderStatus.newOrder,
      };

  /// الإجراءات الممكنة من الحالة الحالية
  List<OrderStatus> get next => switch (this) {
        OrderStatus.newOrder => [OrderStatus.confirmed, OrderStatus.postponed, OrderStatus.canceled],
        OrderStatus.postponed => [OrderStatus.confirmed, OrderStatus.canceled],
        OrderStatus.confirmed => [OrderStatus.inDelivery, OrderStatus.canceled],
        OrderStatus.inDelivery => [OrderStatus.delivered, OrderStatus.canceled],
        OrderStatus.delivered => [],
        OrderStatus.canceled => [],
      };
}

enum DeliveryMode { home, stopdesk }

extension DeliveryModeX on DeliveryMode {
  String get db => this == DeliveryMode.home ? 'home' : 'stopdesk';
  String get ar => this == DeliveryMode.home ? 'توصيل للمنزل' : 'توصيل للمكتب';
  static DeliveryMode fromDb(String? v) =>
      v == 'stopdesk' ? DeliveryMode.stopdesk : DeliveryMode.home;
}

@immutable
class Profile {
  final String id;
  final String? fullName;
  final String? phone;
  final String? email;
  final UserRole role;
  final String? avatarUrl;

  const Profile({
    required this.id, this.fullName, this.phone,
    this.email, this.role = UserRole.customer, this.avatarUrl,
  });

  factory Profile.fromMap(Map<String, dynamic> m) => Profile(
        id: m['id'] as String,
        fullName: m['full_name'] as String?,
        phone: m['phone'] as String?,
        email: m['email'] as String?,
        role: (m['role'] as String?) == 'merchant' ? UserRole.merchant : UserRole.customer,
        avatarUrl: m['avatar_url'] as String?,
      );

  bool get isMerchant => role == UserRole.merchant;
}

@immutable
class Store {
  final String id;
  final String ownerId;
  final String name;
  final String? slug;
  final String? description;
  final String? logoUrl;
  final String? phone;
  final String? whatsapp;
  final String? wilayaCode;
  final String? communeName;
  final String? address;
  final bool homeDelivery;
  final bool stopdesk;
  final num? freeShipOver;

  const Store({
    required this.id, required this.ownerId, required this.name,
    this.slug, this.description, this.logoUrl, this.phone, this.whatsapp,
    this.wilayaCode, this.communeName, this.address,
    this.homeDelivery = true, this.stopdesk = true, this.freeShipOver,
  });

  factory Store.fromMap(Map<String, dynamic> m) => Store(
        id: m['id'] as String,
        ownerId: m['owner_id'] as String,
        name: m['name'] as String,
        slug: m['slug'] as String?,
        description: m['description'] as String?,
        logoUrl: m['logo_url'] as String?,
        phone: m['phone'] as String?,
        whatsapp: m['whatsapp'] as String?,
        wilayaCode: m['wilaya_code'] as String?,
        communeName: m['commune_name'] as String?,
        address: m['address'] as String?,
        homeDelivery: (m['home_delivery'] as bool?) ?? true,
        stopdesk: (m['stopdesk'] as bool?) ?? true,
        freeShipOver: m['free_ship_over'] as num?,
      );

  Map<String, dynamic> toMap() => {
        'owner_id': ownerId,
        'name': name,
        'slug': slug,
        'description': description,
        'logo_url': logoUrl,
        'phone': phone,
        'whatsapp': whatsapp,
        'wilaya_code': wilayaCode,
        'commune_name': communeName,
        'address': address,
        'home_delivery': homeDelivery,
        'stopdesk': stopdesk,
        'free_ship_over': freeShipOver,
      };
}

@immutable
class Category {
  final String id;
  final String storeId;
  final String name;
  final String? imageUrl;
  final int position;

  const Category({
    required this.id, required this.storeId, required this.name,
    this.imageUrl, this.position = 0,
  });

  factory Category.fromMap(Map<String, dynamic> m) => Category(
        id: m['id'] as String,
        storeId: m['store_id'] as String,
        name: m['name'] as String,
        imageUrl: m['image_url'] as String?,
        position: (m['position'] as int?) ?? 0,
      );
}

@immutable
class VariantSchemaItem {
  final String name;
  final List<String> options;
  const VariantSchemaItem({required this.name, required this.options});

  factory VariantSchemaItem.fromMap(Map<String, dynamic> m) => VariantSchemaItem(
        name: m['name'] as String? ?? '',
        options: (m['options'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      );
  Map<String, dynamic> toMap() => {'name': name, 'options': options};
}

@immutable
class ProductVariant {
  final String id;
  final String productId;
  final String label;
  final Map<String, dynamic> options;
  final num? price;
  final int stock;
  final String? imageUrl;

  const ProductVariant({
    required this.id, required this.productId, required this.label,
    this.options = const {}, this.price, this.stock = 0, this.imageUrl,
  });

  factory ProductVariant.fromMap(Map<String, dynamic> m) => ProductVariant(
        id: m['id'] as String,
        productId: m['product_id'] as String,
        label: m['label'] as String,
        options: (m['options'] as Map?)?.cast<String, dynamic>() ?? const {},
        price: m['price'] as num?,
        stock: (m['stock'] as int?) ?? 0,
        imageUrl: m['image_url'] as String?,
      );
}

@immutable
class Product {
  final String id;
  final String storeId;
  final String? categoryId;
  final String title;
  final String? description;
  final num price;
  final num? comparePrice;
  final int stock;
  final List<String> images;
  final List<VariantSchemaItem> variantSchema;
  final String? badge;
  final bool isActive;
  final bool isFeatured;
  final int soldCount;
  final int views;
  final List<ProductVariant> variants;

  const Product({
    required this.id, required this.storeId, required this.title,
    this.categoryId, this.description, required this.price, this.comparePrice,
    this.stock = 0, this.images = const [], this.variantSchema = const [],
    this.badge, this.isActive = true, this.isFeatured = false,
    this.soldCount = 0, this.views = 0, this.variants = const [],
  });

  factory Product.fromMap(Map<String, dynamic> m, {List<ProductVariant>? variants}) {
    return Product(
      id: m['id'] as String,
      storeId: m['store_id'] as String,
      categoryId: m['category_id'] as String?,
      title: m['title'] as String,
      description: m['description'] as String?,
      price: (m['price'] as num?) ?? 0,
      comparePrice: m['compare_price'] as num?,
      stock: (m['stock'] as int?) ?? 0,
      images: (m['images'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      variantSchema: (m['variant_schema'] as List?)
              ?.map((e) => VariantSchemaItem.fromMap((e as Map).cast<String, dynamic>()))
              .toList() ??
          const [],
      badge: m['badge'] as String?,
      isActive: (m['is_active'] as bool?) ?? true,
      isFeatured: (m['is_featured'] as bool?) ?? false,
      soldCount: (m['sold_count'] as int?) ?? 0,
      views: (m['views'] as int?) ?? 0,
      variants: variants ?? const [],
    );
  }

  String? get mainImage => images.isNotEmpty ? images.first : null;
  bool get hasDiscount => comparePrice != null && comparePrice! > price;
  int get discountPct => hasDiscount
      ? (((comparePrice! - price) / comparePrice!) * 100).round()
      : 0;
  bool get inStock => stock > 0;
  bool get hasVariants => variantSchema.isNotEmpty;

  Product copyWith({int? stock, bool? isActive, bool? isFeatured}) => Product(
        id: id, storeId: storeId, categoryId: categoryId, title: title,
        description: description, price: price, comparePrice: comparePrice,
        stock: stock ?? this.stock, images: images,
        variantSchema: variantSchema, badge: badge,
        isActive: isActive ?? this.isActive,
        isFeatured: isFeatured ?? this.isFeatured,
        soldCount: soldCount, views: views, variants: variants,
      );
}

@immutable
class OrderItem {
  final String? id;
  final String? productId;
  final String? variantId;
  final String title;
  final String? imageUrl;
  final int quantity;
  final num unitPrice;
  final String? variantInfo;

  const OrderItem({
    this.id, this.productId, this.variantId, required this.title,
    this.imageUrl, this.quantity = 1, required this.unitPrice, this.variantInfo,
  });

  factory OrderItem.fromMap(Map<String, dynamic> m) => OrderItem(
        id: m['id'] as String?,
        productId: m['product_id'] as String?,
        variantId: m['variant_id'] as String?,
        title: m['title'] as String? ?? '',
        imageUrl: m['image_url'] as String?,
        quantity: (m['quantity'] as int?) ?? 1,
        unitPrice: (m['unit_price'] as num?) ?? 0,
        variantInfo: m['variant_info'] as String?,
      );

  num get lineTotal => unitPrice * quantity;
}

@immutable
class Order {
  final String id;
  final int orderNumber;
  final String storeId;
  final String? customerId;
  final String customerName;
  final String phone;
  final String? phoneAlt;
  final String wilayaCode;
  final String wilayaName;
  final String communeName;
  final String? address;
  final DeliveryMode deliveryMode;
  final String? notes;
  final num subtotal;
  final num deliveryPrice;
  final num discount;
  final num totalPrice;
  final OrderStatus status;
  final String? courier;
  final String? trackingNumber;
  final DateTime createdAt;
  final List<OrderItem> items;

  const Order({
    required this.id, required this.orderNumber, required this.storeId,
    this.customerId, required this.customerName, required this.phone,
    this.phoneAlt, required this.wilayaCode, required this.wilayaName,
    required this.communeName, this.address,
    this.deliveryMode = DeliveryMode.home, this.notes,
    this.subtotal = 0, this.deliveryPrice = 0, this.discount = 0,
    this.totalPrice = 0, this.status = OrderStatus.newOrder,
    this.courier, this.trackingNumber, required this.createdAt,
    this.items = const [],
  });

  factory Order.fromMap(Map<String, dynamic> m, {List<OrderItem>? items}) => Order(
        id: m['id'] as String,
        orderNumber: (m['order_number'] as num?)?.toInt() ?? 0,
        storeId: m['store_id'] as String,
        customerId: m['customer_id'] as String?,
        customerName: m['customer_name'] as String? ?? '',
        phone: m['phone'] as String? ?? '',
        phoneAlt: m['phone_alt'] as String?,
        wilayaCode: m['wilaya_code'] as String? ?? '',
        wilayaName: m['wilaya_name'] as String? ?? '',
        communeName: m['commune_name'] as String? ?? '',
        address: m['address'] as String?,
        deliveryMode: DeliveryModeX.fromDb(m['delivery_mode'] as String?),
        notes: m['notes'] as String?,
        subtotal: (m['subtotal'] as num?) ?? 0,
        deliveryPrice: (m['delivery_price'] as num?) ?? 0,
        discount: (m['discount'] as num?) ?? 0,
        totalPrice: (m['total_price'] as num?) ?? 0,
        status: OrderStatusX.fromDb(m['status'] as String?),
        courier: m['courier'] as String?,
        trackingNumber: m['tracking_number'] as String?,
        createdAt: DateTime.tryParse(m['created_at']?.toString() ?? '')?.toLocal() ?? DateTime.now(),
        items: items ?? const [],
      );

  String get shortId => '#$orderNumber';
  bool get isOpen => status == OrderStatus.newOrder ||
      status == OrderStatus.confirmed ||
      status == OrderStatus.inDelivery ||
      status == OrderStatus.postponed;
}

@immutable
class AbandonedLead {
  final String id;
  final String storeId;
  final String? customerName;
  final String phone;
  final String? wilayaName;
  final String? communeName;
  final num cartTotal;
  final bool recovered;
  final DateTime createdAt;

  const AbandonedLead({
    required this.id, required this.storeId, this.customerName,
    required this.phone, this.wilayaName, this.communeName,
    this.cartTotal = 0, this.recovered = false, required this.createdAt,
  });

  factory AbandonedLead.fromMap(Map<String, dynamic> m) => AbandonedLead(
        id: m['id'] as String,
        storeId: m['store_id'] as String,
        customerName: m['customer_name'] as String?,
        phone: m['phone'] as String? ?? '',
        wilayaName: m['wilaya_name'] as String?,
        communeName: m['commune_name'] as String?,
        cartTotal: (m['cart_total'] as num?) ?? 0,
        recovered: (m['recovered'] as bool?) ?? false,
        createdAt: DateTime.tryParse(m['created_at']?.toString() ?? '')?.toLocal() ?? DateTime.now(),
      );
}

// ============================================================
// سلة الزبون (محلية)
// ============================================================
@immutable
class CartLine {
  final Product product;
  final ProductVariant? variant;
  final int qty;

  const CartLine({required this.product, this.variant, this.qty = 1});

  num get unitPrice => variant?.price ?? product.price;
  num get total => unitPrice * qty;
  String get key => '${product.id}:${variant?.id ?? ''}';

  CartLine copyWith({int? qty}) =>
      CartLine(product: product, variant: variant, qty: qty ?? this.qty);
}

@immutable
class Cart {
  final List<CartLine> lines;
  final String? storeId;

  const Cart({this.lines = const [], this.storeId});

  bool get isEmpty => lines.isEmpty;
  int get count => lines.fold(0, (a, l) => a + l.qty);
  num get subtotal => lines.fold<num>(0, (a, l) => a + l.total);

  Cart copyWith({List<CartLine>? lines, String? storeId}) =>
      Cart(lines: lines ?? this.lines, storeId: storeId ?? this.storeId);
}

// ============================================================
// الولاية / البلدية
// ============================================================
@immutable
class Commune {
  final String code;
  final String ar;
  final String fr;
  const Commune({required this.code, required this.ar, required this.fr});

  factory Commune.fromMap(Map<String, dynamic> m) => Commune(
        code: m['c'] as String,
        ar: m['ar'] as String,
        fr: m['fr'] as String,
      );
}

@immutable
class Wilaya {
  final String code;
  final String ar;
  final String fr;
  final List<Commune> communes;

  const Wilaya({
    required this.code, required this.ar, required this.fr,
    this.communes = const [],
  });

  factory Wilaya.fromMap(Map<String, dynamic> m) => Wilaya(
        code: m['code'] as String,
        ar: m['ar'] as String,
        fr: m['fr'] as String,
        communes: (m['communes'] as List?)
                ?.map((e) => Commune.fromMap((e as Map).cast<String, dynamic>()))
                .toList() ??
            const [],
      );

  String get display => '$code — $ar';
}
