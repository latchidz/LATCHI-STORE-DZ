import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/models/models.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/ui_kit.dart';
import '../../../../shared/providers/app_providers.dart';

/// ============================================================
/// صفحة المنتج — كاروس صور + اختيار المتغيّر + إضافة للسلة
/// ============================================================
class ProductScreen extends ConsumerStatefulWidget {
  final String id;
  const ProductScreen({super.key, required this.id});

  @override
  ConsumerState<ProductScreen> createState() => _ProductScreenState();
}

class _ProductScreenState extends ConsumerState<ProductScreen> {
  final PageController _pc = PageController();
  int _page = 0;
  int _qty = 1;
  ProductVariant? _variant;
  final Map<String, String> _selectedOptions = {};

  @override
  void dispose() {
    _pc.dispose();
    super.dispose();
  }

  /// يختار المتغيّر المطابق للخيارات المختارة
  void _resolveVariant(Product p) {
    if (!p.hasVariants || p.variants.isEmpty) return;
    if (_selectedOptions.length < p.variantSchema.length) return;
    try {
      final match = p.variants.firstWhere((v) {
        for (final e in _selectedOptions.entries) {
          if ((v.options[e.key]?.toString() ?? '') != e.value) return false;
        }
        return true;
      });
      setState(() => _variant = match);
    } catch (_) {
      setState(() => _variant = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(productProvider(widget.id));

    return Scaffold(
      backgroundColor: Colors.white,
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorView(error: e, onRetry: () => ref.invalidate(productProvider(widget.id))),
        data: (p) {
          if (p == null) {
            return const EmptyState(icon: Icons.search_off, title: 'المنتج ما لقيناهش');
          }
          final images = p.images.isEmpty ? [null] : p.images;
          final current = _variant?.price ?? p.price;

          return Stack(
            children: [
              CustomScrollView(
                slivers: [
                  // ---------- الكاروس ----------
                  SliverAppBar(
                    expandedHeight: MediaQuery.of(context).size.width,
                    pinned: true,
                    backgroundColor: Colors.white,
                    leading: _roundBtn(Icons.arrow_forward, () => context.go('/shop')),
                    actions: [
                      _roundBtn(Icons.share_outlined, () {}),
                      const SizedBox(width: 4),
                    ],
                    flexibleSpace: FlexibleSpaceBar(
                      background: Stack(
                        fit: StackFit.expand,
                        children: [
                          PageView.builder(
                            controller: _pc,
                            itemCount: images.length,
                            onPageChanged: (i) => setState(() => _page = i),
                            itemBuilder: (_, i) => ProductImage(url: images[i], radius: 0),
                          ),
                          if (images.length > 1)
                            Positioned(
                              bottom: 16, left: 0, right: 0,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(
                                  images.length,
                                  (i) => AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    margin: const EdgeInsets.symmetric(horizontal: 3),
                                    width: _page == i ? 22 : 7,
                                    height: 7,
                                    decoration: BoxDecoration(
                                      color: _page == i ? AppColors.green700 : Colors.white70,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

                  // ---------- التفاصيل ----------
                  SliverToBoxAdapter(
                    child: Container(
                      padding: const EdgeInsets.all(AppSpace.x4),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              if (p.badge != null)
                                Padding(
                                  padding: const EdgeInsets.only(left: 8),
                                  child: AppBadge(text: p.badge!, color: AppColors.gold600),
                                ),
                              if (p.soldCount > 0)
                                AppBadge(
                                  text: '${p.soldCount} مبيوع',
                                  color: AppColors.green700,
                                  icon: Icons.local_fire_department,
                                  small: true),
                            ],
                          ),
                          const SizedBox(height: AppSpace.x2),
                          Text(p.title, style: AppText.h2),
                          const SizedBox(height: AppSpace.x3),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              PriceText(current, size: 26),
                              if (p.hasDiscount) ...[
                                const SizedBox(width: 8),
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 3),
                                  child: PriceText(p.comparePrice!, size: 14,
                                      color: AppColors.ink30, strike: true),
                                ),
                                const SizedBox(width: 8),
                                AppBadge(text: '-${p.discountPct}%', color: AppColors.danger, small: true),
                              ],
                            ],
                          ),
                          const SizedBox(height: AppSpace.x2),
                          Row(
                            children: [
                              Icon(p.inStock ? Icons.check_circle : Icons.cancel,
                                  size: 15,
                                  color: p.inStock ? AppColors.success : AppColors.danger),
                              const SizedBox(width: 5),
                              Text(p.inStock ? 'متوفر${p.stock < 6 ? " · بقاو ${p.stock}" : ""}' : 'نفد المخزون',
                                  style: AppText.caption.copyWith(
                                    color: p.inStock ? AppColors.success : AppColors.danger,
                                    fontWeight: FontWeight.w700)),
                            ],
                          ),

                          // ---------- المتغيّرات ----------
                          if (p.hasVariants) ...[
                            const SizedBox(height: AppSpace.x5),
                            ...p.variantSchema.map((schema) {
                              final sel = _selectedOptions[schema.name];
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('${schema.name}: ${sel ?? "اختر"}',
                                      style: AppText.label),
                                  const SizedBox(height: AppSpace.x2),
                                  Wrap(
                                    spacing: 8, runSpacing: 8,
                                    children: schema.options.map((opt) {
                                      final active = sel == opt;
                                      return GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            _selectedOptions[schema.name] = opt;
                                            _variant = null;
                                          });
                                          _resolveVariant(p);
                                        },
                                        child: AnimatedContainer(
                                          duration: const Duration(milliseconds: 150),
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 16, vertical: 10),
                                          decoration: BoxDecoration(
                                            color: active ? AppColors.green700 : Colors.white,
                                            borderRadius: BorderRadius.circular(AppRadius.sm),
                                            border: Border.all(
                                              color: active ? AppColors.green700 : AppColors.line,
                                              width: 1.3),
                                          ),
                                          child: Text(opt,
                                              style: AppText.bodySm.copyWith(
                                                color: active ? Colors.white : AppColors.ink,
                                                fontWeight: FontWeight.w700,
                                              )),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                  const SizedBox(height: AppSpace.x4),
                                ],
                              );
                            }),
                          ],

                          const SizedBox(height: AppSpace.x3),
                          Row(
                            children: [
                              Text('الكمية', style: AppText.label),
                              const Spacer(),
                              QtyStepper(
                                value: _qty,
                                max: p.stock > 0 ? p.stock : 1,
                                onChanged: (v) => setState(() => _qty = v),
                              ),
                            ],
                          ),

                          if (p.description != null && p.description!.isNotEmpty) ...[
                            const SizedBox(height: AppSpace.x5),
                            const Divider(),
                            const SizedBox(height: AppSpace.x3),
                            Text('الوصف', style: AppText.h3),
                            const SizedBox(height: AppSpace.x2),
                            Text(p.description!, style: AppText.bodySm.copyWith(height: 1.75)),
                          ],

                          const SizedBox(height: AppSpace.x5),
                          const Divider(),
                          const SizedBox(height: AppSpace.x3),
                          _infoRow(Icons.local_shipping_outlined, 'توصيل لكل 69 ولاية',
                              'من 2 إلى 5 أيام حسب الولاية'),
                          _infoRow(Icons.payments_outlined, 'الدفع عند الاستلام',
                              'ما تخلصش حتى توصلك السلعة'),
                          _infoRow(Icons.assignment_return_outlined, 'تبديل خلال 48 ساعة',
                              'إذا كان المنتج فيه مشكل'),

                          const SizedBox(height: 110),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              // ---------- شريط سفلي ثابت ----------
              Positioned(
                bottom: 0, left: 0, right: 0,
                child: Container(
                  padding: EdgeInsets.fromLTRB(
                    AppSpace.x4, AppSpace.x3, AppSpace.x4,
                    MediaQuery.of(context).padding.bottom + AppSpace.x3),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: const Border(top: BorderSide(color: AppColors.line)),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 20, offset: const Offset(0, -4)),
                    ],
                  ),
                  child: Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('المجموع', style: AppText.caption),
                          PriceText(current * _qty, size: 19),
                        ],
                      ),
                      const SizedBox(width: AppSpace.x4),
                      Expanded(
                        child: AppButton(
                          label: p.hasVariants && _variant == null
                              ? 'اختر الخيارات'
                              : (p.inStock ? 'زيد للسلة' : 'نفد المخزون'),
                          icon: Icons.add_shopping_cart,
                          onPressed: (!p.inStock || (p.hasVariants && _variant == null))
                              ? null
                              : () {
                                  ref.read(cartProvider.notifier)
                                      .add(p, variant: _variant, qty: _qty);
                                  showSnack(context, 'تزاد للسلة ✓');
                                },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _roundBtn(IconData i, VoidCallback fn) => Padding(
        padding: const EdgeInsets.all(6),
        child: Material(
          color: Colors.white.withValues(alpha: 0.92),
          shape: const CircleBorder(),
          elevation: 2,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: fn,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Icon(i, size: 20, color: AppColors.ink),
            ),
          ),
        ),
      );

  Widget _infoRow(IconData i, String t, String s) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpace.x4),
        child: Row(
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                  color: AppColors.green50,
                  borderRadius: BorderRadius.circular(AppRadius.sm)),
              child: Icon(i, size: 19, color: AppColors.green700),
            ),
            const SizedBox(width: AppSpace.x3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t, style: AppText.bodySm.copyWith(fontWeight: FontWeight.w700)),
                  Text(s, style: AppText.caption),
                ],
              ),
            ),
          ],
        ),
      );
}
