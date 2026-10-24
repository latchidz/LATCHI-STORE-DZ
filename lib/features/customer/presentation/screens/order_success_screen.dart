import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/ui_kit.dart';

/// ============================================================
/// شاشة نجاح الطلب — أهم شاشة فـالتحويل
/// ============================================================
class OrderSuccessScreen extends StatelessWidget {
  final String orderNumber;
  final double total;
  final String phone;
  final String name;

  const OrderSuccessScreen({
    super.key, required this.orderNumber, required this.total,
    required this.phone, required this.name,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpace.x5),
          child: Column(
            children: [
              const Spacer(flex: 2),
              // علامة النجاح
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 700),
                curve: Curves.elasticOut,
                builder: (_, v, __) => Transform.scale(
                  scale: v,
                  child: Container(
                    width: 120, height: 120,
                    decoration: BoxDecoration(
                      color: AppColors.green50,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.green600, width: 3),
                    ),
                    child: const Icon(Icons.check_rounded,
                        size: 62, color: AppColors.green700),
                  ),
                ),
              ),
              const SizedBox(height: AppSpace.x6),
              Text('تسجّل طلبك! 🎉', style: AppText.display),
              const SizedBox(height: AppSpace.x2),
              Text(
                'راح نعيّطولك في أقرب وقت باش نأكدو الطلب.',
                textAlign: TextAlign.center,
                style: AppText.bodySm.copyWith(color: AppColors.ink50),
              ),
              const SizedBox(height: AppSpace.x6),

              // كارت رقم الطلب
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpace.x5),
                decoration: BoxDecoration(
                  color: AppColors.canvas,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: AppColors.line),
                ),
                child: Column(
                  children: [
                    Text('رقم الطلب', style: AppText.caption),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('#$orderNumber', style: AppText.display.copyWith(
                            color: AppColors.green700, letterSpacing: 1.5)),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.copy_rounded, size: 20),
                          color: AppColors.ink50,
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: orderNumber));
                            showSnack(context, 'تحفظ الرقم ✓');
                          },
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    _kv('الاسم', name),
                    _kv('الهاتف', phone),
                    _kv('المجموع', Money.dz(total), highlight: true),
                    _kv('الدفع', 'عند الاستلام'),
                  ],
                ),
              ),
              const Spacer(flex: 3),

              // الإجراءات
              AppButton(
                label: 'تبّع الطلب',
                icon: Icons.local_shipping_outlined,
                onPressed: () => context.go('/shop/track'),
              ),
              const SizedBox(height: AppSpace.x3),
              OutlinedButton.icon(
                onPressed: () => context.go('/shop'),
                icon: const Icon(Icons.storefront_outlined, size: 20),
                label: const Text('كمّل التسوّق'),
              ),
              const SizedBox(height: AppSpace.x4),
              TextButton.icon(
                onPressed: () {
                  // واتساب الدعم
                  showSnack(context, 'راح نفتح واتساب الدعم');
                },
                icon: const Icon(Icons.support_agent, size: 18),
                label: const Text('عندك مشكل؟ كلّمنا'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _kv(String k, String v, {bool highlight = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          children: [
            Text(k, style: AppText.bodySm.copyWith(color: AppColors.ink50)),
            const Spacer(),
            Text(v,
                style: AppText.bodySm.copyWith(
                  fontWeight: FontWeight.w800,
                  color: highlight ? AppColors.green700 : AppColors.ink,
                  fontSize: highlight ? 16 : 13.5,
                )),
          ],
        ),
      );
}
