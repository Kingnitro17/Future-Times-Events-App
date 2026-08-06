/// Spacing tokens — strict 8px grid.
/// Source: --sp-* tokens in globals.css
class AppSpacing {
  AppSpacing._();

  static const double xs  = 4.0;   // --sp-1
  static const double sm  = 8.0;   // --sp-2
  static const double md  = 16.0;  // --sp-3
  static const double lg  = 24.0;  // --sp-4
  static const double xl  = 32.0;  // --sp-5
  static const double xxl = 48.0;  // --sp-6
  static const double xxxl = 64.0; // --sp-7
  static const double huge = 96.0; // --sp-8

  /// Standard horizontal page padding.
  static const double pagePadding = md; // 16px

  /// Card inner padding (matches .card-pad).
  static const double cardPadding = lg; // 24px

  /// Bottom nav bar height (matches pb-nav calculation).
  static const double bottomNavHeight = 64.0;

  /// Minimum touch target per Material / HIG.
  static const double minTouchTarget = 44.0;
}

/// Border radius tokens.
/// Source: --r-* tokens in globals.css
class AppRadius {
  AppRadius._();

  static const double xs   = 6.0;     // --r-xs
  static const double sm   = 8.0;     // --r-sm
  static const double md   = 12.0;    // --r-md
  static const double lg   = 16.0;    // --r-lg
  static const double xl   = 20.0;    // --r-xl
  static const double xxl  = 24.0;    // --r-2xl
  static const double xxxl = 32.0;    // --r-3xl
  static const double full = 9999.0;  // --r-full (pill)
}

/// Shadow / elevation helpers.
/// Source: --shadow-* tokens in globals.css
class AppElevation {
  AppElevation._();

  // Material elevation values (approximate mapping)
  static const double none = 0;
  static const double card = 1;
  static const double raised = 2;
  static const double modal = 4;
  static const double dialog = 8;
}
