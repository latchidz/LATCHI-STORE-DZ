import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/supabase_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/ui_kit.dart';
import '../../../shared/providers/app_providers.dart';

/// ============================================================
/// دخول التاجر — Email/Password عبر Supabase Auth
/// ============================================================
class MerchantLoginScreen extends ConsumerStatefulWidget {
  const MerchantLoginScreen({super.key});

  @override
  ConsumerState<MerchantLoginScreen> createState() => _MerchantLoginScreenState();
}

class _MerchantLoginScreenState extends ConsumerState<MerchantLoginScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _pass = TextEditingController();
  bool _loading = false;
  bool _obscure = true;
  bool _signup = false;

  @override
  void dispose() {
    _email.dispose();
    _pass.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final svc = SupabaseService.instance;
      if (!svc.isReady) throw const AppException('Supabase ماشي مضبوط — شوف env.dart');

      if (_signup) {
        await svc.auth.signUp(
          email: _email.text.trim(),
          password: _pass.text,
          data: {'role': 'merchant'},
        );
        if (mounted) {
          showSnack(context, 'تحلّ الحساب ✓ تحقّق من الإيميل');
        }
      } else {
        await svc.auth.signInWithPassword(
          email: _email.text.trim(),
          password: _pass.text,
        );
      }
      ref.invalidate(profileProvider);
      ref.invalidate(myStoreProvider);
      if (mounted) context.go('/merchant');
    } catch (e) {
      if (mounted) showSnack(context, AppException.from(e).message, error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_forward),
          onPressed: () => context.go('/merchant'),
        ),
      ),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(AppSpace.x5),
          children: [
            const SizedBox(height: AppSpace.x6),
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(
                color: AppColors.green50,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.storefront, color: AppColors.green700, size: 36),
            ),
            const SizedBox(height: AppSpace.x5),
            Text(_signup ? 'أنشئ حساب التاجر' : 'مرحبا بيك مرة أخرى',
                style: AppText.display.copyWith(fontSize: 26)),
            const SizedBox(height: AppSpace.x2),
            Text(
              _signup
                  ? 'سجّل باش تفتح متجرك وتبيع عبر التطبيق.'
                  : 'دخّل بريدك وكلمة السر باش تدخل للوحة التحكم.',
              style: AppText.bodySm.copyWith(color: AppColors.ink50),
            ),
            const SizedBox(height: AppSpace.x8),

            AppField(
              label: 'البريد الإلكتروني',
              hint: 'you@example.com',
              controller: _email,
              keyboard: TextInputType.emailAddress,
              icon: Icons.mail_outline,
              validator: (v) {
                final s = (v ?? '').trim();
                if (!s.contains('@') || !s.contains('.')) return 'بريد غير صحيح';
                return null;
              },
            ),
            const SizedBox(height: AppSpace.x4),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('كلمة السر', style: AppText.label),
                const SizedBox(height: AppSpace.x2),
                TextFormField(
                  controller: _pass,
                  obscureText: _obscure,
                  style: AppText.body,
                  decoration: InputDecoration(
                    hintText: '••••••••',
                    prefixIcon: const Icon(Icons.lock_outline, size: 20),
                    suffixIcon: IconButton(
                      icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility,
                          size: 20),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                  validator: (v) =>
                      (v ?? '').length < 6 ? 'كلمة السر قصيرة (6 على الأقل)' : null,
                ),
              ],
            ),
            const SizedBox(height: AppSpace.x6),
            AppButton(
              label: _signup ? 'أنشئ الحساب' : 'دخول',
              icon: _signup ? Icons.person_add : Icons.login,
              loading: _loading,
              onPressed: _submit,
            ),
            const SizedBox(height: AppSpace.x4),
            TextButton(
              onPressed: () => setState(() => _signup = !_signup),
              child: Text(_signup
                  ? 'عندي حساب — دخول'
                  : 'ما عندكش حساب؟ سجّل'),
            ),
            const SizedBox(height: AppSpace.x6),
            Container(
              padding: const EdgeInsets.all(AppSpace.x3),
              decoration: BoxDecoration(
                color: AppColors.gold100,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, size: 17, color: AppColors.gold600),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'ملاحظة: أول مستخدم يسجّل، لازم يتحوّل لـ"merchant" من SQL Editor.',
                      style: AppText.caption.copyWith(color: AppColors.gold600),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
