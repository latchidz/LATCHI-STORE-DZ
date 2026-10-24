import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/models/models.dart';
import '../../../../core/network/supabase_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/dz_locations.dart';
import '../../../../core/widgets/ui_kit.dart';
import '../../../../shared/providers/app_providers.dart';

/// ============================================================
/// نموذج الطلب السريع — الدفع عند الاستلام
/// بلا حساب · 5 حقول فقط · أقل احتكاك ممكن
/// ============================================================
class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();
  final _notes = TextEditingController();

  String? _wilayaCode;
  String? _wilayaName;
  String? _commune;
  DeliveryMode _mode = DeliveryMode.home;
  bool _loading = false;
  bool _leadSaved = false;

  @override
  void initState() {
    super.initState();
    // نتبّعو التخلي عن السلة بعد ما يبدا يعمّر
    _phone.addListener(_maybeSaveLead);
  }

  @override
  void dispose() {
    _phone.removeListener(_maybeSaveLead);
    _name.dispose();
    _phone.dispose();
    _address.dispose();
    _notes.dispose();
    super.dispose();
  }

  /// يحفظ lead إذا كتب رقم هاتف صحيح وخرج بلا ما يكمّل
  void _maybeSaveLead() {
    final digits = _phone.text.replaceAll(RegExp(r'\D'), '');
    if (_leadSaved || digits.length < 9) return;
    _leadSaved = true;
    _saveLead();
  }

  Future<void> _saveLead() async {
    final svc = SupabaseService.instance;
    if (!svc.isReady) return;
    final cart = ref.read(cartProvider);
    if (cart.isEmpty) return;
    try {
      await svc.client.from('abandoned_leads').insert({
        'store_id': cart.storeId,
        'customer_name': _name.text.trim().isEmpty ? null : _name.text.trim(),
        'phone': _phone.text.trim(),
        'wilaya_code': _wilayaCode,
        'wilaya_name': _wilayaName,
        'commune_name': _commune,
        'address': _address.text.trim().isEmpty ? null : _address.text.trim(),
        'delivery_mode': _mode.db,
        'cart_snapshot': cart.lines
            .map((l) => {
                  'product_id': l.product.id,
                  'title': l.product.title,
                  'variant_id': l.variant?.id,
                  'variant': l.variant?.label,
                  'qty': l.qty,
                  'price': l.unitPrice,
                })
            .toList(),
        'cart_total': cart.subtotal,
        'step_reached': 'form',
      });
    } catch (_) {/* ما نوقفوش الزبون على خطأ تلمّ */}
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    final cart = ref.read(cartProvider);
    if (cart.isEmpty) {
      showSnack(context, 'السلة فارغة', error: true);
      return;
    }
    if (_wilayaCode == null || _commune == null) {
      showSnack(context, 'اختر الولاية والبلدية', error: true);
      return;
    }

    setState(() => _loading = true);
    try {
      final svc = SupabaseService.instance;

      if (!svc.isReady) {
        // وضع Demo: نولّد رقم طلب محلي
        await Future.delayed(const Duration(milliseconds: 700));
        final fake = DateTime.now().millisecondsSinceEpoch % 9000 + 1000;
        ref.read(cartProvider.notifier).clear();
        if (mounted) {
          context.go('/shop/success?n=$fake&t=${cart.subtotal}'
              '&p=${_phone.text.trim()}&name=${Uri.encodeComponent(_name.text.trim())}');
        }
        return;
      }

      final res = await svc.client.rpc('place_order', params: {
        'p_store_id': cart.storeId,
        'p_customer_name': _name.text.trim(),
        'p_phone': _phone.text.trim(),
        'p_phone_alt': null,
        'p_wilaya_code': _wilayaCode,
        'p_wilaya_name': _wilayaName,
        'p_commune_name': _commune,
        'p_address': _address.text.trim(),
        'p_delivery_mode': _mode.db,
        'p_notes': _notes.text.trim().isEmpty ? null : _notes.text.trim(),
        'p_items': cart.lines
            .map((l) => {
                  'product_id': l.product.id,
                  'variant_id': l.variant?.id,
                  'quantity': l.qty,
                })
            .toList(),
        'p_customer_id': svc.user?.id,
      });

      final map = (res as Map).cast<String, dynamic>();
      ref.read(cartProvider.notifier).clear();
      if (mounted) {
        context.go('/shop/success'
            '?n=${map['order_number']}'
            '&t=${map['total']}'
            '&p=${_phone.text.trim()}'
            '&name=${Uri.encodeComponent(_name.text.trim())}');
      }
    } catch (e) {
      if (mounted) showSnack(context, AppException.from(e).message, error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);
    final wilayas = DzLocations.instance.wilayas;

    if (cart.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('إتمام الطلب')),
        body: const EmptyState(icon: Icons.shopping_cart_outlined, title: 'السلة فارغة'),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('إتمام الطلب'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_forward),
          onPressed: () => context.go('/shop'),
        ),
      ),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(AppSpace.x4),
          children: [
            // ---------- تنبيه سريع ----------
            Container(
              padding: const EdgeInsets.all(AppSpace.x3),
              decoration: BoxDecoration(
                color: AppColors.gold100,
                borderRadius: BorderRadius.circular(AppRadius.sm),
                border: Border.all(color: AppColors.gold500.withValues(alpha: 0.35)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, size: 18, color: AppColors.gold600),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'بلا حساب وبلا كلمة سر — عمّر 3 معلومات وخلاص.',
                      style: AppText.caption.copyWith(color: AppColors.gold600,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpace.x4),

            // ---------- الاسم ----------
            AppField(
              label: 'الاسم الكامل *',
              hint: 'مثال: محمد بن علي',
              controller: _name,
              icon: Icons.person_outline,
              action: TextInputAction.next,
              validator: (v) {
                if (v == null || v.trim().length < 3) return 'اكتب اسمك الكامل';
                return null;
              },
            ),
            const SizedBox(height: AppSpace.x4),

            // ---------- الهاتف ----------
            AppField(
              label: 'رقم الهاتف *',
              hint: '05XX XX XX XX',
              controller: _phone,
              keyboard: TextInputType.phone,
              icon: Icons.phone_outlined,
              action: TextInputAction.next,
              validator: (v) {
                final d = (v ?? '').replaceAll(RegExp(r'\D'), '');
                if (d.length < 9) return 'رقم الهاتف ناقص';
                if (!RegExp(r'^0?[5-7]\d{8}$').hasMatch(d)) {
                  return 'الرقم لازم يبدا بـ05/06/07';
                }
                return null;
              },
            ),
            const SizedBox(height: AppSpace.x4),

            // ---------- الولاية ----------
            _DropdownField(
              label: 'الولاية *',
              value: _wilayaCode == null ? null : _wilayaName,
              hint: 'اختر الولاية',
              icon: Icons.map_outlined,
              onTap: () => _pickWilaya(wilayas),
            ),
            const SizedBox(height: AppSpace.x4),

            // ---------- البلدية ----------
            _DropdownField(
              label: 'البلدية *',
              value: _commune,
              hint: _wilayaCode == null ? 'اختر الولاية الأول' : 'اختر البلدية',
              icon: Icons.location_city_outlined,
              enabled: _wilayaCode != null,
              onTap: () => _pickCommune(),
            ),
            const SizedBox(height: AppSpace.x4),

            // ---------- العنوان ----------
            AppField(
              label: 'العنوان (اختياري)',
              hint: 'الحي، الشارع، رقم العمارة…',
              controller: _address,
              icon: Icons.home_outlined,
              maxLines: 2,
            ),
            const SizedBox(height: AppSpace.x4),

            // ---------- طريقة التوصيل ----------
            Text('طريقة التوصيل *', style: AppText.label),
            const SizedBox(height: AppSpace.x2),
            Row(
              children: [
                Expanded(
                  child: _modeCard(
                    title: 'للمنزل',
                    subtitle: 'حتى باب الدار',
                    icon: Icons.home_work_outlined,
                    active: _mode == DeliveryMode.home,
                    onTap: () => setState(() => _mode = DeliveryMode.home),
                  ),
                ),
                const SizedBox(width: AppSpace.x3),
                Expanded(
                  child: _modeCard(
                    title: 'للمكتب',
                    subtitle: 'أرخص · Stop Desk',
                    icon: Icons.store_mall_directory_outlined,
                    active: _mode == DeliveryMode.stopdesk,
                    onTap: () => setState(() => _mode = DeliveryMode.stopdesk),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpace.x4),

            // ---------- ملاحظة ----------
            AppField(
              label: 'ملاحظة للتوصيل (اختياري)',
              hint: 'مثال: عيّطلي قبل ما تجي',
              controller: _notes,
              icon: Icons.notes_outlined,
              maxLines: 2,
            ),
            const SizedBox(height: AppSpace.x6),

            // ---------- الملخص ----------
            Container(
              padding: const EdgeInsets.all(AppSpace.x4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: AppColors.line),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Text('${cart.count} منتج', style: AppText.bodySm),
                      const Spacer(),
                      PriceText(cart.subtotal, size: 16, color: AppColors.ink),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text('التوصيل', style: AppText.bodySm),
                      const Spacer(),
                      Text('يحدّده التاجر عند التأكيد',
                          style: AppText.caption.copyWith(color: AppColors.ink50)),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Divider(),
                  ),
                  Row(
                    children: [
                      Text('المجموع', style: AppText.h3),
                      const Spacer(),
                      PriceText(cart.subtotal, size: 22),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.payments_outlined, size: 15, color: AppColors.success),
                      const SizedBox(width: 5),
                      Text('الدفع عند الاستلام',
                          style: AppText.caption.copyWith(
                              color: AppColors.success, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpace.x4),
            const SizedBox(height: 80),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.fromLTRB(
          AppSpace.x4, AppSpace.x3, AppSpace.x4,
          MediaQuery.of(context).padding.bottom + AppSpace.x3),
        decoration: BoxDecoration(
          color: Colors.white,
          border: const Border(top: BorderSide(color: AppColors.line)),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 16, offset: const Offset(0, -4)),
          ],
        ),
        child: AppButton(
          label: 'أكّد الطلب — ${Money.dz(cart.subtotal)}',
          icon: Icons.check_circle_outline,
          loading: _loading,
          onPressed: _submit,
        ),
      ),
    );
  }

  Widget _modeCard({
    required String title, required String subtitle, required IconData icon,
    required bool active, required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.all(AppSpace.x3),
        decoration: BoxDecoration(
          color: active ? AppColors.green50 : Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(
            color: active ? AppColors.green700 : AppColors.line,
            width: active ? 1.6 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: active ? AppColors.green700 : AppColors.ink50, size: 24),
            const SizedBox(height: 6),
            Text(title, style: AppText.bodySm.copyWith(
                fontWeight: FontWeight.w800,
                color: active ? AppColors.green800 : AppColors.ink)),
            Text(subtitle, style: AppText.caption, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  // ---------- منتقي الولاية ----------
  void _pickWilaya(List<Wilaya> wilayas) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      builder: (c) => _PickerSheet(
        title: 'اختر الولاية',
        searchHint: 'قلّب على الولاية…',
        items: wilayas.map((w) => (w.display, w.ar, w.code)).toList(),
        onPick: (code, ar) {
          setState(() {
            _wilayaCode = code;
            _wilayaName = '$code — $ar';
            _commune = null;
          });
          Navigator.pop(c);
        },
      ),
    );
  }

  void _pickCommune() {
    final list = DzLocations.instance.communesOf(_wilayaCode);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      builder: (c) => _PickerSheet(
        title: 'اختر البلدية',
        searchHint: 'قلّب على البلدية…',
        items: list.map((e) => (e.ar, e.fr, e.code)).toList(),
        onPick: (code, ar) {
          setState(() => _commune = ar);
          Navigator.pop(c);
        },
      ),
    );
  }
}

/// ---------- حقل يشبه الـfield بس يفتح منتقي ----------
class _DropdownField extends StatelessWidget {
  final String label;
  final String? value;
  final String hint;
  final IconData icon;
  final VoidCallback onTap;
  final bool enabled;

  const _DropdownField({
    required this.label, required this.value, required this.hint,
    required this.icon, required this.onTap, this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppText.label),
        const SizedBox(height: AppSpace.x2),
        InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          child: Container(
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: AppSpace.x4),
            decoration: BoxDecoration(
              color: enabled ? Colors.white : AppColors.canvas,
              borderRadius: BorderRadius.circular(AppRadius.sm),
              border: Border.all(color: AppColors.line),
            ),
            child: Row(
              children: [
                Icon(icon, size: 20, color: AppColors.ink50),
                const SizedBox(width: AppSpace.x3),
                Expanded(
                  child: Text(
                    value ?? hint,
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: AppText.body.copyWith(
                        color: value != null ? AppColors.ink : AppColors.ink30),
                  ),
                ),
                const Icon(Icons.expand_more, color: AppColors.ink50, size: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// ---------- لوحة اختيار قابلة للبحث ----------
class _PickerSheet extends StatefulWidget {
  final String title;
  final String searchHint;
  final List<(String, String, String)> items; // (display, secondary, code)
  final void Function(String code, String label) onPick;

  const _PickerSheet({
    required this.title, required this.searchHint,
    required this.items, required this.onPick,
  });

  @override
  State<_PickerSheet> createState() => _PickerSheetState();
}

class _PickerSheetState extends State<_PickerSheet> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final filtered = _q.isEmpty
        ? widget.items
        : widget.items.where((e) =>
            e.$1.contains(_q) || e.$2.toLowerCase().contains(_q.toLowerCase())).toList();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.78,
        maxChildSize: 0.94,
        minChildSize: 0.5,
        builder: (c, ctrl) => Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 44, height: 4,
              decoration: BoxDecoration(
                  color: AppColors.line, borderRadius: BorderRadius.circular(2)),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpace.x4),
              child: Row(
                children: [
                  Expanded(child: Text(widget.title, style: AppText.h2)),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(c),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpace.x4),
              child: TextField(
                autofocus: false,
                style: AppText.body,
                onChanged: (v) => setState(() => _q = v),
                decoration: InputDecoration(
                  hintText: widget.searchHint,
                  prefixIcon: const Icon(Icons.search, size: 20),
                ),
              ),
            ),
            const SizedBox(height: AppSpace.x3),
            Expanded(
              child: ListView.separated(
                controller: ctrl,
                itemCount: filtered.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (_, i) {
                  final e = filtered[i];
                  return ListTile(
                    title: Text(e.$1, style: AppText.body),
                    subtitle: e.$2.isNotEmpty ? Text(e.$2, style: AppText.caption) : null,
                    trailing: const Icon(Icons.arrow_back_ios_new, size: 13, color: AppColors.ink30),
                    onTap: () => widget.onPick(e.$3, e.$2.isEmpty ? e.$1 : e.$2),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
