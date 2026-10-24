import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/models/models.dart';
import '../../../../core/network/supabase_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/ui_kit.dart';
import '../../../../shared/providers/app_providers.dart';

/// ============================================================
/// تفاصيل الطلب — كل المعلومات + تغيير الحالة + بون التوصيل
/// ============================================================
class OrderDetailScreen extends ConsumerStatefulWidget {
  final String id;
  const OrderDetailScreen({super.key, required this.id});

  @override
  ConsumerState<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends ConsumerState<OrderDetailScreen> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(orderDetailProvider(widget.id));

    return Scaffold(
      appBar: AppBar(
        title: const Text('تفاصيل الطلب'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_forward),
          onPressed: () => context.go('/merchant'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.print_outlined),
            tooltip: 'بون التوصيل',
            onPressed: () => _showLabel(context),
          ),
        ],
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorView(
            error: e, onRetry: () => ref.invalidate(orderDetailProvider(widget.id))),
        data: (o) {
          if (o == null) {
            return const EmptyState(icon: Icons.search_off, title: 'الطلب ما لقيناهش');
          }
          return ListView(
            padding: const EdgeInsets.all(AppSpace.x4),
            children: [
              // ---------- الحالة ----------
              Container(
                padding: const EdgeInsets.all(AppSpace.x4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: AppColors.line),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Text(o.shortId,
                            style: AppText.display.copyWith(
                                fontSize: 26, color: AppColors.green700)),
                        const Spacer(),
                        StatusChip(status: o.status),
                      ],
                    ),
                    const SizedBox(height: AppSpace.x3),
                    // شريط الحالة
                    _statusBar(o.status),
                    if (o.status.next.isNotEmpty) ...[
                      const SizedBox(height: AppSpace.x4),
                      Wrap(
                        spacing: 8, runSpacing: 8,
                        children: o.status.next.map((s) {
                          final isDanger = s == OrderStatus.canceled;
                          return _busy
                              ? const SizedBox(
                                  width: 100, height: 40,
                                  child: Center(
                                      child: SizedBox(
                                          width: 18, height: 18,
                                          child: CircularProgressIndicator(strokeWidth: 2))))
                              : ActionChip(
                                  avatar: Text(s.icon, style: const TextStyle(fontSize: 13)),
                                  label: Text('تحويل لـ${s.ar}'),
                                  backgroundColor:
                                      isDanger ? AppColors.danger.withValues(alpha: 0.08) : Colors.white,
                                  side: BorderSide(
                                      color: isDanger
                                          ? AppColors.danger
                                          : StatusChip.colorOf(s)),
                                  labelStyle: AppText.caption.copyWith(
                                    color: isDanger
                                        ? AppColors.danger
                                        : StatusChip.colorOf(s),
                                    fontWeight: FontWeight.w800,
                                  ),
                                  onPressed: () => _changeStatus(o, s),
                                );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: AppSpace.x4),

              // ---------- الزبون ----------
              _card('الزبون', [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(o.customerName, style: AppText.h3),
                          const SizedBox(height: 2),
                          Text(o.phone,
                              style: AppText.bodySm.copyWith(color: AppColors.green700,
                                  fontWeight: FontWeight.w800)),
                          if (o.phoneAlt != null && o.phoneAlt!.isNotEmpty)
                            Text(o.phoneAlt!, style: AppText.caption),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpace.x3),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _launch('tel:${o.phone}'),
                        icon: const Icon(Icons.call, size: 17),
                        label: const Text('عيّط'),
                        style: OutlinedButton.styleFrom(minimumSize: const Size(0, 44)),
                      ),
                    ),
                    const SizedBox(width: AppSpace.x2),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _launch('https://wa.me/${_intl(o.phone)}'),
                        icon: const Icon(Icons.chat, size: 17),
                        label: const Text('واتساب'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 44),
                          foregroundColor: AppColors.success,
                          side: const BorderSide(color: AppColors.success),
                        ),
                      ),
                    ),
                  ],
                ),
              ]),
              const SizedBox(height: AppSpace.x3),

              // ---------- التوصيل ----------
              _card('التوصيل', [
                _row(Icons.place_outlined, 'الولاية', o.wilayaName),
                _row(Icons.location_city_outlined, 'البلدية', o.communeName),
                if (o.address != null && o.address!.isNotEmpty)
                  _row(Icons.home_outlined, 'العنوان', o.address!),
                _row(Icons.local_shipping_outlined, 'الطريقة', o.deliveryMode.ar),
                if (o.notes != null && o.notes!.isNotEmpty)
                  _row(Icons.notes_outlined, 'ملاحظة', o.notes!),
              ]),
              const SizedBox(height: AppSpace.x3),

              // ---------- المنتجات ----------
              _card('المنتجات (${o.items.length})', [
                ...o.items.map((it) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpace.x3),
                      child: Row(
                        children: [
                          ProductImage(url: it.imageUrl, width: 52, height: 52,
                              radius: AppRadius.sm),
                          const SizedBox(width: AppSpace.x3),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(it.title,
                                    maxLines: 2, overflow: TextOverflow.ellipsis,
                                    style: AppText.bodySm.copyWith(fontWeight: FontWeight.w700)),
                                if (it.variantInfo != null)
                                  Text(it.variantInfo!, style: AppText.caption),
                                Text('${it.quantity} × ${Money.dz(it.unitPrice)}',
                                    style: AppText.caption),
                              ],
                            ),
                          ),
                          PriceText(it.lineTotal, size: 14),
                        ],
                      ),
                    )),
                const Divider(),
                const SizedBox(height: AppSpace.x2),
                _totalRow('المجموع الفرعي', o.subtotal),
                _totalRow('التوصيل', o.deliveryPrice),
                if (o.discount > 0) _totalRow('تخفيض', -o.discount),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text('المجموع', style: AppText.h3),
                    const Spacer(),
                    PriceText(o.totalPrice, size: 22),
                  ],
                ),
              ]),
              const SizedBox(height: AppSpace.x3),

              // ---------- بون التوصيل ----------
              OutlinedButton.icon(
                onPressed: () => _showLabel(context),
                icon: const Icon(Icons.assignment_outlined),
                label: const Text('بون التوصيل (Bordereau)'),
              ),
              const SizedBox(height: AppSpace.x6),
            ],
          );
        },
      ),
    );
  }

  Widget _card(String title, List<Widget> children) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpace.x4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: AppText.h3),
            const SizedBox(height: AppSpace.x3),
            ...children,
          ],
        ),
      );

  Widget _row(IconData i, String k, String v) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(i, size: 15, color: AppColors.ink50),
            const SizedBox(width: 7),
            Text('$k: ', style: AppText.bodySm.copyWith(color: AppColors.ink50)),
            Expanded(
              child: Text(v,
                  style: AppText.bodySm.copyWith(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      );

  Widget _totalRow(String k, num v) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(
          children: [
            Text(k, style: AppText.bodySm.copyWith(color: AppColors.ink50)),
            const Spacer(),
            Text(Money.dz(v), style: AppText.bodySm.copyWith(fontWeight: FontWeight.w700)),
          ],
        ),
      );

  Widget _statusBar(OrderStatus s) {
    const steps = [
      OrderStatus.newOrder,
      OrderStatus.confirmed,
      OrderStatus.inDelivery,
      OrderStatus.delivered,
    ];
    if (s == OrderStatus.canceled) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpace.x3),
        decoration: BoxDecoration(
          color: AppColors.danger.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: Row(
          children: [
            const Icon(Icons.cancel_outlined, color: AppColors.danger, size: 18),
            const SizedBox(width: 8),
            Text('هاد الطلب ملغى', style: AppText.bodySm.copyWith(
                color: AppColors.danger, fontWeight: FontWeight.w800)),
          ],
        ),
      );
    }
    if (s == OrderStatus.postponed) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpace.x3),
        decoration: BoxDecoration(
          color: AppColors.warning.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: Row(
          children: [
            const Icon(Icons.pause_circle_outline, color: AppColors.warning, size: 18),
            const SizedBox(width: 8),
            Text('مؤجل — عاود عيّط للزبون',
                style: AppText.bodySm.copyWith(
                    color: AppColors.warning, fontWeight: FontWeight.w800)),
          ],
        ),
      );
    }
    final idx = steps.indexOf(s);
    return Row(
      children: List.generate(steps.length, (i) {
        final done = i <= idx;
        return Expanded(
          child: Column(
            children: [
              Row(
                children: [
                  if (i > 0)
                    Expanded(child: Container(height: 2,
                        color: done ? AppColors.green600 : AppColors.line)),
                  Container(
                    width: 22, height: 22,
                    decoration: BoxDecoration(
                      color: done ? AppColors.green700 : Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: done ? AppColors.green700 : AppColors.line, width: 2),
                    ),
                    child: Icon(done ? Icons.check : Icons.circle,
                        size: 11, color: done ? Colors.white : AppColors.ink30),
                  ),
                  if (i < steps.length - 1)
                    Expanded(child: Container(height: 2,
                        color: i < idx ? AppColors.green600 : AppColors.line)),
                ],
              ),
              const SizedBox(height: 4),
              Text(steps[i].ar, textAlign: TextAlign.center,
                  style: AppText.caption.copyWith(
                    fontSize: 10,
                    color: done ? AppColors.green700 : AppColors.ink30,
                    fontWeight: done ? FontWeight.w800 : FontWeight.w500,
                  )),
            ],
          ),
        );
      }),
    );
  }

  Future<void> _changeStatus(Order o, OrderStatus s) async {
    setState(() => _busy = true);
    try {
      final svc = SupabaseService.instance;
      if (!svc.isReady) {
        showSnack(context, 'التطبيق ماشي مربوط بـSupabase');
        return;
      }
      await svc.client.from('orders').update({'status': s.db}).eq('id', o.id);
      ref.invalidate(orderDetailProvider(widget.id));
      ref.invalidate(merchantOrdersProvider);
      ref.invalidate(storeStatsProvider);
      if (mounted) showSnack(context, 'ولّى: ${s.ar} ✓');
    } catch (e) {
      if (mounted) showSnack(context, AppException.from(e).message, error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _launch(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  String _intl(String p) {
    var x = p.replaceAll(RegExp(r'\D'), '');
    if (x.startsWith('0')) x = '213${x.substring(1)}';
    if (!x.startsWith('213')) x = '213$x';
    return x;
  }

  void _showLabel(BuildContext context) {
    final o = ref.read(orderDetailProvider(widget.id)).valueOrNull;
    if (o == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.85,
        builder: (c, ctrl) => Directionality(
          textDirection: TextDirection.rtl,
          child: ListView(
            controller: ctrl,
            padding: const EdgeInsets.all(AppSpace.x4),
            children: [
              Row(
                children: [
                  const Expanded(child: Text('بون التوصيل', style: AppText.h2)),
                  IconButton(
                    icon: const Icon(Icons.copy, size: 20),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: _labelText(o)));
                      showSnack(context, 'تحفظ ✓');
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(c),
                  ),
                ],
              ),
              const SizedBox(height: AppSpace.x3),
              // ---------- البون ----------
              Container(
                padding: const EdgeInsets.all(AppSpace.x4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  border: Border.all(color: AppColors.ink, width: 2),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Text('LATCHI STORE',
                            style: AppText.h2.copyWith(letterSpacing: 1)),
                        const Spacer(),
                        Text('BON DE LIVRAISON',
                            style: AppText.caption.copyWith(
                                fontWeight: FontWeight.w900, letterSpacing: 1)),
                      ],
                    ),
                    const Divider(height: 16, thickness: 2, color: AppColors.ink),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('N° ${o.orderNumber}',
                            style: AppText.h1.copyWith(fontSize: 22)),
                        Text(_fmtDate(o.createdAt), style: AppText.caption),
                      ],
                    ),
                    const SizedBox(height: AppSpace.x3),
                    _lbl('NOM / الاسم', o.customerName),
                    _lbl('TEL / الهاتف', o.phone),
                    _lbl('WILAYA / الولاية', '${o.wilayaCode} — ${o.wilayaName}'),
                    _lbl('COMMUNE / البلدية', o.communeName),
                    if (o.address != null) _lbl('ADRESSE / العنوان', o.address!),
                    _lbl('MODE / الطريقة', o.deliveryMode == DeliveryMode.home
                        ? 'À DOMICILE / للمنزل'
                        : 'STOP DESK / للمكتب'),
                    const Divider(height: 20, thickness: 2, color: AppColors.ink),
                    ...o.items.map((it) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text('${it.quantity} × ${it.title}',
                                    style: AppText.bodySm.copyWith(fontSize: 12.5)),
                              ),
                              Text(Money.dz(it.lineTotal),
                                  style: AppText.bodySm.copyWith(
                                      fontWeight: FontWeight.w800, fontSize: 12.5)),
                            ],
                          ),
                        )),
                    const Divider(height: 20, thickness: 2, color: AppColors.ink),
                    Row(
                      children: [
                        Text('TOTAL À PAYER',
                            style: AppText.h3.copyWith(letterSpacing: 0.5)),
                        const Spacer(),
                        Text(Money.dz(o.totalPrice),
                            style: AppText.h1.copyWith(fontSize: 24)),
                      ],
                    ),
                    const SizedBox(height: AppSpace.x3),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                          border: Border.all(color: AppColors.line)),
                      child: Text('الدفع عند الاستلام / PAIEMENT À LA LIVRAISON',
                          textAlign: TextAlign.center,
                          style: AppText.caption.copyWith(fontWeight: FontWeight.w800)),
                    ),
                    const SizedBox(height: AppSpace.x5),
                    Row(
                      children: [
                        Expanded(child: _sign('توقيع الزبون')),
                        const SizedBox(width: 12),
                        Expanded(child: _sign('توقيع الموزّع')),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpace.x4),
              OutlinedButton.icon(
                onPressed: () => Navigator.pop(c),
                icon: const Icon(Icons.print_outlined),
                label: const Text('طباعة (قريباً)'),
              ),
              const SizedBox(height: AppSpace.x6),
            ],
          ),
        ),
      ),
    );
  }

  Widget _lbl(String k, String v) => Padding(
        padding: const EdgeInsets.only(bottom: 5),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 130,
              child: Text(k, style: AppText.caption.copyWith(
                  fontSize: 10.5, fontWeight: FontWeight.w900)),
            ),
            Expanded(
              child: Text(v, style: AppText.bodySm.copyWith(
                  fontSize: 12.5, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      );

  Widget _sign(String t) => Column(
        children: [
          Container(height: 40, decoration:
              BoxDecoration(border: Border.all(color: AppColors.ink30))),
          const SizedBox(height: 4),
          Text(t, style: AppText.caption.copyWith(fontSize: 10)),
        ],
      );

  String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  String _labelText(Order o) => '''
LATCHI STORE — BON DE LIVRAISON
N° ${o.orderNumber} · ${_fmtDate(o.createdAt)}
الاسم: ${o.customerName}
الهاتف: ${o.phone}
الولاية: ${o.wilayaCode} — ${o.wilayaName}
البلدية: ${o.communeName}
${o.address != null ? "العنوان: ${o.address}\n" : ""}الطريقة: ${o.deliveryMode.ar}
---
${o.items.map((it) => "${it.quantity} × ${it.title} = ${Money.dz(it.lineTotal)}").join("\n")}
---
TOTAL: ${Money.dz(o.totalPrice)} (الدفع عند الاستلام)
''';
}
