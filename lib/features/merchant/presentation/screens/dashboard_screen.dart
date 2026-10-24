import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/models/models.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/ui_kit.dart';
import '../../../../shared/providers/app_providers.dart';

/// ============================================================
/// لوحة التحكم — نظرة سريعة على المتجر
/// ============================================================
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(storeStatsProvider);
    final orders = ref.watch(merchantOrdersProvider);
    final store = ref.watch(myStoreProvider);

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: RefreshIndicator(
        color: AppColors.green700,
        onRefresh: () async {
          ref.invalidate(storeStatsProvider);
          ref.invalidate(merchantOrdersProvider);
          ref.invalidate(myStoreProvider);
        },
        child: CustomScrollView(
          slivers: [
            // ---------- الهيدر ----------
            SliverToBoxAdapter(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.green800, AppColors.green700],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.vertical(
                      bottom: Radius.circular(AppRadius.xl)),
                ),
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 14,
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
                              Text('لوحة التحكم',
                                  style: AppText.h1.copyWith(color: Colors.white)),
                              const SizedBox(height: 2),
                              Text(store.valueOrNull?.name ?? 'متجري',
                                  style: AppText.caption.copyWith(color: Colors.white70)),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.settings_outlined, color: Colors.white),
                          onPressed: () => context.go('/merchant/settings'),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpace.x4),
                    stats.when(
                      loading: () => const SizedBox(height: 86),
                      error: (_, __) => const SizedBox(height: 86),
                      data: (s) => Row(
                        children: [
                          Expanded(
                            child: _kpi(
                              'مبيوع (30 يوم)',
                              Money.dz((s['revenue_delivered'] as num?) ?? 0),
                              Icons.trending_up,
                            ),
                          ),
                          const SizedBox(width: AppSpace.x3),
                          Expanded(
                            child: _kpi(
                              'طلبات جديدة',
                              '${s['orders_new'] ?? 0}',
                              Icons.fiber_new,
                              accent: AppColors.gold500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ---------- الأرقام ----------
            SliverToBoxAdapter(
              child: stats.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(AppSpace.x4),
                  child: ListSkeleton(count: 1, height: 120),
                ),
                error: (e, _) => Padding(
                  padding: const EdgeInsets.all(AppSpace.x4),
                  child: ErrorView(error: e, onRetry: () => ref.invalidate(storeStatsProvider)),
                ),
                data: (s) => Padding(
                  padding: const EdgeInsets.all(AppSpace.x4),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          _statCard('كل الطلبات', '${s['orders_total'] ?? 0}', AppColors.info),
                          const SizedBox(width: AppSpace.x3),
                          _statCard('مؤكدة', '${s['orders_confirmed'] ?? 0}', AppColors.success),
                        ],
                      ),
                      const SizedBox(height: AppSpace.x3),
                      Row(
                        children: [
                          _statCard('موصّلة', '${s['orders_delivered'] ?? 0}', AppColors.green700),
                          const SizedBox(width: AppSpace.x3),
                          _statCard('ملغاة', '${s['orders_canceled'] ?? 0}', AppColors.danger),
                        ],
                      ),
                      const SizedBox(height: AppSpace.x3),
                      _basketCard((s['avg_basket'] as num?) ?? 0,
                          (s['revenue_pending'] as num?) ?? 0),
                    ],
                  ),
                ),
              ),
            ),

            // ---------- آخر الطلبات ----------
            const SliverToBoxAdapter(child: SectionHeader(title: 'آخر الطلبات')),
            orders.when(
              loading: () => const SliverToBoxAdapter(
                  child: ListSkeleton(count: 3, height: 92)),
              error: (e, _) => SliverToBoxAdapter(
                  child: ErrorView(error: e, onRetry: () => ref.invalidate(merchantOrdersProvider))),
              data: (list) {
                if (list.isEmpty) {
                  return const SliverToBoxAdapter(
                    child: EmptyState(
                      icon: Icons.receipt_long_outlined,
                      title: 'ما كاينش طلبات بعد',
                      subtitle: 'زيد منتجات وشارك المتجر تاعك',
                    ),
                  );
                }
                final recent = list.take(5).toList();
                return SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpace.x4),
                  sliver: SliverList.separated(
                    itemCount: recent.length,
                    separatorBuilder: (_, __) => const SizedBox(height: AppSpace.x3),
                    itemBuilder: (_, i) => _orderTile(context, recent[i]),
                  ),
                );
              },
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 40)),
          ],
        ),
      ),
    );
  }

  Widget _kpi(String label, String value, IconData icon, {Color? accent}) {
    return Container(
      padding: const EdgeInsets.all(AppSpace.x3),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 15, color: accent ?? Colors.white70),
              const SizedBox(width: 5),
              Expanded(
                child: Text(label,
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: AppText.caption.copyWith(color: Colors.white70)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(value,
              maxLines: 1, overflow: TextOverflow.ellipsis,
              style: AppText.h2.copyWith(color: Colors.white, fontSize: 19)),
        ],
      ),
    );
  }

  Widget _statCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(AppSpace.x4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(width: 34, height: 4,
                decoration: BoxDecoration(
                    color: color, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: AppSpace.x2),
            Text(value, style: AppText.h1.copyWith(fontSize: 26)),
            Text(label, style: AppText.caption),
          ],
        ),
      ),
    );
  }

  Widget _basketCard(num avgBasket, num pending) {
    return Container(
      padding: const EdgeInsets.all(AppSpace.x4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('متوسط السلة', style: AppText.caption),
                const SizedBox(height: 2),
                PriceText(avgBasket, size: 18),
              ],
            ),
          ),
          Container(width: 1, height: 40, color: AppColors.line),
          const SizedBox(width: AppSpace.x4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('مبالغ معلّقة', style: AppText.caption),
                const SizedBox(height: 2),
                PriceText(pending, size: 18, color: AppColors.warning),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _orderTile(BuildContext context, Order o) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: () => context.go('/merchant/orders/${o.id}'),
        child: Container(
          padding: const EdgeInsets.all(AppSpace.x3),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.line),
          ),
          child: Row(
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: StatusChip.colorOf(o.status).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                alignment: Alignment.center,
                child: Text(o.status.icon, style: const TextStyle(fontSize: 18)),
              ),
              const SizedBox(width: AppSpace.x3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(o.shortId,
                            style: AppText.bodySm.copyWith(fontWeight: FontWeight.w900)),
                        const SizedBox(width: 6),
                        StatusChip(status: o.status, small: true),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text('${o.customerName} · ${o.wilayaName}',
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: AppText.caption),
                  ],
                ),
              ),
              PriceText(o.totalPrice, size: 15),
            ],
          ),
        ),
      ),
    );
  }
}
