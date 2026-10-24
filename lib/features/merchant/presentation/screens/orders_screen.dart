import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/models/models.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/ui_kit.dart';
import '../../../../shared/providers/app_providers.dart';

/// ============================================================
/// الطلبات — CRM بسيط: فلترة + تعيين سريع + اتصال
/// ============================================================
class OrdersScreen extends ConsumerWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(orderStatusFilterProvider);
    final orders = ref.watch(merchantOrdersProvider);

    // نستمعو للتغييرات اللحظية ونعيد التحميل
    ref.listen(ordersRealtimeProvider, (prev, next) {
      if (next.hasValue) ref.invalidate(merchantOrdersProvider);
    });

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: const Text('الطلبات'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(merchantOrdersProvider),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(52),
          child: SizedBox(
            height: 52,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpace.x4, vertical: 6),
              children: [
                _fchip(ref, null, 'الكل'),
                ...OrderStatus.values.map((s) => _fchip(ref, s, '${s.icon} ${s.ar}')),
              ],
            ),
          ),
        ),
      ),
      body: orders.when(
        loading: () => const ListSkeleton(count: 6),
        error: (e, _) => ErrorView(
            error: e, onRetry: () => ref.invalidate(merchantOrdersProvider)),
        data: (list) {
          if (list.isEmpty) {
            return EmptyState(
              icon: Icons.receipt_long_outlined,
              title: filter == null ? 'ما كاينش طلبات' : 'ما كاينش طلبات ${filter.ar}',
              subtitle: 'الطلبات الجديدة تبان هنا لحظياً',
            );
          }
          return RefreshIndicator(
            color: AppColors.green700,
            onRefresh: () async {
              ref.invalidate(merchantOrdersProvider);
              await ref.read(merchantOrdersProvider.future);
            },
            child: ListView.separated(
              padding: const EdgeInsets.all(AppSpace.x4),
              itemCount: list.length,
              separatorBuilder: (_, __) => const SizedBox(height: AppSpace.x3),
              itemBuilder: (_, i) => _OrderCard(order: list[i]),
            ),
          );
        },
      ),
    );
  }

  Widget _fchip(WidgetRef ref, OrderStatus? s, String label) {
    final active = ref.watch(orderStatusFilterProvider) == s;
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: active,
        onSelected: (_) => ref.read(orderStatusFilterProvider.notifier).state = s,
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

/// ---------- كارت طلب مع إجراءات سريعة ----------
class _OrderCard extends ConsumerWidget {
  final Order order;
  const _OrderCard({required this.order});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => context.go('/merchant/orders/${order.id}'),
            child: Padding(
              padding: const EdgeInsets.all(AppSpace.x3),
              child: Column(
                children: [
                  Row(
                    children: [
                      Text(order.shortId,
                          style: AppText.bodySm.copyWith(fontWeight: FontWeight.w900)),
                      const SizedBox(width: 6),
                      StatusChip(status: order.status, small: true),
                      const Spacer(),
                      PriceText(order.totalPrice, size: 16),
                    ],
                  ),
                  const SizedBox(height: AppSpace.x2),
                  Row(
                    children: [
                      const Icon(Icons.person_outline, size: 14, color: AppColors.ink50),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(order.customerName,
                            maxLines: 1, overflow: TextOverflow.ellipsis,
                            style: AppText.bodySm),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      const Icon(Icons.place_outlined, size: 14, color: AppColors.ink50),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text('${order.wilayaName} · ${order.communeName}',
                            maxLines: 1, overflow: TextOverflow.ellipsis,
                            style: AppText.caption),
                      ),
                      Text(_ago(order.createdAt),
                          style: AppText.caption.copyWith(fontSize: 11)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 1),
          // ---------- إجراءات سريعة ----------
          Row(
            children: [
              _action(Icons.call, 'عيّط', AppColors.info,
                  () => _call(order.phone)),
              _sep(),
              _action(Icons.chat, 'واتساب', AppColors.success,
                  () => _whatsapp(order.phone, order)),
              _sep(),
              if (order.status == OrderStatus.newOrder)
                _action(Icons.check_circle_outline, 'أكّد', AppColors.success,
                    () => _setStatus(context, ref, OrderStatus.confirmed))
              else if (order.status == OrderStatus.confirmed)
                _action(Icons.local_shipping_outlined, 'للتوصيل', AppColors.purple,
                    () => _setStatus(context, ref, OrderStatus.inDelivery))
              else if (order.status == OrderStatus.inDelivery)
                _action(Icons.inventory_2_outlined, 'توصّل', AppColors.green700,
                    () => _setStatus(context, ref, OrderStatus.delivered))
              else
                _action(Icons.visibility_outlined, 'شوف', AppColors.ink70,
                    () => context.go('/merchant/orders/${order.id}')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sep() => Container(width: 1, height: 24, color: AppColors.line);

  Widget _action(IconData i, String t, Color c, VoidCallback onTap) => Expanded(
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 11),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(i, size: 16, color: c),
                const SizedBox(width: 5),
                Text(t, style: AppText.caption.copyWith(
                    color: c, fontWeight: FontWeight.w800)),
              ],
            ),
          ),
        ),
      );

  String _ago(DateTime d) {
    final diff = DateTime.now().difference(d);
    if (diff.inMinutes < 1) return 'دوكا';
    if (diff.inMinutes < 60) return 'قبل ${diff.inMinutes} د';
    if (diff.inHours < 24) return 'قبل ${diff.inHours} سا';
    if (diff.inDays < 7) return 'قبل ${diff.inDays} يوم';
    return '${d.day}/${d.month}';
  }

  Future<void> _call(String phone) async {
    final uri = Uri.parse('tel:${phone.replaceAll(RegExp(r'\s'), '')}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _whatsapp(String phone, Order o) async {
    var p = phone.replaceAll(RegExp(r'\D'), '');
    if (p.startsWith('0')) p = '213${p.substring(1)}';
    if (!p.startsWith('213')) p = '213$p';
    final msg = Uri.encodeComponent(
        'السلام عليكم ${o.customerName} 👋\n'
        'هادا متجر LATCHI STORE بخصوص طلبك ${o.shortId}.\n'
        'نأكدولك الطلب؟');
    final uri = Uri.parse('https://wa.me/$p?text=$msg');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _setStatus(
      BuildContext context, WidgetRef ref, OrderStatus s) async {
    showSnack(context, 'جاري التحديث…');
    // TODO: الاستدعاء الحقيقي
  }
}
