/// ============================================================
/// إعدادات الاتصال بـSupabase
/// ============================================================
/// خيار 1 (موصى به): مرّرها وقت البناء عبر --dart-define
///   flutter build apk --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
/// خيار 2: بدّلها هنا مباشرة (مناسب للتطوير فقط)
/// ============================================================
class Env {
  static const supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://YOUR_PROJECT_REF.supabase.co',
  );

  static const supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'YOUR_ANON_PUBLIC_KEY',
  );

  /// هل التطبيق مضبوط فعلاً؟
  static bool get isConfigured =>
      !supabaseUrl.contains('YOUR_PROJECT_REF') &&
      !supabaseAnonKey.contains('YOUR_ANON_PUBLIC_KEY');

  /// يقرأ إعدادات وقت التشغيل من ملف اختياري (env.json) — اختياري
  static const appName = 'LATCHI STORE';
  static const appVersion = '1.0.0';

  /// العملة
  static const currency = 'DZD';

  /// رقم واتساب الدعم (بصيغة دولية بلا +)
  static const supportWhatsApp = '213555000000';
}
