// ignore_for_file: constant_identifier_names

/// Central location for all app-wide constants.
/// Replace placeholder values before running the app.
class AppConstants {
  AppConstants._();

  // ─── Eventbrite ───────────────────────────────────────────────────────────
  static const String kEventbriteBaseUrl =
      'https://www.eventbriteapi.com/v3/';

  /// Replace with your OAuth2 private token from https://www.eventbrite.com/platform/api-keys
  static const String kEventbriteToken = 'YOUR_EVENTBRITE_TOKEN';

  // ─── Stripe ───────────────────────────────────────────────────────────────
  /// Replace with your Stripe publishable key from https://dashboard.stripe.com/apikeys
  static const String kStripePublishableKey = 'YOUR_STRIPE_PUBLISHABLE_KEY';

  // ─── Eventbrite Category IDs ──────────────────────────────────────────────
  static const Map<String, String> kCategories = {
    'All':          '',
    'Music':        '103',
    'Food & Drink': '110',
    'Arts':         '105',
    'Film & Media': '104',
    'Sports':       '108',
    'Technology':   '102',
    'Family':       '115',
    'Health':       '107',
    'Business':     '101',
    'Travel':       '109',
    'Charity':      '111',
  };

  // ─── Pagination ───────────────────────────────────────────────────────────
  static const int kDefaultPageSize = 20;

  // ─── Firestore ────────────────────────────────────────────────────────────
  static const String kAttendeesCollection = 'attendees';
  static const String kUsersCollection     = 'users';

  // ─── UI ───────────────────────────────────────────────────────────────────
  static const double kBorderRadius   = 24.0;
  static const double kCardElevation  = 0.0;
  static const Duration kAnimDuration = Duration(milliseconds: 350);
}
