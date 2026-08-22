import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/errors/app_failure.dart';
import 'auth_repository.dart';

abstract interface class SavedEventsStore {
  Future<Set<String>> fetch(String userId);
  Future<void> save({required String userId, required String eventId});
  Future<void> remove({required String userId, required String eventId});
}

class SupabaseSavedEventsStore implements SavedEventsStore {
  SupabaseSavedEventsStore([SupabaseClient? client])
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  @override
  Future<Set<String>> fetch(String userId) async {
    final rows = await _client
        .from('saved_events')
        .select('event_id')
        .eq('user_id', userId);
    return rows.map((row) => row['event_id'].toString()).toSet();
  }

  @override
  Future<void> save({required String userId, required String eventId}) =>
      _client.from('saved_events').insert({
        'user_id': userId,
        'event_id': eventId,
      });

  @override
  Future<void> remove({required String userId, required String eventId}) =>
      _client
          .from('saved_events')
          .delete()
          .eq('user_id', userId)
          .eq('event_id', eventId);
}

class SavedEventsRepository extends ChangeNotifier {
  SavedEventsRepository({
    AuthRepository? authRepository,
    SupabaseClient? client,
    SavedEventsStore? store,
    String? Function()? userIdProvider,
  })  : assert(authRepository != null || userIdProvider != null),
        _auth = authRepository,
        _store = store ?? SupabaseSavedEventsStore(client),
        _userIdProvider = userIdProvider ?? (() => authRepository?.user?.id) {
    _auth?.addListener(_handleAuthChange);
  }

  final AuthRepository? _auth;
  final SavedEventsStore _store;
  final String? Function() _userIdProvider;
  final Set<String> _ids = {};
  final Set<String> _pending = {};
  bool _loading = false;
  String? _loadedUserId;
  AppFailure? _lastFailure;

  Set<String> get ids => Set.unmodifiable(_ids);
  bool get isLoading => _loading;
  AppFailure? get lastFailure => _lastFailure;
  bool isSaved(String eventId) => _ids.contains(eventId);
  bool isPending(String eventId) => _pending.contains(eventId);

  void _handleAuthChange() {
    final id = _userIdProvider();
    if (id == _loadedUserId) return;
    _ids.clear();
    _pending.clear();
    _lastFailure = null;
    _loadedUserId = id;
    notifyListeners();
    if (id != null) load();
  }

  Future<void> load() async {
    final userId = _userIdProvider();
    if (userId == null) return;
    _loading = true;
    _lastFailure = null;
    notifyListeners();
    try {
      final remoteIds = await _store.fetch(userId);
      if (userId != _userIdProvider()) return;
      _ids
        ..clear()
        ..addAll(remoteIds);
      _loadedUserId = userId;
    } catch (error) {
      if (kDebugMode) {
        debugPrint('[saved-events] load failed: ${error.runtimeType}');
      }
      _lastFailure = const DataFailure(
        'Saved events could not be loaded. Try again.',
      );
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> toggle(String eventId) async {
    final userId = _userIdProvider();
    if (userId == null) {
      throw const AuthFailure('Sign in to save events.');
    }
    if (_pending.contains(eventId)) return;

    final wasSaved = _ids.contains(eventId);
    _pending.add(eventId);
    _lastFailure = null;
    wasSaved ? _ids.remove(eventId) : _ids.add(eventId);
    notifyListeners();
    try {
      if (wasSaved) {
        await _store.remove(userId: userId, eventId: eventId);
      } else {
        await _store.save(userId: userId, eventId: eventId);
      }
    } catch (error) {
      wasSaved ? _ids.add(eventId) : _ids.remove(eventId);
      _lastFailure = const DataFailure(
        'Could not update your saved events. Try again.',
      );
      if (kDebugMode) {
        debugPrint('[saved-events] update failed: ${error.runtimeType}');
      }
      throw _lastFailure!;
    } finally {
      _pending.remove(eventId);
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _auth?.removeListener(_handleAuthChange);
    super.dispose();
  }
}
