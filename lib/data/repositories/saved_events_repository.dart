import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/errors/app_failure.dart';
import 'auth_repository.dart';

class SavedEventsRepository extends ChangeNotifier {
  SavedEventsRepository(
      {required AuthRepository authRepository, SupabaseClient? client})
      : _auth = authRepository,
        _client = client ?? Supabase.instance.client {
    _auth.addListener(_handleAuthChange);
  }

  final AuthRepository _auth;
  final SupabaseClient _client;
  final Set<String> _ids = {};
  bool _loading = false;
  String? _loadedUserId;

  Set<String> get ids => Set.unmodifiable(_ids);
  bool get isLoading => _loading;
  bool isSaved(String eventId) => _ids.contains(eventId);

  void _handleAuthChange() {
    final id = _auth.user?.id;
    if (id == _loadedUserId) return;
    _ids.clear();
    _loadedUserId = id;
    notifyListeners();
    if (id != null) load();
  }

  Future<void> load() async {
    final userId = _auth.user?.id;
    if (userId == null) return;
    _loading = true;
    notifyListeners();
    try {
      final rows = await _client
          .from('saved_events')
          .select('event_id')
          .eq('user_id', userId);
      _ids
        ..clear()
        ..addAll(rows.map((row) => row['event_id'].toString()));
      _loadedUserId = userId;
    } on PostgrestException catch (error) {
      if (kDebugMode) debugPrint('[saved-events] load failed: ${error.code}');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> toggle(String eventId) async {
    final userId = _auth.user?.id;
    if (userId == null) {
      throw const AuthFailure('Sign in to save events.');
    }
    final wasSaved = _ids.contains(eventId);
    wasSaved ? _ids.remove(eventId) : _ids.add(eventId);
    notifyListeners();
    try {
      if (wasSaved) {
        await _client
            .from('saved_events')
            .delete()
            .eq('user_id', userId)
            .eq('event_id', eventId);
      } else {
        await _client.from('saved_events').insert({
          'user_id': userId,
          'event_id': eventId,
        });
      }
    } on PostgrestException catch (error) {
      wasSaved ? _ids.add(eventId) : _ids.remove(eventId);
      notifyListeners();
      if (kDebugMode) debugPrint('[saved-events] update failed: ${error.code}');
      throw const DataFailure('Could not update your saved events. Try again.');
    }
  }

  @override
  void dispose() {
    _auth.removeListener(_handleAuthChange);
    super.dispose();
  }
}
