import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/providers/app_providers.dart';

/// ============================================================
/// أول شاشة: "أنا زبون" / "أنا تاجر"
/// ============================================================
class RolePickerScreen extends ConsumerStatefulWidget {
  const RolePickerScreen({super.key});

  @override
  ConsumerState<RolePickerScreen> createState() => _RolePickerScreenState();
}

class _RolePickerScreenState extends ConsumerState<RolePickerScreen> {
  String? _hover;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.green900,
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(flex: 2),
            // ---- الشعار ----
            Container(
              width: 108, height: 108,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 40, offset: const Offset(0, 16)),
                ],
              ),
              alignment: Alignment.center,
              child: const _BagMark(size: 56),
            ),
            const SizedBox(height: AppSpace.x5),
            const Text('LATCHI STORE',
                style: TextStyle(
                  fontFamily: 'Tajawal', fontSize: 26, fontWeight: FontWeight.w900,
                  color: Colors.white, letterSpacing: 1.2)),
            const SizedBox(height: AppSpace.x1),
            Text('متجرك الجزائري — الدفع عند الاستلام',
                style: AppText.bodySm.copyWith(color: Colors.white70)),
            const Spacer(flex: 2),

            // ---- الاختيار ----
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpace.x5),
              child: Column(
                children: [
                  _PersonaCard(
                    title: 'أنا زبون',
                    subtitle: 'تسوّق بلا حساب · الدفع عند الاستلام',
                    icon: Icons.shopping_bag_outlined,
                    accent: AppColors.gold500,
                    selected: _hover == 'customer',
                    onTap: () => ref.read(roleProvider.notifier).pick('customer'),
                  ),
                  const SizedBox(height: AppSpace.x3),
                  _PersonaCard(
                    title: 'أنا تاجر',
                    subtitle: 'لوحة تحكم · منتجات · طلبات · توصيل',
                    icon: Icons.storefront_outlined,
                    accent: AppColors.green500,
                    selected: _hover == 'merchant',
                    onTap: () => ref.read(roleProvider.notifier).pick('merchant'),
                  ),
                ],
              ),
            ),
            const Spacer(flex: 2),
            Text('v1.0.0 · LATCHI STORE DZ',
                style: AppText.caption.copyWith(color: Colors.white30)),
            const SizedBox(height: AppSpace.x5),
          ],
        ),
      ),
    );
  }
}

class _PersonaCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final bool selected;
  final VoidCallback onTap;

  const _PersonaCard({
    required this.title, required this.subtitle, required this.icon,
    required this.accent, required this.selected, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(AppSpace.x5),
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
              color: selected ? Colors.white : Colors.white.withValues(alpha: 0.16),
              width: 1.4,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 54, height: 54,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: selected ? 0.16 : 0.22),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(icon, color: selected ? accent : Colors.white, size: 26),
              ),
              const SizedBox(width: AppSpace.x4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: AppText.h2.copyWith(
                            color: selected ? AppColors.ink : Colors.white)),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: AppText.caption.copyWith(
                            color: selected ? AppColors.ink50 : Colors.white60)),
                  ],
                ),
              ),
              Icon(Icons.arrow_back_ios_new_rounded,
                  size: 16,
                  color: selected ? AppColors.green700 : Colors.white38),
            ],
          ),
        ),
      ),
    );
  }
}

/// أيقونة الكيس + الهلال (SVG مصغّر بـFlutter primitives)
class _BagMark extends StatelessWidget {
  final double size;
  const _BagMark({required this.size});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size, height: size,
      child: CustomPaint(painter: _BagPainter(color: AppColors.green700)),
    );
  }
}

class _BagPainter extends CustomPainter {
  final Color color;
  const _BagPainter({required this.color});

  @override
  void paint(Canvas canvas, Size s) {
    final paint = Paint()..color = color..isAntiAlias = true;
    final w = s.width, h = s.height;

    // المقبض
    final handle = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.10
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;
    canvas.drawArc(
      Rect.fromLTWH(w * 0.30, h * 0.06, w * 0.40, h * 0.36),
      3.14159, 3.14159, false, handle,
    );

    // الجسم
    final body = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.14, h * 0.34, w * 0.72, h * 0.60),
      Radius.circular(w * 0.11),
    );
    canvas.drawRRect(body, paint);

    // الهلال (بلون الخلفية)
    final bg = Paint()..color = Colors.white..isAntiAlias = true;
    final c = Offset(w * 0.42, h * 0.64);
    final r = w * 0.13;
    canvas.drawCircle(c, r, bg);
    final path = Path.combine(
      PathOperation.difference,
      Path()..addOval(Rect.fromCircle(center: c, radius: r)),
      Path()..addOval(Rect.fromCircle(center: c.translate(r * 0.55, -r * 0.22), radius: r * 0.88)),
    );
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _BagPainter old) => old.color != color;
}
