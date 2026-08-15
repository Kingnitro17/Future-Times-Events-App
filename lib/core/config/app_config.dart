import 'package:flutter/foundation.dart';

class AppConfig {
  const AppConfig._();

  static const _supabaseUrlInput = String.fromEnvironment('SUPABASE_URL');
  static const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
  static const qaMockAuth = bool.fromEnvironment('QA_MOCK_AUTH');
  static const expectedProjectId = 'ecbbmcqwluivbzlaqdsd';

  static String get supabaseUrl {
    final value = _supabaseUrlInput.trim();
    if (value == expectedProjectId) {
      return 'https://$expectedProjectId.supabase.co';
    }
    return value;
  }

  static bool get isConfigured {
    final uri = Uri.tryParse(supabaseUrl);
    return uri?.scheme == 'https' &&
        uri?.host.endsWith('.supabase.co') == true &&
        supabaseAnonKey.trim().isNotEmpty;
  }

  static String get projectId {
    final host = Uri.tryParse(supabaseUrl)?.host ?? '';
    return host.endsWith('.supabase.co') ? host.split('.').first : host;
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
      debugPrint(
          '[config] QA mock auth: ${qaMockAuth ? 'enabled' : 'disabled'}');
    }
  }
}
