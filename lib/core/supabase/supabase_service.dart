import 'dart:developer' as dev;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/app_config.dart';

/// Single gateway to the Supabase client.
///
/// Initialize once in [bootstrap.dart] via [SupabaseService.initialize].
/// Access the client anywhere with [SupabaseService.client].
class SupabaseService {
  SupabaseService._();

  static bool _initialized = false;

  /// Initialize Supabase. Call once before [runApp].
  static Future<void> initialize() async {
    if (_initialized) return;

    if (AppConfig.supabaseUrl == 'https://placeholder.supabase.co' ||
        AppConfig.supabaseAnonKey.isEmpty) {
      dev.log(
        '[SupabaseService] WARNING: Running without real Supabase credentials. '
        'Pass --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...',
        name: 'SupabaseService',
      );
    }

    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      anonKey: AppConfig.supabaseAnonKey,
      authOptions: FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
        autoRefreshToken: true,
      ),
      debug: AppConfig.isDev,
    );

    _initialized = true;
    dev.log('[SupabaseService] Initialized.', name: 'SupabaseService');
  }

  /// The initialized Supabase client. Throws if called before [initialize].
  static SupabaseClient get client {
    assert(_initialized, 'Call SupabaseService.initialize() first.');
    return Supabase.instance.client;
  }

  /// Convenience: current authenticated user (null if not signed in).
  static User? get currentUser => client.auth.currentUser;

  /// Convenience: current session (null if not signed in).
  static Session? get currentSession => client.auth.currentSession;

  /// Auth state change stream.
  static Stream<AuthState> get authStream => client.auth.onAuthStateChange;
}
