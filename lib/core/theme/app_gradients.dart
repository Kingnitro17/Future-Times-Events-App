import 'package:flutter/material.dart';
import 'app_colors.dart';

abstract final class AppGradients {
  static const brand = LinearGradient(
    colors: [AppColors.pink, AppColors.purple],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const purpleHaze = LinearGradient(
    colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const brandGlow = LinearGradient(
    colors: [Color(0xFF7C3AED), Color(0xFFEC4899), Color(0xFFF59E0B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const darkSurface = LinearGradient(
    colors: [Color(0xFF1E1B4B), Color(0xFF312E81)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
