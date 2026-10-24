import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/models/models.dart';
import '../../../../core/network/supabase_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/ui_kit.dart';
import '../../../../shared/providers/app_providers.dart';

/// ============================================================
/// منتجات التاجر — قائمة + تعديل + حذف + تفعيل/تعطيل
/// ============================================================
final merchantProductsProvider = FutureProvider<List<Product>>((ref) async {
  final svc = SupabaseService.instance;
  if (!svc.isReady) return const [];
  final store = await ref.watch(myStoreProvider.future);
  if (store == null) return const [];
  final rows = await svc.client
      .from('products')
      .select()
      .eq('store_id', store.id)
      .order('created_at', ascending: false);
  return (rows as List)
      .map((e) => Product.fromMap((e as Map).cast<String, dynamic>()))
      .toList();
});

class ProductsScreen extends ConsumerWidget {
  const ProductsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(merchantProductsProvider);

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: const Text('المنتجات'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(merchantProductsProvider),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/merchant/products/new'),
        backgroundColor: AppColors.green700,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('منتج جديد'),
      ),
      body: async.when(
        loading: () => const ListSkeleton(count: 6, height: 88),
        error: (e, _) => ErrorView(
            error: e, onRetry: () => ref.invalidate(merchantProductsProvider)),
        data: (list) {
          if (list.isEmpty) {
            return EmptyState(
              icon: Icons.inventory_2_outlined,
              title: 'ما كاينش منتجات',
              subtitle: 'زيد أول منتج باش يبان فالواجهة',
              action: SizedBox(
                width: 220, height: 52,
                child: FilledButton.icon(
                  onPressed: () => context.go('/merchant/products/new'),
                  icon: const Icon(Icons.add),
                  label: const Text('زيد منتج'),
                ),
              ),
            );
          }
          return RefreshIndicator(
            color: AppColors.green700,
            onRefresh: () async {
              ref.invalidate(merchantProductsProvider);
              await ref.read(merchantProductsProvider.future);
            },
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(AppSpace.x4, AppSpace.x4,
                  AppSpace.x4, 90),
              itemCount: list.length,
              separatorBuilder: (_, __) => const SizedBox(height: AppSpace.x3),
              itemBuilder: (_, i) => _ProductTile(p: list[i]),
            ),
          );
        },
      ),
    );
  }
}

class _ProductTile extends ConsumerWidget {
  final Product p;
  const _ProductTile({required this.p});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(AppSpace.x3),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => context.go('/merchant/products/${p.id}/edit'),
            child: Row(
              children: [
                ProductImage(url: p.mainImage, width: 68, height: 68,
                    radius: AppRadius.sm),
                const SizedBox(width: AppSpace.x3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p.title,
                          maxLines: 2, overflow: TextOverflow.ellipsis,
                          style: AppText.bodySm.copyWith(
                              fontWeight: FontWeight.w800, color: AppColors.ink)),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          PriceText(p.price, size: 15),
                          const SizedBox(width: AppSpace.x2),
                          AppBadge(
                            text: p.inStock ? 'المخزون: ${p.stock}' : 'نفد',
                            color: p.inStock
                                ? (p.stock < 5 ? AppColors.warning : AppColors.success)
                                : AppColors.danger,
                            small: true,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 20),
          Row(
            children: [
              _act(Icons.edit_outlined, 'تعديل', AppColors.info, () {
                context.go('/merchant/products/${p.id}/edit');
              }),
              Container(width: 1, height: 22, color: AppColors.line),
              _act(
                p.isActive ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                p.isActive ? 'خبّي' : 'بيّن',
                p.isActive ? AppColors.warning : AppColors.success,
                () => _toggleActive(context, ref),
              ),
              Container(width: 1, height: 22, color: AppColors.line),
              _act(Icons.delete_outline, 'حذف', AppColors.danger,
                  () => _confirmDelete(context, ref)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _act(IconData i, String t, Color c, VoidCallback onTap) => Expanded(
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(i, size: 15, color: c),
                const SizedBox(width: 5),
                Text(t, style: AppText.caption.copyWith(
                    color: c, fontWeight: FontWeight.w800)),
              ],
            ),
          ),
        ),
      );

  Future<void> _toggleActive(BuildContext context, WidgetRef ref) async {
    try {
      final svc = SupabaseService.instance;
      await svc.client.from('products').update({'is_active': !p.isActive}).eq('id', p.id);
      ref.invalidate(merchantProductsProvider);
      ref.invalidate(productsProvider);
      if (context.mounted) {
        showSnack(context, p.isActive ? 'تخبّى ✓' : 'بان ✓');
      }
    } catch (e) {
      if (context.mounted) showSnack(context, AppException.from(e).message, error: true);
    }
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('تحذف المنتج؟'),
        content: Text('«${p.title}» راح يتحيّد نهائياً.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('لا')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(c, true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      final svc = SupabaseService.instance;
      await svc.client.from('products').delete().eq('id', p.id);
      ref.invalidate(merchantProductsProvider);
      ref.invalidate(productsProvider);
      if (context.mounted) showSnack(context, 'تحذف ✓');
    } catch (e) {
      if (context.mounted) showSnack(context, AppException.from(e).message, error: true);
    }
  }
}
