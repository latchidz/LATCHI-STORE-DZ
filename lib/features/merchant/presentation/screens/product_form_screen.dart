import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:storage_client/storage_client.dart' show FileOptions;

import '../../../../core/models/models.dart';
import '../../../../core/network/supabase_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/ui_kit.dart';
import '../../../../shared/providers/app_providers.dart';
import 'products_screen.dart';

/// ============================================================
/// إضافة / تعديل منتج
/// ============================================================
class ProductFormScreen extends ConsumerStatefulWidget {
  final String? id;
  const ProductFormScreen({super.key, this.id});

  @override
  ConsumerState<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends ConsumerState<ProductFormScreen> {
  final _form = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _desc = TextEditingController();
  final _price = TextEditingController();
  final _compare = TextEditingController();
  final _stock = TextEditingController(text: '0');
  final _sku = TextEditingController();
  final _badge = TextEditingController();

  final List<String> _images = [];
  final List<XFile> _newFiles = [];
  String? _categoryId;
  bool _featured = false;
  bool _active = true;
  bool _loading = false;
  bool _init = false;

  // متغيّرات: اسم + قيم
  final List<(String, List<String>)> _variantSchema = [];

  bool get isEdit => widget.id != null;

  @override
  void dispose() {
    for (final c in [_title, _desc, _price, _compare, _stock, _sku, _badge]) {
      c.dispose();
    }
    super.dispose();
  }

  void _hydrate(Product p) {
    if (_init) return;
    _init = true;
    _title.text = p.title;
    _desc.text = p.description ?? '';
    _price.text = p.price.toString();
    _compare.text = p.comparePrice?.toString() ?? '';
    _stock.text = p.stock.toString();
    _badge.text = p.badge ?? '';
    _categoryId = p.categoryId;
    _featured = p.isFeatured;
    _active = p.isActive;
    _images.addAll(p.images);
    for (final s in p.variantSchema) {
      _variantSchema.add((s.name, List.of(s.options)));
    }
  }

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final files = await picker.pickMultiImage(imageQuality: 82, maxWidth: 1600);
    if (files.isEmpty) return;
    setState(() => _newFiles.addAll(files.take(5 - _images.length)));
  }

  Future<List<String>> _upload() async {
    final svc = SupabaseService.instance;
    final urls = <String>[];
    for (final f in _newFiles) {
      final bytes = await f.readAsBytes();
      final uid = svc.user?.id ?? 'anon';
      final path = '$uid/${DateTime.now().millisecondsSinceEpoch}_${f.name}';
      await svc.client.storage
          .from('product-images')
          .uploadBinary(path, bytes,
              fileOptions: const FileOptions(
                  contentType: 'image/jpeg', upsert: false));
      urls.add(svc.client.storage.from('product-images').getPublicUrl(path));
    }
    return urls;
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final svc = SupabaseService.instance;
      final store = await ref.read(myStoreProvider.future);
      if (store == null) throw const AppException('ما لقيناش المتجر');

      final uploaded = await _upload();
      final allImages = [..._images, ...uploaded];

      final payload = {
        'store_id': store.id,
        'category_id': _categoryId,
        'title': _title.text.trim(),
        'description': _desc.text.trim().isEmpty ? null : _desc.text.trim(),
        'price': int.tryParse(_price.text.trim()) ?? 0,
        'compare_price': int.tryParse(_compare.text.trim()),
        'stock': int.tryParse(_stock.text.trim()) ?? 0,
        'sku': _sku.text.trim().isEmpty ? null : _sku.text.trim(),
        'badge': _badge.text.trim().isEmpty ? null : _badge.text.trim(),
        'images': allImages,
        'variant_schema': _variantSchema
            .where((v) => v.$1.trim().isNotEmpty && v.$2.isNotEmpty)
            .map((v) => {'name': v.$1.trim(), 'options': v.$2})
            .toList(),
        'is_featured': _featured,
        'is_active': _active,
      };

      if (isEdit) {
        await svc.client.from('products').update(payload).eq('id', widget.id!);
      } else {
        await svc.client.from('products').insert(payload);
      }

      ref.invalidate(merchantProductsProvider);
      ref.invalidate(productsProvider);
      ref.invalidate(featuredProductsProvider);
      if (mounted) {
        showSnack(context, isEdit ? 'تحدّث ✓' : 'تزاد ✓');
        context.go('/merchant');
      }
    } catch (e) {
      if (mounted) showSnack(context, AppException.from(e).message, error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cats = ref.watch(categoriesProvider);

    if (isEdit) {
      final pAsync = ref.watch(productProvider(widget.id!));
      if (pAsync.valueOrNull != null) _hydrate(pAsync.value!);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'تعديل المنتج' : 'منتج جديد'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_forward),
          onPressed: () => context.go('/merchant'),
        ),
      ),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(AppSpace.x4),
          children: [
            // ---------- الصور ----------
            Text('الصور (حتى 5)', style: AppText.label),
            const SizedBox(height: AppSpace.x2),
            SizedBox(
              height: 92,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  ..._images.asMap().entries.map((e) => Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: Stack(
                          children: [
                            ProductImage(url: e.value, width: 88, height: 88),
                            Positioned(
                              top: 2, left: 2,
                              child: GestureDetector(
                                onTap: () => setState(() => _images.removeAt(e.key)),
                                child: Container(
                                  padding: const EdgeInsets.all(3),
                                  decoration: const BoxDecoration(
                                      color: AppColors.danger, shape: BoxShape.circle),
                                  child: const Icon(Icons.close,
                                      size: 12, color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        ),
                      )),
                  ..._newFiles.map((f) => Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          child: Image.file(File(f.path), width: 88, height: 88, fit: BoxFit.cover),
                        ),
                      )),
                  if (_images.length + _newFiles.length < 5)
                    GestureDetector(
                      onTap: _pickImages,
                      child: Container(
                        width: 88, height: 88,
                        decoration: BoxDecoration(
                          color: AppColors.green50,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          border: Border.all(color: AppColors.green600, width: 1.4),
                        ),
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_photo_alternate_outlined,
                                color: AppColors.green700),
                            SizedBox(height: 4),
                            Text('زيد', style: TextStyle(
                                fontFamily: 'Tajawal', fontSize: 12,
                                color: AppColors.green700, fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSpace.x4),

            AppField(
              label: 'اسم المنتج *',
              hint: 'مثال: قميص رجالي قطن',
              controller: _title,
              icon: Icons.title,
              validator: (v) => (v ?? '').trim().length < 3 ? 'الاسم قصير بزاف' : null,
            ),
            const SizedBox(height: AppSpace.x3),

            AppField(
              label: 'الوصف',
              hint: 'وصف مختصر ومقنع…',
              controller: _desc,
              icon: Icons.notes,
              maxLines: 4,
            ),
            const SizedBox(height: AppSpace.x3),

            // ---------- الصنف ----------
            Text('الصنف', style: AppText.label),
            const SizedBox(height: AppSpace.x2),
            cats.when(
              loading: () => const LinearProgressIndicator(),
              error: (_, __) => const SizedBox.shrink(),
              data: (list) => DropdownButtonFormField<String>(
                initialValue: _categoryId,
                decoration: const InputDecoration(hintText: 'بلا صنف'),
                items: list
                    .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name)))
                    .toList(),
                onChanged: (v) => setState(() => _categoryId = v),
              ),
            ),
            const SizedBox(height: AppSpace.x3),

            // ---------- الأسعار ----------
            Row(
              children: [
                Expanded(
                  child: AppField(
                    label: 'السعر (دج) *',
                    hint: '2500',
                    controller: _price,
                    keyboard: TextInputType.number,
                    icon: Icons.payments_outlined,
                    validator: (v) =>
                        (int.tryParse(v ?? '') ?? 0) <= 0 ? 'السعر مطلوب' : null,
                  ),
                ),
                const SizedBox(width: AppSpace.x3),
                Expanded(
                  child: AppField(
                    label: 'السعر قبل التخفيض',
                    hint: '3500',
                    controller: _compare,
                    keyboard: TextInputType.number,
                    icon: Icons.local_offer_outlined,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpace.x3),

            Row(
              children: [
                Expanded(
                  child: AppField(
                    label: 'المخزون *',
                    hint: '10',
                    controller: _stock,
                    keyboard: TextInputType.number,
                    icon: Icons.inventory_2_outlined,
                  ),
                ),
                const SizedBox(width: AppSpace.x3),
                Expanded(
                  child: AppField(
                    label: 'الشارة (اختياري)',
                    hint: 'جديد / تخفيض',
                    controller: _badge,
                    icon: Icons.label_outline,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpace.x3),

            // ---------- المتغيّرات ----------
            Row(
              children: [
                Text('المتغيّرات (لون، مقاس…)', style: AppText.label),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => setState(() => _variantSchema.add(('', []))),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('زيد'),
                ),
              ],
            ),
            ..._variantSchema.asMap().entries.map((e) {
              final i = e.key;
              final (name, options) = e.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpace.x3),
                child: _VariantEditor(
                  name: name,
                  options: options,
                  onChanged: (n, o) => setState(() => _variantSchema[i] = (n, o)),
                  onDelete: () => setState(() => _variantSchema.removeAt(i)),
                ),
              );
            }),

            const SizedBox(height: AppSpace.x3),
            SwitchListTile(
              value: _featured,
              onChanged: (v) => setState(() => _featured = v),
              title: Text('مختار ليك (يتصدر الصفحة)', style: AppText.bodySm),
              activeThumbColor: AppColors.green700,
              contentPadding: EdgeInsets.zero,
            ),
            SwitchListTile(
              value: _active,
              onChanged: (v) => setState(() => _active = v),
              title: Text('ظاهر فالواجهة', style: AppText.bodySm),
              activeThumbColor: AppColors.green700,
              contentPadding: EdgeInsets.zero,
            ),

            const SizedBox(height: AppSpace.x6),
            AppButton(
              label: isEdit ? 'حفظ التعديلات' : 'زيد المنتج',
              icon: Icons.check,
              loading: _loading,
              onPressed: _save,
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}

class _VariantEditor extends StatefulWidget {
  final String name;
  final List<String> options;
  final void Function(String name, List<String> options) onChanged;
  final VoidCallback onDelete;

  const _VariantEditor({
    required this.name, required this.options,
    required this.onChanged, required this.onDelete,
  });

  @override
  State<_VariantEditor> createState() => _VariantEditorState();
}

class _VariantEditorState extends State<_VariantEditor> {
  late final TextEditingController _name;
  late final TextEditingController _opts;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.name);
    _opts = TextEditingController(text: widget.options.join('، '));
    _name.addListener(_emit);
    _opts.addListener(_emit);
  }

  void _emit() {
    final list = _opts.text
        .split(RegExp(r'[،,|\n]'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    widget.onChanged(_name.text, list);
  }

  @override
  void dispose() {
    _name.dispose();
    _opts.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpace.x3),
      decoration: BoxDecoration(
        color: AppColors.green50,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _name,
                  style: AppText.bodySm,
                  decoration: const InputDecoration(
                    hintText: 'الاسم: اللون',
                    filled: true, fillColor: Colors.white,
                  ),
                ),
              ),
              IconButton(
                onPressed: widget.onDelete,
                icon: const Icon(Icons.close, size: 18, color: AppColors.danger),
              ),
            ],
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _opts,
            style: AppText.bodySm,
            decoration: const InputDecoration(
              hintText: 'القيم: أحمر، أزرق، أخضر',
              filled: true, fillColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
