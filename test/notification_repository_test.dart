import 'package:flutter_test/flutter_test.dart';
import 'package:future_times_events/data/repositories/notification_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  test('markAsRead rejects unauthenticated users', () async {
    final repository = NotificationRepository(client: _FakeSupabaseClient());

    await expectLater(
      repository.markAsRead('notification-1'),
      throwsA(isA<StateError>()),
    );
  });

  test('deleteNotification rejects unauthenticated users', () async {
    final repository = NotificationRepository(client: _FakeSupabaseClient());

    await expectLater(
      repository.deleteNotification('notification-1'),
      throwsA(isA<StateError>()),
    );
  });
}

class _FakeSupabaseClient extends Fake implements SupabaseClient {
  @override
  GoTrueClient get auth => _FakeGoTrueClient();
}

class _FakeGoTrueClient extends Fake implements GoTrueClient {
  @override
  User? get currentUser => null;
}
