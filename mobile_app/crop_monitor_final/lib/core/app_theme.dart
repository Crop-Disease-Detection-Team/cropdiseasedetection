import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Colors copied 1:1 from statics/css/style.css (:root variables)
/// so the Flutter app looks like the web app.
class AppColors {
  AppColors._();

  static const green900 = Color(0xFF1A2E1F);
  static const green800 = Color(0xFF22381F);
  static const green700 = Color(0xFF2C5F2D); // primary
  static const green600 = Color(0xFF3A7D3A);
  static const green400 = Color(0xFF7DAF5B);
  static const green100 = Color(0xFFE6F3E8);
  static const green50 = Color(0xFFF0FAF0);

  static const amber500 = Color(0xFFD97706);
  static const red600 = Color(0xFFDC2626);
  static const red100 = Color(0xFFFEE2E2);

  static const gray900 = Color(0xFF111827);
  static const gray700 = Color(0xFF374151);
  static const gray500 = Color(0xFF6B7280);
  static const gray300 = Color(0xFFD1D5DB);
  static const gray100 = Color(0xFFF3F4F6);
  static const gray50 = Color(0xFFF9FAFB);

  static const white = Color(0xFFFFFFFF);

  // Severity colors reused across predict result / history / disease detail
  static Color severityColor(String? severity) {
    switch ((severity ?? '').toLowerCase()) {
      case 'low':
        return green600;
      case 'medium':
        return amber500;
      case 'high':
      case 'critical':
        return red600;
      default:
        return gray500;
    }
  }
}

class AppRadius {
  AppRadius._();
  static const sm = 8.0;
  static const md = 14.0;
  static const lg = 20.0;
  static const xl = 28.0;
  static const full = 999.0;
}

class AppTheme {
  AppTheme._();

  static ThemeData get light {
    final base = ThemeData.light(useMaterial3: true);
    final textTheme = GoogleFonts.interTextTheme(base.textTheme).apply(
      bodyColor: AppColors.gray900,
      displayColor: AppColors.gray900,
    );

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.gray50,
      textTheme: textTheme,
      colorScheme: base.colorScheme.copyWith(
        primary: AppColors.green700,
        secondary: AppColors.amber500,
        error: AppColors.red600,
        surface: AppColors.white,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.gray900,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.inter(
          color: AppColors.gray900,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.green700,
          foregroundColor: AppColors.white,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.green700,
          minimumSize: const Size.fromHeight(52),
          side: const BorderSide(color: AppColors.green700, width: 1.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.green700,
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.gray50,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.gray300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.gray300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.green700, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.red600),
        ),
        labelStyle: const TextStyle(color: AppColors.gray500),
      ),
      cardTheme: CardThemeData(
        color: AppColors.white,
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.gray900,
        contentTextStyle: const TextStyle(color: AppColors.white),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
      ),
    );
  }
}
