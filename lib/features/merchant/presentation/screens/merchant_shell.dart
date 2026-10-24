import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/providers/app_providers.dart';
import 'dashboard_screen.dart';
import 'leads_screen.dart';
import 'orders_screen.dart';
import 'products_screen.dart';

/// ============================================================
/// هيكل لوحة التاجر — 4 تبويبات
/// ============================================================
class MerchantShell extends ConsumerStatefulWidget {
  const MerchantShell({super.key});

  @override
  ConsumerState<MerchantShell> createState() => _MerchantShellState();
}

class _MerchantShellState extends ConsumerState<MerchantShell> {
  int _index = 0;

  static const _pages = [
    DashboardScreen(),
    OrdersScreen(),
    ProductsScreen(),
    LeadsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final unread = ref.watch(unreadCountProvider).valueOrNull ?? 0;

    return Scaffold(
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppColors.line)),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 64,
            child: Row(
              children: [
                _tab(0, Icons.dashboard_outlined, Icons.dashboard, 'الرئيسية', unread),
                _tab(1, Icons.receipt_long_outlined, Icons.receipt_long, 'الطلبات'),
                _tab(2, Icons.inventory_2_outlined, Icons.inventory_2, 'المنتجات'),
                _tab(3, Icons.people_outline, Icons.people, 'المتابعات'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _tab(int i, IconData a, IconData b, String label, [int badge = 0]) {
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
                Icon(active ? b : a, size: 24,
                    color: active ? AppColors.green700 : AppColors.ink50),
                if (badge > 0)
                  Positioned(
                    top: -5, left: -9,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      constraints: const BoxConstraints(minWidth: 17),
                      decoration: BoxDecoration(
                        color: AppColors.danger,
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Text('$badge',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontFamily: 'Tajawal',
                              fontSize: 10.5, fontWeight: FontWeight.w800,
                              color: Colors.white)),
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
