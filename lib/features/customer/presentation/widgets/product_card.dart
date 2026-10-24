import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/models/models.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/ui_kit.dart';

/// ============================================================
/// كارت المنتج — يستعمل في الشبكة والصفوف الأفقية
/// ============================================================
class ProductCard extends ConsumerWidget {
  final Product product;
  final bool compact;

  const ProductCard({super.key, required this.product, this.compact = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: () => context.go('/shop/product/${product.id}'),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.line),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // صورة
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ProductImage(url: product.mainImage, radius: 0),
                    if (!product.inStock)
                      Container(
                        color: Colors.black.withValues(alpha: 0.45),
                        alignment: Alignment.center,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                          ),
                          child: Text('نفد المخزون',
                              style: AppText.caption.copyWith(
                                  color: AppColors.danger, fontWeight: FontWeight.w800)),
                        ),
                      ),
                    if (product.hasDiscount)
                      Positioned(
                        top: 8, right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.danger,
                            borderRadius: BorderRadius.circular(AppRadius.xs),
                          ),
                          child: Text('-${product.discountPct}%',
                              style: AppText.caption.copyWith(
                                  color: Colors.white, fontWeight: FontWeight.w900)),
                        ),
                      ),
                    if (product.badge != null && product.badge!.isNotEmpty)
                      Positioned(
                        top: 8, left: 8,
                        child: AppBadge(text: product.badge!, color: AppColors.gold600, small: true),
                      ),
                  ],
                ),
              ),
              // معلومات
              Padding(
                padding: const EdgeInsets.all(AppSpace.x3),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(product.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.bodySm.copyWith(
                            fontWeight: FontWeight.w700, color: AppColors.ink, height: 1.35)),
                    const SizedBox(height: 6),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(child: PriceText(product.price, size: 16)),
                        if (product.hasDiscount)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 1),
                            child: PriceText(product.comparePrice!,
                                size: 11.5, color: AppColors.ink30, strike: true),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// ---------- صف منتج (للسلة والصفحات) ----------
class ProductRow extends StatelessWidget {
  final Product product;
  final Widget? trailing;
  final String? subtitle;

  const ProductRow({super.key, required this.product, this.trailing, this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ProductImage(url: product.mainImage, width: 64, height: 64, radius: AppRadius.sm),
        const SizedBox(width: AppSpace.x3),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(product.title,
                  maxLines: 2, overflow: TextOverflow.ellipsis,
                  style: AppText.bodySm.copyWith(
                      fontWeight: FontWeight.w700, color: AppColors.ink)),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(subtitle!, style: AppText.caption),
              ],
              const SizedBox(height: 4),
              PriceText(product.price, size: 15),
            ],
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}
