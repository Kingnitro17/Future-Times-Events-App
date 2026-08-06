import 'package:flutter/material.dart';

/// All brand colors extracted from the Future Times Events website.
/// Source: app/globals.css and tailwind.config.ts
///
/// NEVER scatter hex values in widgets — use these constants.
class AppColors {
  AppColors._();

  // ── Brand Core ─────────────────────────────────────────────────────────────
  static const Color violet = Color(0xFF7222E3);      // --accent (primary CTA)
  static const Color violetLight = Color(0xFF9B5EFF); // --accent-light
  static const Color pink = Color(0xFFFF55C2);        // brand.pink
  static const Color cyan = Color(0xFF2CC4EA);        // brand.cyan
  static const Color purple = Color(0xFF533885);      // brand.purple
  static const Color orange = Color(0xFFFFBC73);      // brand.orange
  static const Color magenta = Color(0xFFFF00B9);     // brand.magenta
  static const Color mint = Color(0xFF46FFAB);        // brand.mint
  static const Color grape = Color(0xFFA02EFF);       // brand.grape
  static const Color blue = Color(0xFF1D5BFF);        // brand.blue
  static const Color lime = Color(0xFFC7FE17);        // brand.lime
  static const Color fuchsia = Color(0xFFDD1FFF);     // brand.fuchsia
  static const Color sky = Color(0xFF24D8FB);         // brand.sky

  // ── Light Mode Surfaces ────────────────────────────────────────────────────
  static const Color background = Color(0xFFFFFFFF);           // --bg
  static const Color backgroundSecondary = Color(0xFFF7F7FA);  // --bg-secondary
  static const Color backgroundTertiary = Color(0xFFEFEFF5);   // --bg-tertiary
  static const Color card = Color(0xEBFFFFFF);                  // --bg-card (92% white)
  static const Color glass = Color(0xC7FFFFFF);                 // --bg-glass (78% white)

  // ── Text ──────────────────────────────────────────────────────────────────
  static const Color text = Color(0xFF0A0A14);         // --text
  static const Color textSecondary = Color(0xFF38384E); // --text-secondary
  static const Color textMuted = Color(0xFF78788C);    // --text-muted
  static const Color textOnDark = Color(0xFFFFFFFF);

  // ── Borders ────────────────────────────────────────────────────────────────
  static const Color border = Color(0x12000000);                // rgba(0,0,0,0.07)
  static const Color borderHover = Color(0x4D7222E3);           // rgba(114,34,227,0.3)

  // ── Semantic ──────────────────────────────────────────────────────────────
  static const Color success = Color(0xFF22C55E);
  static const Color successBg = Color(0x1F46FFAB);   // rgba(70,255,171,0.12)
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningBg = Color(0x24FFBC73);   // rgba(255,188,115,0.14)
  static const Color error = Color(0xFFEF4444);
  static const Color errorBg = Color(0x1AEF4444);     // rgba(239,68,68,0.10)
  static const Color info = Color(0xFF0EA5E9);
  static const Color infoBg = Color(0x1F2CC4EA);      // rgba(44,196,234,0.12)

  // ── Dark Glass (used on image overlays) ───────────────────────────────────
  static const Color glassDark = Color(0x570A0A12);         // rgba(10,10,18,0.34)
  static const Color glassDarkStrong = Color(0x7A0A0A12);   // rgba(10,10,18,0.48)

  // ── Category Color Map (used for category pills / event cards) ─────────────
  static const Map<String, Color> categoryGradientStart = {
    'music':      pink,
    'arts':       cyan,
    'food':       orange,
    'sports':     mint,
    'tech':       blue,
    'networking': violet,
    'comedy':     lime,
    'fashion':    fuchsia,
    'business':   purple,
    'wellness':   sky,
  };
}
