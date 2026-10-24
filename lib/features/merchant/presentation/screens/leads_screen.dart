import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/models/models.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/ui_kit.dart';
import '../../../../shared/providers/app_providers.dart';

/// ============================================================
/// السلات المتروكة (Leads) — أهم أداة ربح فـCOD
/// ============================================================
class LeadsScreen extends ConsumerWidget {
  const LeadsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(leadsProvider);

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: const Text('المتابعات'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(leadsProvider),
          ),
        ],
      ),
      body: async.when(
        loading: () => const ListSkeleton(count: 5, height: 90),
        error: (e, _) => ErrorView(
            error: e, onRetry: () => ref.invalidate(leadsProvider)),
        data: (list) {
          if (list.isEmpty) {
            return const EmptyState(
              icon: Icons.people_outline,
              title: 'ما كاينش متابعات',
              subtitle: 'كل زبون يبدا يعمّر النموذج وما يكمّلش، يبان هنا',
            );
          }
          final hot = list.where((l) => !l.recovered).toList();
          final done = list.where((l) => l.recovered).toList();

          return RefreshIndicator(
            color: AppColors.green700,
            onRefresh: () async {
              ref.invalidate(leadsProvider);
              await ref.read(leadsProvider.future);
            },
            child: ListView(
              padding: const EdgeInsets.all(AppSpace.x4),
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpace.x4),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [AppColors.gold600, AppColors.gold500]),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.local_fire_department,
                          color: Colors.white, size: 30),
                      const SizedBox(width: AppSpace.x3),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${hot.length} زبون محتمل',
                                style: AppText.h3.copyWith(color: Colors.white)),
                            Text('عمّرو النموذج وما كمّلو الطلب',
                                style: AppText.caption.copyWith(color: Colors.white70)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpace.x4),
                if (hot.isNotEmpty) ...[
                  const Text('🔥 ساخنين', style: AppText.h3),
                  const SizedBox(height: AppSpace.x2),
                  ...hot.map((l) => _LeadCard(lead: l)),
                ],
                if (done.isNotEmpty) ...[
                  const SizedBox(height: AppSpace.x4),
                  const Text('✅ تعاودو', style: AppText.h3),
                  const SizedBox(height: AppSpace.x2),
                  ...done.map((l) => _LeadCard(lead: l)),
                ],
                const SizedBox(height: AppSpace.x8),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _LeadCard extends ConsumerWidget {
  final AbandonedLead lead;
  const _LeadCard({required this.lead});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpace.x3),
      padding: const EdgeInsets.all(AppSpace.x3),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
            color: lead.recovered ? AppColors.line : AppColors.gold500.withValues(alpha: 0.4)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 42, height: 42,
                decoration: BoxDecoration(
                  color: (lead.recovered ? AppColors.ink50 : AppColors.gold600)
                      .withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  (lead.customerName ?? '?').trim().isEmpty
                      ? '?'
                      : lead.customerName!.trim()[0],
                  style: AppText.h3.copyWith(
                      color: lead.recovered ? AppColors.ink50 : AppColors.gold600),
                ),
              ),
              const SizedBox(width: AppSpace.x3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(lead.customerName ?? 'بلا اسم',
                        style: AppText.bodySm.copyWith(fontWeight: FontWeight.w800)),
                    Text(lead.phone,
                        style: AppText.caption.copyWith(
                            color: AppColors.green700, fontWeight: FontWeight.w700)),
                    if (lead.wilayaName != null)
                      Text('${lead.wilayaName}${lead.communeName != null ? " · ${lead.communeName}" : ""}',
                          style: AppText.caption.copyWith(fontSize: 11)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  PriceText(lead.cartTotal, size: 15),
                  Text(_ago(lead.createdAt),
                      style: AppText.caption.copyWith(fontSize: 10.5)),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpace.x2),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _wa(context, lead),
                  icon: const Icon(Icons.chat, size: 16),
                  label: const Text('واتساب'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 40),
                    foregroundColor: AppColors.success,
                    side: const BorderSide(color: AppColors.success),
                  ),
                ),
              ),
              const SizedBox(width: AppSpace.x2),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _call(lead.phone),
                  icon: const Icon(Icons.call, size: 16),
                  label: const Text('عيّط'),
                  style: OutlinedButton.styleFrom(minimumSize: const Size(0, 40)),
                ),
              ),
              const SizedBox(width: AppSpace.x2),
              if (!lead.recovered)
                IconButton(
                  tooltip: 'تعاود',
                  onPressed: () => _recover(context, ref),
                  icon: const Icon(Icons.check_circle_outline,
                      color: AppColors.success),
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _ago(DateTime d) {
    final diff = DateTime.now().difference(d);
    if (diff.inMinutes < 60) return 'قبل ${diff.inMinutes} د';
    if (diff.inHours < 24) return 'قبل ${diff.inHours} سا';
    return 'قبل ${diff.inDays} يوم';
  }

  Future<void> _call(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _wa(BuildContext context, AbandonedLead l) async {
    var p = l.phone.replaceAll(RegExp(r'\D'), '');
    if (p.startsWith('0')) p = '213${p.substring(1)}';
    if (!p.startsWith('213')) p = '213$p';
    final msg = Uri.encodeComponent(
        'السلام عليكم ${l.customerName ?? ''} 👋\n'
        'شوفنا بلي حبيت تشري من متجرنا وما كمّلتش الطلب.\n'
        'نقدر نعاونك؟ التوصيل متوفر والدفع عند الاستلام 💚');
    final uri = Uri.parse('https://wa.me/$p?text=$msg');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _recover(BuildContext context, WidgetRef ref) async {
    // TODO: استدعاء update على abandoned_leads
    showSnack(context, 'تعلّم كـ«تعاود» ✓');
  }
}
