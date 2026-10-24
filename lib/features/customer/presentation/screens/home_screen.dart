import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/env.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/ui_kit.dart';
import '../../../../shared/providers/app_providers.dart';
import '../widgets/product_card.dart';

/// ============================================================
/// الصفحة الرئيسية للمتجر
/// ============================================================
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _searchCtrl = TextEditingController();
  bool _searching = false;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final storeAsync = ref.watch(publicStoreProvider);
    final featured = ref.watch(featuredProductsProvider);
    final cats = ref.watch(categoriesProvider);
    final products = ref.watch(productsProvider);
    final filter = ref.watch(catalogFilterProvider);

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: RefreshIndicator(
        color: AppColors.green700,
        onRefresh: () async {
          ref.invalidate(productsProvider);
          ref.invalidate(featuredProductsProvider);
          ref.invalidate(categoriesProvider);
          await ref.read(productsProvider.future);
        },
        child: CustomScrollView(
          slivers: [
            // ---------- الهيدر ----------
            SliverToBoxAdapter(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [AppColors.green700, AppColors.green600],
                  ),
                  borderRadius: BorderRadius.vertical(
                      bottom: Radius.circular(AppRadius.xl)),
                ),
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 12,
                  left: AppSpace.x4, right: AppSpace.x4, bottom: AppSpace.x5,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                storeAsync.valueOrNull?.name ?? 'LATCHI STORE',
                                style: AppText.h1.copyWith(color: Colors.white),
                                maxLines: 1, overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  const Icon(Icons.verified_rounded,
                                      size: 14, color: AppColors.gold500),
                                  const SizedBox(width: 4),
                                  Text(
                                    storeAsync.valueOrNull?.wilayaCode != null
                                        ? 'متجر موثّق · توصيل لكل الولايات'
                                        : 'توصيل لكل الولايات · الدفع عند الاستلام',
                                    style: AppText.caption.copyWith(color: Colors.white70),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        _circleBtn(Icons.notifications_none_rounded, () {}),
                      ],
                    ),
                    const SizedBox(height: AppSpace.x4),

                    // ---------- البحث ----------
                    GestureDetector(
                      onTap: () => setState(() => _searching = !_searching),
                      child: Container(
                        height: 50,
                        padding: const EdgeInsets.symmetric(horizontal: AppSpace.x4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                        child: _searching
                            ? Row(
                                children: [
                                  const Icon(Icons.search, size: 20, color: AppColors.ink50),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: TextField(
                                      controller: _searchCtrl,
                                      autofocus: true,
                                      style: AppText.body,
                                      decoration: const InputDecoration(
                                        hintText: 'قلّب على منتج…',
                                        border: InputBorder.none,
                                        enabledBorder: InputBorder.none,
                                        focusedBorder: InputBorder.none,
                                        filled: false,
                                        contentPadding: EdgeInsets.zero,
                                      ),
                                      onChanged: (v) => ref
                                          .read(catalogFilterProvider.notifier)
                                          .state = filter.copyWith(query: v),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.close, size: 18),
                                    onPressed: () {
                                      _searchCtrl.clear();
                                      setState(() => _searching = false);
                                      ref.read(catalogFilterProvider.notifier).state =
                                          filter.copyWith(query: '');
                                    },
                                  ),
                                ],
                              )
                            : Row(
                                children: [
                                  const Icon(Icons.search, size: 20, color: AppColors.ink50),
                                  const SizedBox(width: 10),
                                  Text('قلّب على منتج…',
                                      style: AppText.bodySm.copyWith(color: AppColors.ink30)),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ---------- الأصناف ----------
            SliverToBoxAdapter(
              child: cats.when(
                loading: () => const SizedBox(height: 100),
                error: (_, __) => const SizedBox.shrink(),
                data: (list) {
                  if (list.isEmpty) return const SizedBox.shrink();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SectionHeader(title: 'الأصناف'),
                      SizedBox(
                        height: 96,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: AppSpace.x4),
                          itemCount: list.length + 1,
                          separatorBuilder: (_, __) => const SizedBox(width: AppSpace.x3),
                          itemBuilder: (_, i) {
                            if (i == 0) {
                              return _CatTile(
                                label: 'الكل',
                                icon: Icons.apps_rounded,
                                selected: filter.categoryId == null,
                                onTap: () => ref
                                    .read(catalogFilterProvider.notifier)
                                    .state = filter.copyWith(clearCat: true),
                              );
                            }
                            final c = list[i - 1];
                            return _CatTile(
                              label: c.name,
                              image: c.imageUrl,
                              selected: filter.categoryId == c.id,
                              onTap: () => ref
                                  .read(catalogFilterProvider.notifier)
                                  .state = filter.copyWith(categoryId: c.id),
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),

            // ---------- مميز ----------
            SliverToBoxAdapter(
              child: featured.when(
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
                data: (list) => list.isEmpty
                    ? const SizedBox.shrink()
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SectionHeader(title: '⭐ مختار ليك'),
                          SizedBox(
                            height: 268,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.symmetric(horizontal: AppSpace.x4),
                              itemCount: list.length,
                              separatorBuilder: (_, __) => const SizedBox(width: AppSpace.x3),
                              itemBuilder: (_, i) =>
                                  SizedBox(width: 168, child: ProductCard(product: list[i])),
                            ),
                          ),
                        ],
                      ),
              ),
            ),

            // ---------- كل المنتجات ----------
            SliverToBoxAdapter(
              child: SectionHeader(
                title: filter.query.isNotEmpty
                    ? 'نتائج: ${filter.query}'
                    : (filter.categoryId != null ? 'منتجات الصنف' : 'كل المنتجات'),
              ),
            ),

            products.when(
              loading: () => const SliverToBoxAdapter(child: ListSkeleton(count: 3, height: 200)),
              error: (e, _) => SliverToBoxAdapter(
                  child: ErrorView(error: e, onRetry: () => ref.invalidate(productsProvider))),
              data: (list) {
                if (list.isEmpty) {
                  return const SliverToBoxAdapter(
                    child: EmptyState(
                      icon: Icons.inventory_2_outlined,
                      title: 'ما كاينش منتجات',
                      subtitle: 'جرّب تبدّل الصنف ولا كلمة البحث',
                    ),
                  );
                }
                return SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpace.x4),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: AppSpace.x3,
                      crossAxisSpacing: AppSpace.x3,
                      childAspectRatio: 0.66,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (_, i) => ProductCard(product: list[i]),
                      childCount: list.length,
                    ),
                  ),
                );
              },
            ),

            // ---------- الفوتر ----------
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(AppSpace.x6),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _trustChip(Icons.local_shipping_outlined, 'توصيل 69 ولاية'),
                        const SizedBox(width: AppSpace.x2),
                        _trustChip(Icons.payments_outlined, 'الدفع عند الاستلام'),
                      ],
                    ),
                    const SizedBox(height: AppSpace.x3),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _trustChip(Icons.support_agent, 'دعم مباشر'),
                        const SizedBox(width: AppSpace.x2),
                        _trustChip(Icons.assignment_return_outlined, 'تبديل سهل'),
                      ],
                    ),
                    const SizedBox(height: AppSpace.x5),
                    Text('${Env.appName} · v${Env.appVersion}',
                        style: AppText.caption.copyWith(color: AppColors.ink30)),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 40)),
          ],
        ),
      ),
    );
  }

  Widget _circleBtn(IconData i, VoidCallback onTap) => Material(
        color: Colors.white.withValues(alpha: 0.15),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Icon(i, color: Colors.white, size: 22),
          ),
        ),
      );

  Widget _trustChip(IconData i, String t) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.green50,
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(i, size: 15, color: AppColors.green700),
            const SizedBox(width: 5),
            Text(t, style: AppText.caption.copyWith(color: AppColors.green800)),
          ],
        ),
      );
}

class _CatTile extends StatelessWidget {
  final String label;
  final IconData? icon;
  final String? image;
  final bool selected;
  final VoidCallback onTap;

  const _CatTile({
    required this.label, this.icon, this.image,
    this.selected = false, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: SizedBox(
        width: 76,
        child: Column(
          children: [
            Container(
              width: 62, height: 62,
              decoration: BoxDecoration(
                color: selected ? AppColors.green700 : Colors.white,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(
                  color: selected ? AppColors.green700 : AppColors.line, width: 1.2),
              ),
              clipBehavior: Clip.antiAlias,
              child: image != null && image!.isNotEmpty
                  ? ProductImage(url: image, radius: 0)
                  : Icon(icon ?? Icons.category_outlined,
                      color: selected ? Colors.white : AppColors.green600, size: 26),
            ),
            const SizedBox(height: 6),
            Text(label,
                maxLines: 1, overflow: TextOverflow.ellipsis,
                style: AppText.caption.copyWith(
                  color: selected ? AppColors.green700 : AppColors.ink70,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
                )),
          ],
        ),
      ),
    );
  }
}
