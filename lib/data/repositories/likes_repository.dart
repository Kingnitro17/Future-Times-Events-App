import 'package:supabase_flutter/supabase_flutter.dart';

class LikesRepository {
  LikesRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<int> getLikeCount(String eventId) async {
    final response = await _client
        .from('event_likes')
        .select('user_id')
        .eq('event_id', eventId)
        .count(CountOption.exact);
    return response.count;
  }

  Future<bool> hasLiked(String eventId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return false;
    final row = await _client
        .from('event_likes')
        .select('user_id')
        .eq('event_id', eventId)
        .eq('user_id', userId)
        .maybeSingle();
    return row != null;
  }

  Future<void> likeEvent(String eventId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw const AuthException('Sign in to like events.');
    }
    await _client.from('event_likes').upsert(
      {'event_id': eventId, 'user_id': userId},
      onConflict: 'event_id,user_id',
      ignoreDuplicates: true,
    );
  }

  Future<void> unlikeEvent(String eventId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw const AuthException('Sign in to unlike events.');
    }
    await _client
        .from('event_likes')
        .delete()
        .eq('event_id', eventId)
        .eq('user_id', userId);
  }

  Future<Map<String, int>> getLikeCounts(List<String> eventIds) async {
    if (eventIds.isEmpty) return const {};
    final rows = await _client
        .from('event_likes')
        .select('event_id')
        .inFilter('event_id', eventIds);
    final counts = <String, int>{};
    for (final row in rows) {
      final eventId = row['event_id']?.toString();
      if (eventId != null) {
        counts.update(
          eventId,
          (count) => count + 1,
          ifAbsent: () => 1,
        );
      }
    }
    return counts;
  }

  Stream<int> watchLikeCount(String eventId) => _client
      .from('event_likes')
      .stream(primaryKey: const ['event_id', 'user_id'])
      .eq('event_id', eventId)
      .map((rows) => rows.length);
}
