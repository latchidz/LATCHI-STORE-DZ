import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/models/models.dart';
import '../../../../core/network/supabase_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/ui_kit.dart';
import '../../../../shared/providers/app_providers.dart';

/// ============================================================
/// إعدادات المتجر
/// ============================================================
class StoreSettingsScreen extends ConsumerStatefulWidget {
  const StoreSettingsScreen({super.key});

  @override
  ConsumerState<StoreSettingsScreen> createState() => _StoreSettingsScreenState();
}

class _StoreSettingsScreenState extends ConsumerState<StoreSettingsScreen> {
  final _name = TextEditingController();
  final _desc = TextEditingController();
  final _phone = TextEditingController();
  final _whatsapp = TextEditingController();
  bool _home = true;
  bool _desk = true;
  bool _init = false;
  bool _saving = false;

  @override
  void dispose() {
    for (final c in [_name, _desc, _phone, _whatsapp]) {
      c.dispose();
    }
    super.dispose();
  }

  void _hydrate(Store s) {
    if (_init) return;
    _init = true;
    _name.text = s.name;
    _desc.text = s.description ?? '';
    _phone.text = s.phone ?? '';
    _whatsapp.text = s.whatsapp ?? '';
    _home = s.homeDelivery;
    _desk = s.stopdesk;
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final svc = SupabaseService.instance;
      final s = ref.read(myStoreProvider).valueOrNull;
      if (s == null) throw const AppException('ما لقيناش المتجر');
      await svc.client.from('stores').update({
        'name': _name.text.trim(),
        'description': _desc.text.trim(),
        'phone': _phone.text.trim(),
        'whatsapp': _whatsapp.text.trim(),
        'home_delivery': _home,
        'stopdesk': _desk,
      }).eq('id', s.id);
      ref.invalidate(myStoreProvider);
      ref.invalidate(publicStoreProvider);
      if (mounted) showSnack(context, 'تحفظ ✓');
    } catch (e) {
      if (mounted) showSnack(context, AppException.from(e).message, error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final storeAsync = ref.watch(myStoreProvider);
    if (storeAsync.valueOrNull != null) _hydrate(storeAsync.value!);

    return Scaffold(
      appBar: AppBar(
        title: const Text('إعدادات المتجر'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_forward),
          onPressed: () => context.go('/merchant'),
        ),
      ),
      body: storeAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorView(error: e),
        data: (s) {
          if (s == null) {
            return const EmptyState(
              icon: Icons.storefront_outlined,
              title: 'ما عندكش متجر',
              subtitle: 'لازم تنشئ متجر باش تبيع',
            );
          }
          return ListView(
            padding: const EdgeInsets.all(AppSpace.x4),
            children: [
              // ---------- معلومات ----------
              _card('معلومات المتجر', [
                AppField(label: 'اسم المتجر', controller: _name, icon: Icons.store),
                const SizedBox(height: AppSpace.x3),
                AppField(label: 'الوصف', controller: _desc, maxLines: 3,
                    icon: Icons.notes),
              ]),
              const SizedBox(height: AppSpace.x3),
              _card('الاتصال', [
                AppField(label: 'الهاتف', controller: _phone,
                    keyboard: TextInputType.phone, icon: Icons.phone),
                const SizedBox(height: AppSpace.x3),
                AppField(label: 'واتساب', controller: _whatsapp,
                    keyboard: TextInputType.phone, icon: Icons.chat),
              ]),
              const SizedBox(height: AppSpace.x3),
              _card('التوصيل', [
                SwitchListTile(
                  value: _home,
                  onChanged: (v) => setState(() => _home = v),
                  title: Text('توصيل للمنزل', style: AppText.bodySm),
                  activeThumbColor: AppColors.green700,
                  contentPadding: EdgeInsets.zero,
                ),
                SwitchListTile(
                  value: _desk,
                  onChanged: (v) => setState(() => _desk = v),
                  title: Text('توصيل للمكتب (Stop Desk)', style: AppText.bodySm),
                  activeThumbColor: AppColors.green700,
                  contentPadding: EdgeInsets.zero,
                ),
              ]),
              const SizedBox(height: AppSpace.x5),
              AppButton(label: 'حفظ', icon: Icons.check, loading: _saving, onPressed: _save),
              const SizedBox(height: AppSpace.x4),
              Center(
                child: TextButton.icon(
                  onPressed: () async {
                    await ref.read(roleProvider.notifier).clear();
                    await ref.read(roleProvider.notifier).pick('customer');
                  },
                  icon: const Icon(Icons.swap_horiz),
                  label: const Text('بدّل لواجهة الزبون'),
                ),
              ),
              const SizedBox(height: 60),
            ],
          );
        },
      ),
    );
  }

  Widget _card(String title, List<Widget> children) => Container(
        padding: const EdgeInsets.all(AppSpace.x4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [Text(title, style: AppText.h3), const SizedBox(height: AppSpace.x3), ...children],
        ),
      );
}
