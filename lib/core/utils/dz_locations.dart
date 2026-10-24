import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/models.dart';

/// ============================================================
/// الولايات والبلديات الجزائرية — 69 ولاية / 1541 بلدية
/// المصدر: الجريدة الرسمية — القانون 26-06 (أفريل 2026)
/// الملف: assets/data/algeria.json
/// ============================================================
class DzLocations {
  DzLocations._();
  static final DzLocations instance = DzLocations._();

  List<Wilaya> _wilayas = const [];
  bool _loaded = false;

  List<Wilaya> get wilayas => _wilayas;
  bool get isLoaded => _loaded;

  Future<void> load() async {
    if (_loaded) return;
    final raw = await rootBundle.loadString('assets/data/algeria.json');
    final data = json.decode(raw) as Map<String, dynamic>;
    _wilayas = (data['wilayas'] as List)
        .map((e) => Wilaya.fromMap((e as Map).cast<String, dynamic>()))
        .toList();
    _loaded = true;
  }

  Wilaya? byCode(String? code) {
    if (code == null) return null;
    for (final w in _wilayas) {
      if (w.code == code) return w;
    }
    return null;
  }

  List<Commune> communesOf(String? wilayaCode) => byCode(wilayaCode)?.communes ?? const [];

  /// بحث ذكي: يقبل العربي والفرنسي والأرقام
  List<Wilaya> search(String q) {
    final s = q.trim().toLowerCase();
    if (s.isEmpty) return _wilayas;
    return _wilayas.where((w) =>
        w.ar.contains(q) ||
        w.fr.toLowerCase().contains(s) ||
        w.code.contains(s)).toList();
  }

  List<Commune> searchCommunes(String wilayaCode, String q) {
    final list = communesOf(wilayaCode);
    final s = q.trim().toLowerCase();
    if (s.isEmpty) return list;
    return list.where((c) =>
        c.ar.contains(q) || c.fr.toLowerCase().contains(s)).toList();
  }
}
