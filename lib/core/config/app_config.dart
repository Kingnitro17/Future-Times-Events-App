import 'package:flutter/foundation.dart';

class AppConfig {
  const AppConfig._();

  static const _defaultSupabaseUrl = 'https://ecbbmcqwluivbzlaqdsd.supabase.co';
  static const _defaultSupabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVjYmJtY3F3bHVpdmJ6bGFxZHNkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzc3NjEyNzcsImV4cCI6MjA5MzMzNzI3N30.XTTs7RN-SrZ0YnC20m8mZms8ZfVVeANJgvwg1Key6SQ';

  static const _supabaseUrlInput = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: _defaultSupabaseUrl,
  );
  static const supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: _defaultSupabaseAnonKey,
  );
  static const expectedProjectId = 'ecbbmcqwluivbzlaqdsd';

  static String get supabaseUrl {
    return normalizeSupabaseUrl(_supabaseUrlInput);
  }

  static bool get isConfigured {
    return isValidSupabaseConfig(supabaseUrl, supabaseAnonKey);
  }

  static String get projectId {
    return projectIdFromSupabaseUrl(supabaseUrl);
  }

  static void validate() {
    if (!isConfigured) {
      throw StateError(
        'Supabase is not configured. Run with --dart-define=SUPABASE_URL=... '
        '--dart-define=SUPABASE_ANON_KEY=...',
      );
    }
    if (projectId != expectedProjectId) {
      throw StateError('Supabase project does not match production.');
    }
    if (kDebugMode) {
      debugPrint('[config] Supabase configured: yes');
      debugPrint('[config] Supabase project: $projectId');
      debugPrint('[config] publishable key present: yes');
      debugPrint('[config] build mode: debug');
    }
  }

  @visibleForTesting
  static String normalizeSupabaseUrl(String input) {
    final value = input.trim();
    if (value == expectedProjectId) {
      return 'https://$expectedProjectId.supabase.co';
    }
    return value;
  }

  @visibleForTesting
  static String projectIdFromSupabaseUrl(String value) {
    final host = Uri.tryParse(value)?.host ?? '';
    return host.endsWith('.supabase.co') ? host.split('.').first : host;
  }

  @visibleForTesting
  static bool isValidSupabaseConfig(String url, String publishableKey) {
    final uri = Uri.tryParse(url.trim());
    return uri?.scheme == 'https' &&
        uri?.host.endsWith('.supabase.co') == true &&
        projectIdFromSupabaseUrl(url) == expectedProjectId &&
        publishableKey.trim().isNotEmpty;
  }
}
