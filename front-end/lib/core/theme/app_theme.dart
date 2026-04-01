import 'package:flutter/material.dart';

class AppColors {
  static const Color primary      = Color(0xFF0A7EA4);
  static const Color primaryLight = Color(0xFF38B2CC);
  static const Color primaryDark  = Color(0xFF065F7E);
  static const Color accent       = Color(0xFF00BFA5);
  static const Color accentLight  = Color(0xFF64DFCF);

  static const Color bgWhite  = Color(0xFFFFFFFF);
  static const Color bgSoft   = Color(0xFFF0F7FA);

  static const Color gradStart = Color(0xFFE8F4FD);
  static const Color gradMid   = Color(0xFFD0EBF7);
  static const Color gradEnd   = Color(0xFFFFFFFF);

  static const Color riskLow    = Color(0xFF4CAF50);
  static const Color riskMedium = Color(0xFFFF9800);
  static const Color riskHigh   = Color(0xFFF44336);

  static const Color textPrimary   = Color(0xFF1A2B3C);
  static const Color textSecondary = Color(0xFF5B7A8E);
  static const Color textHint      = Color(0xFF9DB5C4);
  static const Color textWhite     = Color(0xFFFFFFFF);

  static const Color border       = Color(0xFFDDEEF5);
  static const Color dotActive    = Color(0xFF0A7EA4);
  static const Color dotInactive  = Color(0xFFCCE4EF);
}

class AppFonts {
  static const String family = 'Nunito';

  static const TextStyle displayLarge = TextStyle(
    fontFamily: family, fontSize: 32, fontWeight: FontWeight.w800,
    color: AppColors.textPrimary, height: 1.2, letterSpacing: -0.5,
  );
  static const TextStyle displayMedium = TextStyle(
    fontFamily: family, fontSize: 26, fontWeight: FontWeight.w700,
    color: AppColors.textPrimary, height: 1.25, letterSpacing: -0.3,
  );
  static const TextStyle bodyLarge = TextStyle(
    fontFamily: family, fontSize: 16, fontWeight: FontWeight.w400,
    color: AppColors.textSecondary, height: 1.65,
  );
  static const TextStyle labelBtn = TextStyle(
    fontFamily: family, fontSize: 16, fontWeight: FontWeight.w700,
    color: AppColors.textWhite, letterSpacing: 0.3,
  );
  static const TextStyle appName = TextStyle(
    fontFamily: family, fontSize: 34, fontWeight: FontWeight.w800,
    letterSpacing: -0.5,
  );
  static const TextStyle appSubtitle = TextStyle(
    fontFamily: family, fontSize: 12, fontWeight: FontWeight.w500,
    color: AppColors.textHint, letterSpacing: 2.8,
  );
}

class AppTheme {
  static ThemeData get light => ThemeData(
    fontFamily: AppFonts.family,
    useMaterial3: true,
    scaffoldBackgroundColor: AppColors.bgSoft,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.light,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      iconTheme: IconThemeData(color: AppColors.textPrimary),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textWhite,
        minimumSize: const Size(double.infinity, 56),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 0,
      ),
    ),
  );
}