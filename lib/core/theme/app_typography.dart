import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Typography scale extracted from the Future Times Events design brief.
///
/// Font families:
///   - Display (H1): Space Grotesk 700
///   - Sub-heading (H2, H3): Raleway 600
///   - Body / UI: Inter 400–600
class AppTypography {
  AppTypography._();

  // ── Letter Spacing (matching CSS ls-* tokens) ──────────────────────────────
  static const double lsHeading = -0.01;   // --ls-heading
  static const double lsSub = -0.005;      // --ls-sub
  static const double lsButton = 0.02;     // --ls-btn
  static const double lsOverline = 0.12;   // --ls-overline

  // ── Line Heights ──────────────────────────────────────────────────────────
  static const double lhBody = 1.5;
  static const double lhHeading = 1.15;
  static const double lhSub = 1.25;

  // ─────────────────────────────────────────────────────────────────────────
  // TEXT STYLES
  // ─────────────────────────────────────────────────────────────────────────

  /// H1 — Space Grotesk 700 — 32px mobile (website: clamp 32–45px)
  static TextStyle get h1 => GoogleFonts.spaceGrotesk(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    letterSpacing: lsHeading * 32,
    height: lhHeading,
    color: AppColors.text,
  );

  /// H2 — Raleway 600 — 22px mobile (website: clamp 22–28px)
  static TextStyle get h2 => GoogleFonts.raleway(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    letterSpacing: lsSub * 22,
    height: lhSub,
    color: AppColors.text,
  );

  /// H3 — Raleway 600 — 20px mobile (website: clamp 20–24px)
  static TextStyle get h3 => GoogleFonts.raleway(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    letterSpacing: lsSub * 20,
    height: lhSub,
    color: AppColors.text,
  );

  /// H4 — Inter 600 — 16px
  static TextStyle get h4 => GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.3,
    color: AppColors.text,
  );

  /// H5 — Inter 500 — 14px
  static TextStyle get h5 => GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.4,
    color: AppColors.text,
  );

  /// Body — Inter 400 — 16px (website: clamp 16–17px)
  static TextStyle get body => GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: lhBody,
    color: AppColors.textSecondary,
  );

  /// Body Medium — Inter 500 — 16px
  static TextStyle get bodyMedium => GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    height: lhBody,
    color: AppColors.text,
  );

  /// Body Small — Inter 400 — 14px
  static TextStyle get bodySmall => GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: lhBody,
    color: AppColors.textSecondary,
  );

  /// Caption — Inter 500 — 14px (website: clamp 14–16px)
  static TextStyle get caption => GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.5,
    letterSpacing: 0.01 * 14,
    color: AppColors.textMuted,
  );

  /// Overline — Inter 700 — 11px uppercase
  static TextStyle get overline => GoogleFonts.inter(
    fontSize: 11,
    fontWeight: FontWeight.w700,
    letterSpacing: lsOverline * 11,
    height: 1.4,
    color: AppColors.textMuted,
  );

  /// Button label — Inter 600 — 16px
  static TextStyle get button => GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: lsButton * 16,
    height: 1,
    color: AppColors.textOnDark,
  );

  /// Button label small — Inter 600 — 13px
  static TextStyle get buttonSmall => GoogleFonts.inter(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    letterSpacing: lsButton * 13,
    height: 1,
    color: AppColors.textOnDark,
  );

  /// Mono — for ticket numbers, QR descriptions
  static TextStyle get mono => const TextStyle(
    fontFamily: 'monospace',
    fontSize: 13,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.02,
    color: AppColors.textMuted,
  );

  /// Price display — Space Grotesk 700 — 24px
  static TextStyle get price => GoogleFonts.spaceGrotesk(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: AppColors.text,
  );

  /// Navigation label — Inter 600 — 12px
  static TextStyle get navLabel => GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.01,
    height: 1.2,
  );

  // ── Gradient text helper ───────────────────────────────────────────────────
  // Use with ShaderMask to apply gradient to text. See FtGradientText widget.
}
