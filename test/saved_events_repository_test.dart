import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:future_times_events/core/errors/app_failure.dart';
import 'package:future_times_events/data/repositories/saved_events_repository.dart';

void main() {
  test('loads the signed-in user saved event ids', () async {
    final store = _FakeSavedEventsStore(initial: {'event-1', 'event-2'});
    final repository = SavedEventsRepository(
      store: store,
      userIdProvider: () => 'user-1',
    );

    await repository.load();

    expect(repository.ids, {'event-1', 'event-2'});
    expect(repository.lastFailure, isNull);
    repository.dispose();
  });

  test('rolls back optimistic save when persistence fails', () async {
    final store = _FakeSavedEventsStore()..failSave = true;
    final repository = SavedEventsRepository(
      store: store,
      userIdProvider: () => 'user-1',
    );

    final operation = repository.toggle('event-1');
    expect(repository.isSaved('event-1'), isTrue);
    expect(repository.isPending('event-1'), isTrue);
    await expectLater(operation, throwsA(isA<DataFailure>()));

    expect(repository.isSaved('event-1'), isFalse);
    expect(repository.isPending('event-1'), isFalse);
    expect(repository.lastFailure, isA<DataFailure>());
    repository.dispose();
  });

  test('coalesces rapid duplicate save taps', () async {
    final store = _FakeSavedEventsStore()..saveGate = Completer<void>();
    final repository = SavedEventsRepository(
      store: store,
      userIdProvider: () => 'user-1',
    );

    final first = repository.toggle('event-1');
    final second = repository.toggle('event-1');
    expect(store.saveCalls, 1);
    store.saveGate!.complete();
    await Future.wait([first, second]);

    expect(repository.isSaved('event-1'), isTrue);
    expect(store.saveCalls, 1);
    repository.dispose();
  });

  test('requires authentication before mutating saved state', () async {
    final repository = SavedEventsRepository(
      store: _FakeSavedEventsStore(),
      userIdProvider: () => null,
    );

    await expectLater(
      repository.toggle('event-1'),
      throwsA(isA<AuthFailure>()),
    );
    expect(repository.ids, isEmpty);
    repository.dispose();
  });
}

class _FakeSavedEventsStore implements SavedEventsStore {
  _FakeSavedEventsStore({Set<String>? initial}) : values = {...?initial};

  final Set<String> values;
  bool failSave = false;
  Completer<void>? saveGate;
  int saveCalls = 0;

  @override
  Future<Set<String>> fetch(String userId) async => {...values};

  @override
  Future<void> save({required String userId, required String eventId}) async {
    saveCalls++;
    if (failSave) throw StateError('save failed');
    await saveGate?.future;
    values.add(eventId);
  }

  @override
  Future<void> remove({required String userId, required String eventId}) async {
    values.remove(eventId);
  }
}
