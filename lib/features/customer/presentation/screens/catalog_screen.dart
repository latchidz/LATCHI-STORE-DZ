import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/ui_kit.dart';
import '../../../../shared/providers/app_providers.dart';
import '../widgets/product_card.dart';

/// كتالوج مستقل (بحث وفلترة كاملة)
class CatalogScreen extends ConsumerWidget {
  final bool standalone;
  const CatalogScreen({super.key, this.standalone = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final products = ref.watch(productsProvider);
    final filter = ref.watch(catalogFilterProvider);

    return Scaffold(
      appBar: standalone
          ? AppBar(
              title: const Text('كل المنتجات'),
              leading: IconButton(
                icon: const Icon(Icons.arrow_forward),
                onPressed: () => context.go('/shop'),
              ),
            )
          : null,
      body: Column(
        children: [
          // ---------- الترتيب ----------
          SizedBox(
            height: 52,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpace.x4, vertical: 6),
              children: [
                _sortChip(ref, filter, 'newest', 'الأحدث'),
                _sortChip(ref, filter, 'price_asc', 'الأرخص'),
                _sortChip(ref, filter, 'price_desc', 'الأغلى'),
                _sortChip(ref, filter, 'popular', 'الأكثر مبيعاً'),
              ],
            ),
          ),
          Expanded(
            child: products.when(
              loading: () => const ListSkeleton(count: 4, height: 180),
              error: (e, _) => ErrorView(
                  error: e, onRetry: () => ref.invalidate(productsProvider)),
              data: (list) => list.isEmpty
                  ? const EmptyState(
                      icon: Icons.inventory_2_outlined,
                      title: 'ما كاينش منتجات',
                      subtitle: 'جرّب تبدّل البحث ولا الصنف',
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.all(AppSpace.x4),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: AppSpace.x3,
                        crossAxisSpacing: AppSpace.x3,
                        childAspectRatio: 0.66,
                      ),
                      itemCount: list.length,
                      itemBuilder: (_, i) => ProductCard(product: list[i]),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sortChip(WidgetRef ref, CatalogFilter f, String value, String label) {
    final active = f.sort == value;
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: active,
        onSelected: (_) =>
            ref.read(catalogFilterProvider.notifier).state = f.copyWith(sort: value),
        labelStyle: AppText.caption.copyWith(
          color: active ? Colors.white : AppColors.ink70,
          fontWeight: active ? FontWeight.w800 : FontWeight.w500,
        ),
        selectedColor: AppColors.green700,
        backgroundColor: Colors.white,
        showCheckmark: false,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          side: BorderSide(color: active ? AppColors.green700 : AppColors.line),
        ),
      ),
    );
  }
}
