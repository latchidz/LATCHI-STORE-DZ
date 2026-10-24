import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// ============================================================
/// LATCHI STORE DZ — Design System
/// هوية بصرية واحدة: أخضر جزائري غامق + ذهبي + محايدات نظيفة
/// كل الألوان والمسافات والخطوط تُستهلك من هنا فقط.
/// ============================================================

class AppColors {
  // Brand
  static const green900 = Color(0xFF062D1E);
  static const green800 = Color(0xFF08432C);
  static const green700 = Color(0xFF0A6942);
  static const green600 = Color(0xFF0F7B4F);
  static const green500 = Color(0xFF16915F);
  static const green100 = Color(0xFFDCF3E8);
  static const green50 = Color(0xFFF1FAF5);

  static const gold600 = Color(0xFFB8860B);
  static const gold500 = Color(0xFFD8A31A);
  static const gold100 = Color(0xFFFDF3D4);

  // Neutral
  static const ink = Color(0xFF101614);
  static const ink70 = Color(0xFF4A5551);
  static const ink50 = Color(0xFF7B8783);
  static const ink30 = Color(0xFFB4BDBA);
  static const line = Color(0xFFE3E8E6);
  static const surface = Color(0xFFFFFFFF);
  static const canvas = Color(0xFFF7F9F8);

  // Semantic
  static const success = Color(0xFF12925B);
  static const warning = Color(0xFFE09A1A);
  static const danger = Color(0xFFD33B3B);
  static const info = Color(0xFF2C7BE5);
  static const purple = Color(0xFF7B4FD8);

  // Order status
  static const stNew = Color(0xFF2C7BE5);
  static const stConfirmed = Color(0xFF12925B);
  static const stCanceled = Color(0xFFD33B3B);
  static const stPostponed = Color(0xFFE09A1A);
  static const stInDelivery = Color(0xFF7B4FD8);
  static const stDelivered = Color(0xFF0A6942);
}

class AppRadius {
  static const xs = 8.0;
  static const sm = 12.0;
  static const md = 16.0;
  static const lg = 20.0;
  static const xl = 28.0;
  static const pill = 999.0;
}

class AppSpace {
  static const x1 = 4.0;
  static const x2 = 8.0;
  static const x3 = 12.0;
  static const x4 = 16.0;
  static const x5 = 20.0;
  static const x6 = 24.0;
  static const x8 = 32.0;
  static const x10 = 40.0;
}

class AppShadows {
  static const soft = [
    BoxShadow(color: Color(0x0A000000), blurRadius: 12, offset: Offset(0, 4)),
  ];
  static const card = [
    BoxShadow(color: Color(0x0F000000), blurRadius: 20, offset: Offset(0, 6)),
  ];
  static const float = [
    BoxShadow(color: Color(0x1F0A6942), blurRadius: 28, offset: Offset(0, 10)),
  ];
}

/// أنماط النص — Tajawal مضمّن في assets
class AppText {
  static const family = 'Tajawal';

  static const display = TextStyle(
      fontFamily: family, fontSize: 30, fontWeight: FontWeight.w900,
      height: 1.25, color: AppColors.ink);
  static const h1 = TextStyle(
      fontFamily: family, fontSize: 24, fontWeight: FontWeight.w800,
      height: 1.3, color: AppColors.ink);
  static const h2 = TextStyle(
      fontFamily: family, fontSize: 20, fontWeight: FontWeight.w700,
      height: 1.35, color: AppColors.ink);
  static const h3 = TextStyle(
      fontFamily: family, fontSize: 17, fontWeight: FontWeight.w700,
      height: 1.4, color: AppColors.ink);
  static const body = TextStyle(
      fontFamily: family, fontSize: 15, fontWeight: FontWeight.w400,
      height: 1.6, color: AppColors.ink);
  static const bodySm = TextStyle(
      fontFamily: family, fontSize: 13.5, fontWeight: FontWeight.w400,
      height: 1.55, color: AppColors.ink70);
  static const label = TextStyle(
      fontFamily: family, fontSize: 13.5, fontWeight: FontWeight.w700,
      height: 1.3, color: AppColors.ink);
  static const caption = TextStyle(
      fontFamily: family, fontSize: 12, fontWeight: FontWeight.w500,
      height: 1.4, color: AppColors.ink50);
  static const price = TextStyle(
      fontFamily: family, fontSize: 19, fontWeight: FontWeight.w900,
      height: 1.2, color: AppColors.green700);
  static const button = TextStyle(
      fontFamily: family, fontSize: 16, fontWeight: FontWeight.w800,
      height: 1.2, letterSpacing: 0.1);
}

class AppTheme {
  static ThemeData light() {
    final base = ThemeData.light(useMaterial3: true);
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.green700,
      brightness: Brightness.light,
    ).copyWith(
      primary: AppColors.green700,
      onPrimary: Colors.white,
      secondary: AppColors.gold500,
      onSecondary: AppColors.ink,
      surface: AppColors.surface,
      onSurface: AppColors.ink,
      error: AppColors.danger,
      outline: AppColors.line,
      surfaceContainerLowest: AppColors.surface,
      surfaceContainerLow: AppColors.canvas,
    );

    return base.copyWith(
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.canvas,
      textTheme: const TextTheme(
        displayLarge: AppText.display,
        displayMedium: AppText.h1,
        headlineMedium: AppText.h2,
        headlineSmall: AppText.h3,
        titleMedium: AppText.label,
        bodyLarge: AppText.body,
        bodyMedium: AppText.bodySm,
        bodySmall: AppText.caption,
        labelLarge: AppText.button,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.ink,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: false,
        titleTextStyle: AppText.h2,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          side: const BorderSide(color: AppColors.line),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.line, thickness: 1, space: 1),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.green50,
        selectedColor: AppColors.green700,
        labelStyle: AppText.bodySm,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.pill)),
        side: BorderSide.none,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpace.x4, vertical: AppSpace.x4),
        hintStyle: AppText.bodySm.copyWith(color: AppColors.ink30),
        labelStyle: AppText.bodySm,
        floatingLabelStyle: AppText.label,
        prefixIconColor: AppColors.ink50,
        suffixIconColor: AppColors.ink50,
        border: _border(AppColors.line),
        enabledBorder: _border(AppColors.line),
        focusedBorder: _border(AppColors.green700, 1.6),
        errorBorder: _border(AppColors.danger),
        focusedErrorBorder: _border(AppColors.danger, 1.6),
        errorStyle: AppText.caption.copyWith(color: AppColors.danger),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.green700,
          foregroundColor: Colors.white,
          minimumSize: const Size(0, 54),
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.x6),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.sm)),
          textStyle: AppText.button,
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.green700,
          minimumSize: const Size(0, 54),
          side: const BorderSide(color: AppColors.green700, width: 1.4),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.sm)),
          textStyle: AppText.button,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.green700,
          textStyle: AppText.label,
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg)),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.ink,
        contentTextStyle: AppText.body.copyWith(color: Colors.white),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm)),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(builders: {
        TargetPlatform.android: ZoomPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      }),
    );
  }

  static OutlineInputBorder _border(Color c, [double w = 1]) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        borderSide: BorderSide(color: c, width: w),
      );
}

/// تنسيق العملة الجزائرية
class Money {
  static String dz(num v) {
    final n = v.round();
    final s = n.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return '${s.startsWith('-') ? '-' : ''}${buf.toString().replaceFirst('-', '')} دج';
  }

  static String plain(num v) => v.round().toString();
}
