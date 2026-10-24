import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/providers/app_providers.dart';
import 'cart_screen.dart';
import 'home_screen.dart';
import 'profile_screen.dart';

/// ============================================================
/// هيكل واجهة الزبون — 4 تبويبات + زر سلة عائم
/// ============================================================
class CustomerShell extends ConsumerStatefulWidget {
  const CustomerShell({super.key});

  @override
  ConsumerState<CustomerShell> createState() => _CustomerShellState();
}

class _CustomerShellState extends ConsumerState<CustomerShell> {
  int _index = 0;

  static const _pages = [HomeScreen(), CartScreen(), OrderHistoryScreen(), ProfileScreen()];

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);

    return Scaffold(
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: const Border(top: BorderSide(color: AppColors.line)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 20, offset: const Offset(0, -4)),
          ],
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 64,
            child: Row(
              children: [
                _tab(0, Icons.storefront_outlined, Icons.storefront, 'المتجر'),
                _tab(1, Icons.shopping_cart_outlined, Icons.shopping_cart, 'السلة',
                    badge: cart.count),
                _tab(2, Icons.receipt_long_outlined, Icons.receipt_long, 'طلباتي'),
                _tab(3, Icons.person_outline, Icons.person, 'حسابي'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _tab(int i, IconData a, IconData b, String label, {int badge = 0}) {
    final active = _index == i;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _index = i),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(active ? b : a,
                    size: 24,
                    color: active ? AppColors.green700 : AppColors.ink50),
                if (badge > 0)
                  Positioned(
                    top: -6, left: -10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      constraints: const BoxConstraints(minWidth: 17),
                      decoration: BoxDecoration(
                        color: AppColors.danger,
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Text('$badge',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontFamily: 'Tajawal', fontSize: 10.5,
                              fontWeight: FontWeight.w800, color: Colors.white)),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 3),
            Text(label,
                style: AppText.caption.copyWith(
                  fontSize: 11,
                  color: active ? AppColors.green700 : AppColors.ink50,
                  fontWeight: active ? FontWeight.w800 : FontWeight.w500,
                )),
          ],
        ),
      ),
    );
  }
}

/// ---------- سجل الطلبات (يتطلب رقم هاتف) ----------
class OrderHistoryScreen extends ConsumerStatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  ConsumerState<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends ConsumerState<OrderHistoryScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('طلباتي')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpace.x6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 96, height: 96,
                decoration: const BoxDecoration(
                    color: AppColors.green50, shape: BoxShape.circle),
                child: const Icon(Icons.receipt_long_outlined,
                    size: 44, color: AppColors.green600),
              ),
              const SizedBox(height: AppSpace.x5),
              Text('تبّع طلبيتك', style: AppText.h3),
              const SizedBox(height: AppSpace.x2),
              Text(
                'دخّل رقم الطلب ورقم الهاتف باش تشوف وين وصلت.',
                textAlign: TextAlign.center,
                style: AppText.bodySm.copyWith(color: AppColors.ink50),
              ),
              const SizedBox(height: AppSpace.x6),
              AppButtonInline(
                label: 'تبّع طلب',
                onTap: () => context.go('/shop/track'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AppButtonInline extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const AppButtonInline({super.key, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      height: 52,
      child: FilledButton(onPressed: onTap, child: Text(label)),
    );
  }
}
