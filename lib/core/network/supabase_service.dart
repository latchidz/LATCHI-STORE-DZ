import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/env.dart';

/// ============================================================
/// طبقة الشبكة — المكان الوحيد الذي يلمس Supabase مباشرة
/// ============================================================
class SupabaseService {
  SupabaseService._();
  static final SupabaseService instance = SupabaseService._();

  static bool _ready = false;

  static Future<void> init() async {
    if (_ready) return;
    if (!Env.isConfigured) return; // التطبيق يشتغل في وضع Demo
    await Supabase.initialize(
      url: Env.supabaseUrl,
      // ignore: deprecated_member_use
      anonKey: Env.supabaseAnonKey,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
      ),
      realtimeClientOptions: const RealtimeClientOptions(
        logLevel: RealtimeLogLevel.error,
      ),
    );
    _ready = true;
  }

  bool get isReady => _ready;

  SupabaseClient get client => Supabase.instance.client;
  GoTrueClient get auth => client.auth;
  User? get user => client.auth.currentUser;
  bool get isLoggedIn => user != null;
  Session? get session => client.auth.currentSession;
}

/// استثناء موحّد يترجم أخطاء Supabase إلى رسائل عربية مفهومة
class AppException implements Exception {
  final String message;
  final String? code;
  const AppException(this.message, {this.code});

  factory AppException.from(Object e) {
    final raw = e.toString();
    if (raw.contains('OUT_OF_STOCK')) {
      final t = raw.split('OUT_OF_STOCK:').last.split(RegExp(r'[\n"]')).first;
      return AppException('نفد المخزون: $t', code: 'OUT_OF_STOCK');
    }
    if (raw.contains('EMPTY_CART')) {
      return const AppException('السلة فارغة', code: 'EMPTY_CART');
    }
    if (raw.contains('NOT_OWNER')) {
      return const AppException('ما عندكش صلاحية على هاد المتجر', code: 'NOT_OWNER');
    }
    if (raw.contains('Invalid login credentials')) {
      return const AppException('البريد أو كلمة السر غالطين', code: 'BAD_CREDENTIALS');
    }
    if (raw.contains('User already registered')) {
      return const AppException('هاد البريد مسجّل من قبل', code: 'EXISTS');
    }
    if (raw.contains('Password should be at least')) {
      return const AppException('كلمة السر قصيرة (6 حروف على الأقل)', code: 'WEAK');
    }
    if (raw.contains('SocketException') || raw.contains('Failed host lookup')) {
      return const AppException('ما كاينش اتصال بالإنترنت', code: 'NETWORK');
    }
    return AppException(raw.length > 160 ? '${raw.substring(0, 160)}…' : raw);
  }

  @override
  String toString() => message;
}
