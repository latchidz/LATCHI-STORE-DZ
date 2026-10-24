import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/ui_kit.dart';
import '../../../../shared/providers/app_providers.dart';
import '../widgets/product_card.dart';

/// ============================================================
/// السلة
/// ============================================================
class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('السلة${cart.isEmpty ? "" : " (${cart.count})"}'),
        actions: [
          if (!cart.isEmpty)
            TextButton(
              onPressed: () => _confirmClear(context, ref),
              child: Text('فرّغ', style: AppText.label.copyWith(color: AppColors.danger)),
            ),
        ],
      ),
      body: cart.isEmpty
          ? EmptyState(
              icon: Icons.shopping_cart_outlined,
              title: 'السلة فارغة',
              subtitle: 'قلّب على المنتجات وزيدها هنا',
              action: SizedBox(
                width: 220, height: 52,
                child: FilledButton(
                  onPressed: () => context.go('/shop'),
                  child: const Text('تسوّق دوكا'),
                ),
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(AppSpace.x4),
                    itemCount: cart.lines.length,
                    separatorBuilder: (_, __) => const SizedBox(height: AppSpace.x3),
                    itemBuilder: (_, i) {
                      final line = cart.lines[i];
                      return Container(
                        padding: const EdgeInsets.all(AppSpace.x3),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          border: Border.all(color: AppColors.line),
                        ),
                        child: Column(
                          children: [
                            ProductRow(
                              product: line.product,
                              subtitle: line.variant?.label,
                              trailing: IconButton(
                                icon: const Icon(Icons.close, size: 18),
                                color: AppColors.ink50,
                                onPressed: () =>
                                    ref.read(cartProvider.notifier).remove(line.key),
                              ),
                            ),
                            const SizedBox(height: AppSpace.x2),
                            Row(
                              children: [
                                QtyStepper(
                                  value: line.qty,
                                  max: line.product.stock > 0 ? line.product.stock : 99,
                                  onChanged: (v) =>
                                      ref.read(cartProvider.notifier).setQty(line.key, v),
                                ),
                                const Spacer(),
                                PriceText(line.total, size: 16),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                _summary(context, ref, cart),
              ],
            ),
    );
  }

  Widget _summary(BuildContext context, WidgetRef ref, cart) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSpace.x4, AppSpace.x4, AppSpace.x4,
        MediaQuery.of(context).padding.bottom + AppSpace.x4),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(top: BorderSide(color: AppColors.line)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 16, offset: const Offset(0, -4)),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text('المجموع الفرعي', style: AppText.bodySm),
              const Spacer(),
              PriceText(cart.subtotal, size: 16, color: AppColors.ink),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Text('التوصيل', style: AppText.bodySm),
              const Spacer(),
              Text('يتحدّد حسب الولاية',
                  style: AppText.caption.copyWith(color: AppColors.ink50)),
            ],
          ),
          const SizedBox(height: AppSpace.x4),
          AppButton(
            label: 'كمّل الطلب',
            icon: Icons.arrow_back_rounded,
            onPressed: () => context.go('/shop/checkout'),
          ),
        ],
      ),
    );
  }

  void _confirmClear(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('تفرّغ السلة؟'),
        content: const Text('راح يتحيّد كلشي من السلة.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: const Text('لا')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () {
              ref.read(cartProvider.notifier).clear();
              Navigator.pop(c);
            },
            child: const Text('نعم'),
          ),
        ],
      ),
    );
  }
}
