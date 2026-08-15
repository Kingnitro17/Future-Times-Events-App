import 'package:flutter/material.dart';
import 'app_colors.dart';

abstract final class AppTheme {
  static const electricIndigo = AppColors.purple;
  static const indigoLight = AppColors.purpleLight;
  static const indigoDark = Color(0xFF5214AE);
  static const charcoal = AppColors.background;
  static const charcoalSurface = AppColors.surface;
  static const charcoalCard = AppColors.surface;
  static const charcoalBorder = AppColors.border;
  static const pureWhite = Colors.white;
  static const offWhite = AppColors.text;
  static const subtleGrey = AppColors.textMuted;
  static const successGreen = AppColors.success;
  static const errorRed = AppColors.error;
  static final radiusLarge = BorderRadius.circular(24);
  static final radiusMedium = BorderRadius.circular(16);
  static final radiusSmall = BorderRadius.circular(10);
  static final radiusPill = BorderRadius.circular(999);
  static const indigoGradient = LinearGradient(
      colors: [AppColors.pink, AppColors.purple],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight);
  static const heroGradient = LinearGradient(
      colors: [Colors.transparent, Color(0xB3000000)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter);
  static List<BoxShadow> get softShadow => const [
        BoxShadow(
            color: Color(0x140A0A14), blurRadius: 20, offset: Offset(0, 8))
      ];
  static List<BoxShadow> get indigoGlow => const [
        BoxShadow(
            color: Color(0x337222E3), blurRadius: 20, offset: Offset(0, 6))
      ];

  static ThemeData get lightTheme {
    final scheme = ColorScheme.fromSeed(
        seedColor: AppColors.purple,
        brightness: Brightness.light,
        primary: AppColors.purple,
        secondary: AppColors.pink,
        surface: AppColors.surface,
        error: AppColors.error);
    final base = ThemeData(useMaterial3: true, colorScheme: scheme);
    return base.copyWith(
      scaffoldBackgroundColor: AppColors.background,
      textTheme: base.textTheme
          .apply(
              bodyColor: AppColors.textSecondary, displayColor: AppColors.text)
          .copyWith(
            headlineLarge: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: AppColors.text,
                letterSpacing: -1),
            headlineMedium: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: AppColors.text,
                letterSpacing: -.7),
            headlineSmall: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.text),
            titleLarge: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.text),
            titleMedium: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.text),
            bodyLarge: const TextStyle(
                fontSize: 16, height: 1.5, color: AppColors.textSecondary),
            bodyMedium: const TextStyle(
                fontSize: 14, height: 1.45, color: AppColors.textSecondary),
          ),
      appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.background,
          foregroundColor: AppColors.text,
          elevation: 0,
          scrolledUnderElevation: 0),
      cardTheme: CardThemeData(
          color: AppColors.surface,
          elevation: 0,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: const BorderSide(color: AppColors.border))),
      filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
              minimumSize: const Size(48, 54),
              backgroundColor: AppColors.purple,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              textStyle:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.w700))),
      outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
              minimumSize: const Size(48, 54),
              foregroundColor: AppColors.purple,
              side: const BorderSide(color: AppColors.purple),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)))),
      inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.surface,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.border)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.border)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.purple, width: 2))),
      navigationBarTheme: NavigationBarThemeData(
          backgroundColor: AppColors.surface,
          indicatorColor: AppColors.purple.withValues(alpha: .12),
          elevation: 0),
      dividerTheme: const DividerThemeData(color: AppColors.border),
    );
  }

  static ThemeData get darkTheme => lightTheme;
}
