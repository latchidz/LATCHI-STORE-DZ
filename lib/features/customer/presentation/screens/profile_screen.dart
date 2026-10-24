import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/env.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/ui_kit.dart';
import '../../../../shared/providers/app_providers.dart';

/// ============================================================
/// حسابي — بسيط بلا تسجيل إجباري
/// ============================================================
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('حسابي')),
      body: ListView(
        children: [
          // ---------- الهوية ----------
          Container(
            margin: const EdgeInsets.all(AppSpace.x4),
            padding: const EdgeInsets.all(AppSpace.x5),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.green700, AppColors.green600],
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
              ),
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: Row(
              children: [
                Container(
                  width: 58, height: 58,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.person, color: Colors.white, size: 30),
                ),
                const SizedBox(width: AppSpace.x4),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('مرحبا بيك 👋',
                          style: AppText.h3.copyWith(color: Colors.white)),
                      const SizedBox(height: 2),
                      Text('تسوّق بلا حساب، والدفع عند الاستلام',
                          style: AppText.caption.copyWith(color: Colors.white70)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ---------- الوصول السريع ----------
          _tile(Icons.local_shipping_outlined, 'تبّع طلب',
              'شوف وين وصلت سلعتك', () => context.go('/shop/track')),
          _tile(Icons.receipt_long_outlined, 'طلباتي', 'طلباتك السابقة',
              () => context.go('/shop')),
          const Divider(height: 24),

          // ---------- المعلومات ----------
          _tile(Icons.local_shipping_outlined, 'التوصيل',
              'توصيل لكل 69 ولاية · من 2 لـ5 أيام', null),
          _tile(Icons.payments_outlined, 'الدفع', 'الدفع عند الاستلام فقط', null),
          _tile(Icons.assignment_return_outlined, 'التبديل',
              'خلال 48 ساعة إذا كان مشكل', null),
          const Divider(height: 24),

          // ---------- الدعم ----------
          _tile(Icons.chat_bubble_outline, 'كلّمنا على واتساب',
              'نردو عليك في دقائق', () {
            showSnack(context, 'واتساب: +${Env.supportWhatsApp}');
          }),
          _tile(Icons.info_outline, 'على التطبيق', 'LATCHI STORE DZ v${Env.appVersion}', null),
          const Divider(height: 24),

          // ---------- التبديل ----------
          _tile(Icons.storefront_outlined, 'أنا تاجر',
              'بدّل للوحة تحكم التاجر', () async {
            await ref.read(roleProvider.notifier).clear();
            await ref.read(roleProvider.notifier).pick('merchant');
          }, accent: AppColors.gold600),

          const SizedBox(height: AppSpace.x8),
        ],
      ),
    );
  }

  Widget _tile(IconData icon, String title, String subtitle, VoidCallback? onTap,
      {Color? accent}) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 42, height: 42,
        decoration: BoxDecoration(
          color: (accent ?? AppColors.green700).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: Icon(icon, size: 20, color: accent ?? AppColors.green700),
      ),
      title: Text(title, style: AppText.bodySm.copyWith(fontWeight: FontWeight.w800)),
      subtitle: Text(subtitle, style: AppText.caption),
      trailing: onTap == null
          ? null
          : const Icon(Icons.arrow_back_ios_new, size: 13, color: AppColors.ink30),
    );
  }
}
