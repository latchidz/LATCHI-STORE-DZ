import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/models/models.dart';
import '../../../../core/network/supabase_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/ui_kit.dart';

/// ============================================================
/// تتبع الطلب برقم الطلب + الهاتف (RPC track_order)
/// ============================================================
class TrackOrderScreen extends ConsumerStatefulWidget {
  const TrackOrderScreen({super.key});

  @override
  ConsumerState<TrackOrderScreen> createState() => _TrackOrderScreenState();
}

class _TrackOrderScreenState extends ConsumerState<TrackOrderScreen> {
  final _num = TextEditingController();
  final _phone = TextEditingController();
  bool _loading = false;
  Map<String, dynamic>? _result;
  String? _error;

  @override
  void dispose() {
    _num.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    setState(() {
      _loading = true;
      _error = null;
      _result = null;
    });
    try {
      final svc = SupabaseService.instance;
      if (!svc.isReady) {
        await Future.delayed(const Duration(milliseconds: 600));
        setState(() => _error = 'التطبيق ماشي مربوط بـSupabase بعد.');
        return;
      }
      final res = await svc.client.rpc('track_order', params: {
        'p_order_number': int.tryParse(_num.text.replaceAll(RegExp(r'\D'), '')) ?? 0,
        'p_phone': _phone.text.trim(),
      });
      if (res == null) {
        setState(() => _error = 'ما لقيناش طلب بهاد الرقم والهاتف.');
      } else {
        setState(() => _result = (res as Map).cast<String, dynamic>());
      }
    } catch (e) {
      setState(() => _error = AppException.from(e).message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تبّع طلبك'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_forward),
          onPressed: () => context.go('/shop'),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpace.x4),
        children: [
          if (_result == null) ...[
            Container(
              padding: const EdgeInsets.all(AppSpace.x4),
              decoration: BoxDecoration(
                color: AppColors.green50,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Column(
                children: [
                  const Icon(Icons.local_shipping_outlined,
                      size: 40, color: AppColors.green700),
                  const SizedBox(height: AppSpace.x2),
                  Text('دخّل رقم الطلب والهاتف اللي طلبت بيه',
                      textAlign: TextAlign.center,
                      style: AppText.bodySm.copyWith(color: AppColors.green800)),
                ],
              ),
            ),
            const SizedBox(height: AppSpace.x5),
            AppField(
              label: 'رقم الطلب',
              hint: 'مثال: 1042',
              controller: _num,
              keyboard: TextInputType.number,
              icon: Icons.tag,
            ),
            const SizedBox(height: AppSpace.x4),
            AppField(
              label: 'رقم الهاتف',
              hint: '05XX XX XX XX',
              controller: _phone,
              keyboard: TextInputType.phone,
              icon: Icons.phone_outlined,
            ),
            const SizedBox(height: AppSpace.x5),
            AppButton(
              label: 'قلّب على الطلب',
              icon: Icons.search,
              loading: _loading,
              onPressed: _search,
            ),
            if (_error != null) ...[
              const SizedBox(height: AppSpace.x4),
              Container(
                padding: const EdgeInsets.all(AppSpace.x3),
                decoration: BoxDecoration(
                  color: AppColors.danger.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: AppColors.danger, size: 18),
                    const SizedBox(width: 8),
                    Expanded(child: Text(_error!,
                        style: AppText.bodySm.copyWith(color: AppColors.danger))),
                  ],
                ),
              ),
            ],
          ] else
            _resultCard(),
        ],
      ),
    );
  }

  Widget _resultCard() {
    final r = _result!;
    final status = OrderStatusX.fromDb(r['status'] as String?);
    final created = DateTime.tryParse(r['created_at']?.toString() ?? '')?.toLocal();

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpace.x5),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.line),
          ),
          child: Column(
            children: [
              StatusChip(status: status),
              const SizedBox(height: AppSpace.x3),
              Text('طلب #${r['order_number']}',
                  style: AppText.h2.copyWith(color: AppColors.green700)),
              const SizedBox(height: 4),
              Text(r['customer_name']?.toString() ?? '', style: AppText.bodySm),
              const SizedBox(height: AppSpace.x4),
              const Divider(),
              const SizedBox(height: AppSpace.x4),
              _progress(status),
              const SizedBox(height: AppSpace.x5),
              _row('الولاية', r['wilaya']?.toString() ?? '—'),
              _row('البلدية', r['commune']?.toString() ?? '—'),
              _row('التوصيل',
                  DeliveryModeX.fromDb(r['delivery_mode'] as String?).ar),
              _row('المجموع', Money.dz((r['total'] as num?) ?? 0), highlight: true),
              if (created != null)
                _row('تاريخ الطلب',
                    '${created.day}/${created.month}/${created.year} '
                    '${created.hour.toString().padLeft(2, '0')}:'
                    '${created.minute.toString().padLeft(2, '0')}'),
            ],
          ),
        ),
        const SizedBox(height: AppSpace.x4),
        OutlinedButton.icon(
          onPressed: () => setState(() { _result = null; _error = null; }),
          icon: const Icon(Icons.search, size: 18),
          label: const Text('قلّب على طلب آخر'),
        ),
      ],
    );
  }

  Widget _progress(OrderStatus s) {
    const steps = [
      OrderStatus.newOrder,
      OrderStatus.confirmed,
      OrderStatus.inDelivery,
      OrderStatus.delivered,
    ];
    final idx = steps.indexOf(s);
    final isCanceled = s == OrderStatus.canceled;

    if (isCanceled) {
      return Container(
        padding: const EdgeInsets.all(AppSpace.x3),
        decoration: BoxDecoration(
          color: AppColors.danger.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: Row(
          children: [
            const Icon(Icons.cancel_outlined, color: AppColors.danger, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text('هاد الطلب تلغى. إذا ما فهمتش علاش، كلّمنا.',
                  style: AppText.bodySm.copyWith(color: AppColors.danger)),
            ),
          ],
        ),
      );
    }

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
                    width: 26, height: 26,
                    decoration: BoxDecoration(
                      color: done ? AppColors.green700 : Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: done ? AppColors.green700 : AppColors.line, width: 2),
                    ),
                    child: Icon(
                      done ? Icons.check : Icons.circle_outlined,
                      size: 14,
                      color: done ? Colors.white : AppColors.ink30,
                    ),
                  ),
                  if (i < steps.length - 1)
                    Expanded(child: Container(height: 2,
                        color: i < idx ? AppColors.green600 : AppColors.line)),
                ],
              ),
              const SizedBox(height: 6),
              Text(steps[i].ar,
                  textAlign: TextAlign.center,
                  style: AppText.caption.copyWith(
                    fontSize: 10.5,
                    color: done ? AppColors.green700 : AppColors.ink30,
                    fontWeight: done ? FontWeight.w800 : FontWeight.w500,
                  )),
            ],
          ),
        );
      }),
    );
  }

  Widget _row(String k, String v, {bool highlight = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Text(k, style: AppText.bodySm.copyWith(color: AppColors.ink50)),
            const Spacer(),
            Text(v,
                style: AppText.bodySm.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: highlight ? 16 : 13.5,
                  color: highlight ? AppColors.green700 : AppColors.ink,
                )),
          ],
        ),
      );
}
