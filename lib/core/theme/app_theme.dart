import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

class AppTheme {
  AppTheme._();

  static RoundedRectangleBorder _rounded(double r) =>
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(r));

  static ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.violet,
      brightness: Brightness.light,
      primary: AppColors.violet,
      onPrimary: Colors.white,
      secondary: AppColors.pink,
      onSecondary: Colors.white,
      surface: AppColors.background,
      onSurface: AppColors.text,
      error: AppColors.error,
      onError: Colors.white,
    ),
    scaffoldBackgroundColor: AppColors.backgroundSecondary,
    splashFactory: InkRipple.splashFactory,
    textTheme: _buildTextTheme(),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.background,
      foregroundColor: AppColors.text,
      elevation: 0,
      scrolledUnderElevation: 0.5,
      centerTitle: false,
      titleTextStyle: AppTypography.h4.copyWith(color: AppColors.text),
      surfaceTintColor: Colors.transparent,
    ),
    cardTheme: CardTheme(
      color: AppColors.card,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: _rounded(AppRadius.xxl),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.violet,
        foregroundColor: Colors.white,
        minimumSize: const Size(44, 44),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        shape: _rounded(AppRadius.lg),
        textStyle: AppTypography.button,
        elevation: 0,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.text,
        minimumSize: const Size(44, 44),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        shape: _rounded(AppRadius.lg),
        side: const BorderSide(color: AppColors.border, width: 1.5),
        textStyle: AppTypography.button.copyWith(color: AppColors.text),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.violet,
        minimumSize: const Size(44, 44),
        textStyle: AppTypography.bodyMedium.copyWith(color: AppColors.violet),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.backgroundSecondary,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 12,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        borderSide: const BorderSide(color: AppColors.border, width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        borderSide: const BorderSide(color: AppColors.border, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        borderSide: const BorderSide(color: AppColors.violet, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        borderSide: const BorderSide(color: AppColors.error, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        borderSide: const BorderSide(color: AppColors.error, width: 2),
      ),
      hintStyle: AppTypography.body.copyWith(color: AppColors.textMuted),
      labelStyle: AppTypography.caption,
      errorStyle: AppTypography.caption.copyWith(color: AppColors.error),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.backgroundTertiary,
      selectedColor: AppColors.violet.withAlpha(26),
      labelStyle: AppTypography.caption,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      shape: _rounded(AppRadius.full),
      side: BorderSide.none,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.background,
      indicatorColor: AppColors.violet.withAlpha(26),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return AppTypography.navLabel.copyWith(color: AppColors.violet);
        }
        return AppTypography.navLabel.copyWith(color: AppColors.textMuted);
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const IconThemeData(color: AppColors.violet, size: 24);
        }
        return const IconThemeData(color: AppColors.textMuted, size: 24);
      }),
      elevation: 0,
      surfaceTintColor: Colors.transparent,
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: AppColors.background,
      selectedIconTheme: const IconThemeData(color: AppColors.violet),
      unselectedIconTheme: const IconThemeData(color: AppColors.textMuted),
      selectedLabelTextStyle:
          AppTypography.navLabel.copyWith(color: AppColors.violet),
      unselectedLabelTextStyle:
          AppTypography.navLabel.copyWith(color: AppColors.textMuted),
      indicatorColor: AppColors.violet.withAlpha(26),
    ),
    dialogTheme: DialogTheme(
      backgroundColor: AppColors.background,
      shape: _rounded(AppRadius.xxl),
      elevation: 0,
      titleTextStyle: AppTypography.h4,
      contentTextStyle: AppTypography.body,
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.background,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xxl)),
      ),
      elevation: 0,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.text,
      contentTextStyle:
          AppTypography.bodySmall.copyWith(color: AppColors.textOnDark),
      shape: _rounded(AppRadius.lg),
      behavior: SnackBarBehavior.floating,
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.border,
      thickness: 1,
      space: 1,
    ),
    listTileTheme: ListTileThemeData(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      shape: _rounded(AppRadius.lg),
      titleTextStyle: AppTypography.bodyMedium,
      subtitleTextStyle: AppTypography.caption,
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((s) =>
          s.contains(WidgetState.selected) ? AppColors.violet : Colors.white),
      trackColor: WidgetStateProperty.resolveWith((s) =>
          s.contains(WidgetState.selected)
              ? AppColors.violetLight
              : AppColors.border),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: AppColors.violet,
      linearTrackColor: AppColors.backgroundTertiary,
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: AppColors.violet,
      foregroundColor: Colors.white,
      shape: _rounded(AppRadius.xl),
      elevation: 4,
    ),
  );

  static TextTheme _buildTextTheme() => TextTheme(
    displayLarge: AppTypography.h1,
    displayMedium: AppTypography.h1.copyWith(fontSize: 28),
    displaySmall: AppTypography.h2,
    headlineLarge: AppTypography.h2,
    headlineMedium: AppTypography.h3,
    headlineSmall: AppTypography.h4,
    titleLarge: AppTypography.h4,
    titleMedium: AppTypography.bodyMedium,
    titleSmall: AppTypography.bodyMedium.copyWith(fontSize: 14),
    bodyLarge: AppTypography.body,
    bodyMedium: AppTypography.bodySmall,
    bodySmall: AppTypography.caption,
    labelLarge: AppTypography.button,
    labelMedium: AppTypography.buttonSmall,
    labelSmall: AppTypography.overline,
  );
}
