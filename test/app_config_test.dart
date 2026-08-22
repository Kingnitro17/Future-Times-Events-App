import 'package:flutter_test/flutter_test.dart';
import 'package:future_times_events/core/config/app_config.dart';

void main() {
  test('normalizes the production project id into its HTTPS URL', () {
    expect(
      AppConfig.normalizeSupabaseUrl(' ${AppConfig.expectedProjectId} '),
      'https://${AppConfig.expectedProjectId}.supabase.co',
    );
  });

  test('accepts only the intended production project and a public key', () {
    expect(
      AppConfig.isValidSupabaseConfig(
        'https://${AppConfig.expectedProjectId}.supabase.co',
        'public-test-key',
      ),
      isTrue,
    );
    expect(
      AppConfig.isValidSupabaseConfig(
        'https://another-project.supabase.co',
        'public-test-key',
      ),
      isFalse,
    );
    expect(
      AppConfig.isValidSupabaseConfig(
        'http://${AppConfig.expectedProjectId}.supabase.co',
        'public-test-key',
      ),
      isFalse,
    );
    expect(
      AppConfig.isValidSupabaseConfig(
        'https://${AppConfig.expectedProjectId}.supabase.co',
        ' ',
      ),
      isFalse,
    );
  });
}
