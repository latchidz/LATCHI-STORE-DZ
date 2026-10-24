import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/merchant_login_screen.dart';
import '../../features/customer/presentation/screens/catalog_screen.dart';
import '../../features/customer/presentation/screens/checkout_screen.dart';
import '../../features/customer/presentation/screens/customer_shell.dart';
import '../../features/customer/presentation/screens/order_success_screen.dart';
import '../../features/customer/presentation/screens/product_screen.dart';
import '../../features/customer/presentation/screens/track_order_screen.dart';
import '../../features/merchant/presentation/screens/lead_detail_screen.dart';
import '../../features/merchant/presentation/screens/merchant_shell.dart';
import '../../features/merchant/presentation/screens/order_detail_screen.dart';
import '../../features/merchant/presentation/screens/product_form_screen.dart';
import '../../features/merchant/presentation/screens/store_settings_screen.dart';
import '../../features/onboarding/presentation/role_picker_screen.dart';
import '../../shared/providers/app_providers.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = ValueNotifier<String?>(null);

  ref.listen(roleProvider, (prev, next) {
    notifier.value = next;
  }, fireImmediately: true);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: notifier,
    redirect: (context, state) {
      final persona = ref.read(roleProvider);
      final loc = state.matchedLocation;

      // لا اختيار شخصية بعد ⇒ شاشة الاختيار
      if (persona == null) {
        return loc == '/welcome' ? null : '/welcome';
      }
      // اختار الزبون ولا التاجر ⇒ ما يبقاش في welcome
      if (loc == '/welcome') {
        return persona == 'merchant' ? '/merchant' : '/shop';
      }
      // التاجر ما يدخلش للواجهة الزبون
      if (persona == 'merchant' && loc.startsWith('/shop')) return '/merchant';
      if (persona == 'customer' && loc.startsWith('/merchant')) return '/shop';
      return null;
    },
    routes: [
      GoRoute(path: '/welcome', builder: (_, __) => const RolePickerScreen()),

      // ---------- CUSTOMER ----------
      GoRoute(
        path: '/shop',
        builder: (_, __) => const CustomerShell(),
        routes: [
          GoRoute(path: 'product/:id', builder: (_, s) => ProductScreen(id: s.pathParameters['id']!)),
          GoRoute(path: 'checkout', builder: (_, __) => const CheckoutScreen()),
          GoRoute(
            path: 'success',
            builder: (_, s) => OrderSuccessScreen(
              orderNumber: s.uri.queryParameters['n'] ?? '',
              total: double.tryParse(s.uri.queryParameters['t'] ?? '') ?? 0,
              phone: s.uri.queryParameters['p'] ?? '',
              name: s.uri.queryParameters['name'] ?? '',
            ),
          ),
          GoRoute(path: 'track', builder: (_, __) => const TrackOrderScreen()),
          GoRoute(path: 'catalog', builder: (_, __) => const CatalogScreen(standalone: true)),
        ],
      ),

      // ---------- MERCHANT ----------
      GoRoute(path: '/merchant', builder: (_, __) => const MerchantShell()),
      GoRoute(path: '/merchant/login', builder: (_, __) => const MerchantLoginScreen()),
      GoRoute(path: '/merchant/orders/:id', builder: (_, s) => OrderDetailScreen(id: s.pathParameters['id']!)),
      GoRoute(path: '/merchant/leads/:id', builder: (_, s) => LeadDetailScreen(id: s.pathParameters['id']!)),
      GoRoute(path: '/merchant/products/new', builder: (_, __) => const ProductFormScreen()),
      GoRoute(path: '/merchant/products/:id/edit', builder: (_, s) => ProductFormScreen(id: s.pathParameters['id'])),
      GoRoute(path: '/merchant/settings', builder: (_, __) => const StoreSettingsScreen()),
    ],
    errorBuilder: (ctx, s) => Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('الصفحة ما لقيناهاش', style: TextStyle(fontSize: 18)),
            const SizedBox(height: 12),
            Text(s.uri.toString()),
            const SizedBox(height: 20),
            FilledButton(onPressed: () => ctx.go('/'), child: const Text('رجوع')),
          ],
        ),
      ),
    ),
  );
});
