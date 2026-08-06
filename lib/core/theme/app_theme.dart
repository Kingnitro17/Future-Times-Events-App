import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// EventDistro Design System
/// Palette: Deep Charcoal (#121212) · White · Electric Indigo (#6610F2)
abstract class AppTheme {
  // ─── Color Tokens ────────────────────────────────────────────────────────
  static const Color electricIndigo = Color(0xFF6610F2);
  static const Color indigoLight = Color(0xFF9B59F5);
  static const Color indigoDark = Color(0xFF4A0DB3);

  static const Color charcoal = Color(0xFF121212);
  static const Color charcoalSurface = Color(0xFF1E1E2E);
  static const Color charcoalCard = Color(0xFF252538);
  static const Color charcoalBorder = Color(0xFF2E2E45);

  static const Color pureWhite = Color(0xFFFFFFFF);
  static const Color offWhite = Color(0xFFF0F0F5);
  static const Color subtleGrey = Color(0xFF8A8AA3);

  static const Color successGreen = Color(0xFF00C896);
  static const Color errorRed = Color(0xFFFF4566);

  // ─── Gradients ────────────────────────────────────────────────────────────
  static const LinearGradient indigoGradient = LinearGradient(
    colors: [electricIndigo, indigoDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient heroGradient = LinearGradient(
    colors: [Colors.transparent, Color(0xCC121212)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // ─── Border Radius ────────────────────────────────────────────────────────
  static final BorderRadius radiusLarge = BorderRadius.circular(24);
  static final BorderRadius radiusMedium = BorderRadius.circular(16);
  static final BorderRadius radiusSmall = BorderRadius.circular(10);
  static final BorderRadius radiusPill = BorderRadius.circular(999);

  // ─── Shadows ─────────────────────────────────────────────────────────────
  static List<BoxShadow> get softShadow => [
        BoxShadow(
          color: Colors.black.withOpacity(0.35),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ];

  static List<BoxShadow> get indigoGlow => [
        BoxShadow(
          color: electricIndigo.withOpacity(0.4),
          blurRadius: 24,
          offset: const Offset(0, 6),
        ),
      ];

  // ─── Material 3 Dark Theme ────────────────────────────────────────────────
  static ThemeData get darkTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: electricIndigo,
      brightness: Brightness.dark,
      surface: charcoalSurface,
      primary: electricIndigo,
      onPrimary: pureWhite,
      secondary: indigoLight,
      onSecondary: pureWhite,
      error: errorRed,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: charcoal,
      fontFamily: 'Inter',

      // AppBar
      appBarTheme: const AppBarTheme(
        backgroundColor: charcoal,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: TextStyle(
          color: pureWhite,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
        iconTheme: IconThemeData(color: pureWhite),
      ),

      // Cards
      cardTheme: CardThemeData(
        color: charcoalCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: radiusLarge,
          side: const BorderSide(color: charcoalBorder, width: 1),
        ),
      ),

      // Buttons
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: electricIndigo,
          foregroundColor: pureWhite,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(borderRadius: radiusMedium),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: electricIndigo,
          side: const BorderSide(color: electricIndigo),
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(borderRadius: radiusMedium),
        ),
      ),

      // Chips
      chipTheme: ChipThemeData(
        backgroundColor: charcoalCard,
        selectedColor: electricIndigo,
        labelStyle: const TextStyle(color: offWhite, fontSize: 13),
        side: const BorderSide(color: charcoalBorder),
        shape: RoundedRectangleBorder(borderRadius: radiusPill),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),

      // Input
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: charcoalSurface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: radiusMedium,
          borderSide: const BorderSide(color: charcoalBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: radiusMedium,
          borderSide: const BorderSide(color: charcoalBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: radiusMedium,
          borderSide: const BorderSide(color: electricIndigo, width: 2),
        ),
        hintStyle: const TextStyle(color: subtleGrey),
      ),

      // Navigation Drawer
      navigationDrawerTheme: NavigationDrawerThemeData(
        backgroundColor: charcoalSurface,
        indicatorColor: electricIndigo.withOpacity(0.2),
        labelTextStyle: WidgetStateProperty.all(
          const TextStyle(color: offWhite, fontSize: 14),
        ),
      ),

      // Divider
      dividerTheme: const DividerThemeData(
        color: charcoalBorder,
        thickness: 1,
        space: 1,
      ),

      // Bottom Sheet
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: charcoalSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),

      // Text
      textTheme: _buildTextTheme(),
    );
  }

  // ─── Cupertino Theme ─────────────────────────────────────────────────────
  static CupertinoThemeData get cupertinoTheme => const CupertinoThemeData(
        brightness: Brightness.dark,
        primaryColor: electricIndigo,
        barBackgroundColor: charcoal,
        scaffoldBackgroundColor: charcoal,
        textTheme: CupertinoTextThemeData(
          primaryColor: pureWhite,
          textStyle: TextStyle(
            color: pureWhite,
            fontFamily: 'Inter',
            fontSize: 16,
          ),
          navLargeTitleTextStyle: TextStyle(
            color: pureWhite,
            fontFamily: 'Inter',
            fontSize: 34,
            fontWeight: FontWeight.w700,
            letterSpacing: -1,
          ),
          navTitleTextStyle: TextStyle(
            color: pureWhite,
            fontFamily: 'Inter',
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
      );

  // ─── Text Theme ──────────────────────────────────────────────────────────
  static TextTheme _buildTextTheme() => const TextTheme(
        displayLarge: TextStyle(
          color: pureWhite,
          fontSize: 57,
          fontWeight: FontWeight.w700,
          letterSpacing: -2,
        ),
        displayMedium: TextStyle(
          color: pureWhite,
          fontSize: 45,
          fontWeight: FontWeight.w700,
          letterSpacing: -1.5,
        ),
        headlineLarge: TextStyle(
          color: pureWhite,
          fontSize: 32,
          fontWeight: FontWeight.w700,
          letterSpacing: -1,
        ),
        headlineMedium: TextStyle(
          color: pureWhite,
          fontSize: 28,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.5,
        ),
        headlineSmall: TextStyle(
          color: pureWhite,
          fontSize: 22,
          fontWeight: FontWeight.w600,
        ),
        titleLarge: TextStyle(
          color: pureWhite,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.3,
        ),
        titleMedium: TextStyle(
          color: pureWhite,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        titleSmall: TextStyle(
          color: offWhite,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        bodyLarge: TextStyle(
          color: offWhite,
          fontSize: 16,
          fontWeight: FontWeight.w400,
          height: 1.6,
        ),
        bodyMedium: TextStyle(
          color: subtleGrey,
          fontSize: 14,
          fontWeight: FontWeight.w400,
          height: 1.5,
        ),
        labelLarge: TextStyle(
          color: pureWhite,
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
        labelSmall: TextStyle(
          color: subtleGrey,
          fontSize: 11,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.5,
        ),
      );
}
