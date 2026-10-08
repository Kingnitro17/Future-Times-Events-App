import 'package:flutter/material.dart';

abstract final class AppColors {
  static const purple = Color(0xFF7222E3);
  static const purpleLight = Color(0xFF9B5EFF);
  static const pink = Color(0xFFFF55C2);
  static const background = Color(0xFFF7F7FA);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceMuted = Color(0xFFEFEFF5);
  static const text = Color(0xFF0A0A14);
  static const textSecondary = Color(0xFF38384E);
  static const textMuted = Color(0xFF78788C);
  static const border = Color(0x14000000);
  static const success = Color(0xFF087F5B);
  static const error = Color(0xFFB42318);

  // Glass surfaces — dark-mode optimized
  static const Color glassSurface = Color(0x1FFFFFFF); // 12% white
  static const Color glassSurfaceHi = Color(0x33FFFFFF); // 20% white
  static const Color glassBorder = Color(0x26FFFFFF); // 15% white
  static const Color glassShadow = Color(0x66000000); // 40% black
  static const Color glassBackdrop = Color(0xCC0A0A14); // near-black

  // Dark theme surfaces
  static const Color bgDark = Color(0xFF0A0A14);
  static const Color bgDarkElevated = Color(0xFF14141F);
  static const Color bgDarkCard = Color(0xFF1A1A28);
  static const Color textOnDark = Color(0xFFF4F4F8);
  static const Color textOnDarkMuted = Color(0xFF9CA3AF);

  // Category colors — used by map pins, chips, and cards.
  static const categoryMusic = Color(0xFF8B5CF6);
  static const categorySports = Color(0xFF10B981);
  static const categoryFood = Color(0xFFF59E0B);
  static const categoryNightlife = Color(0xFF3B82F6);
  static const categoryExpos = Color(0xFFEF4444);
  static const categoryArts = Color(0xFFEC4899);
  static const categoryBusiness = Color(0xFF0EA5E9);
  static const categoryOther = Color(0xFF64748B);

  // Glassmorphism surfaces.
  static const glassLight = Color(0x33FFFFFF);
  static const glassMedium = Color(0x4DFFFFFF);
  static const glassDark = Color(0x33000000);
  static const glassBorderLegacy = Color(0x1FFFFFFF);
}
