/// App-wide compile-time configuration injected via --dart-define.
/// Never commit real values. Use:
///   flutter run \
///     --dart-define=SUPABASE_URL=https://xxx.supabase.co \
///     --dart-define=SUPABASE_ANON_KEY=eyJ... \
///     --dart-define=APP_BASE_URL=https://futuretimes.events
class AppConfig {
  AppConfig._();

  /// The Supabase project URL. Public — no secrets.
  static const supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://placeholder.supabase.co',
  );

  /// The Supabase anon (publishable) key. Public — RLS enforced.
  static const supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '',
  );

  /// Canonical website base URL used for sharing and deep links.
  static const appBaseUrl = String.fromEnvironment(
    'APP_BASE_URL',
    defaultValue: 'https://futuretimes.events',
  );

  /// Whether the app is running in development mode.
  static const isDev = bool.fromEnvironment('IS_DEV', defaultValue: false);

  /// App display name.
  static const appName = 'Future Times Events';

  /// Minimum payout amount (ZWL/USD — must match backend setting).
  static const minPayoutAmount = 5.0;

  /// QR token byte length for secure random generation.
  static const qrTokenBytes = 32;

  /// Payment status poll interval in seconds.
  static const paymentPollIntervalSeconds = 5;

  /// Payment status poll max attempts before stopping.
  static const paymentPollMaxAttempts = 60;

  /// Ticket search debounce in milliseconds.
  static const searchDebounceMs = 300;

  /// Default event page size for pagination.
  static const eventPageSize = 20;
}
