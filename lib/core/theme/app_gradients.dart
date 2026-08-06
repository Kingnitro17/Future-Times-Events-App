import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Brand gradients extracted from --grad-* CSS variables.
class AppGradients {
  AppGradients._();

  /// Pink → Violet — primary CTA, featured events, hero sections.
  static const LinearGradient primary = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.pink, AppColors.violet],
  );

  /// Cyan → Purple — ocean/secondary gradient.
  static const LinearGradient ocean = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.cyan, AppColors.purple],
  );

  /// Mint → Grape — emerald gradient (check-in progress, success).
  static const LinearGradient emerald = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.mint, AppColors.grape],
  );

  /// Orange → Magenta — fire gradient (trending, hot events).
  static const LinearGradient fire = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.orange, AppColors.magenta],
  );

  /// Blue → Lime — electric gradient.
  static const LinearGradient electric = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.blue, AppColors.lime],
  );

  /// Fuchsia → Sky — cosmic gradient.
  static const LinearGradient cosmic = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.fuchsia, AppColors.sky],
  );

  /// Dark overlay for hero images (bottom-heavy).
  static const LinearGradient heroDark = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0x4D0A0A0F), Color(0xE60A0A0F)],
  );

  /// Light fade for image to white (used in light cards).
  static const LinearGradient heroLight = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0x1AFFFFFF), Color(0xF2FFFFFF)],
  );

  /// Shimmer animation gradient — use with AnimationController.
  static LinearGradient shimmer({double position = -1.0}) => LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: const [
      Color(0x00FFFFFF),
      Color(0x24FFFFFF),
      Color(0x00FFFFFF),
    ],
    stops: [
      position.clamp(0.0, 1.0),
      (position + 0.3).clamp(0.0, 1.0),
      (position + 0.6).clamp(0.0, 1.0),
    ],
  );

  /// Returns a gradient by category slug.
  static LinearGradient forCategory(String category) {
    return switch (category.toLowerCase()) {
      'music' => primary,
      'arts' => ocean,
      'food' => fire,
      'sports' => emerald,
      'tech' => electric,
      'comedy' => cosmic,
      'fashion' => primary,
      _ => ocean,
    };
  }
}
