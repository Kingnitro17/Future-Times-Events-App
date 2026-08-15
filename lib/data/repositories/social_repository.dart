import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/attendee_model.dart';

class SocialRepository {
  SocialRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<void> checkIn({
    required String eventId,
    required String userId,
    required String displayName,
    String? avatarUrl,
  }) async {
    final authenticatedId = _client.auth.currentUser?.id;
    if (authenticatedId == null || authenticatedId != userId) {
      throw const AuthException('Authentication required.');
    }
    await _client.from('rsvps').upsert({
      'event_id': eventId,
      'user_id': authenticatedId,
      'status': 'going',
      'is_public': true,
    }, onConflict: 'event_id,user_id');
  }

  Future<void> checkOut({
    required String eventId,
    required String userId,
  }) async {
    final authenticatedId = _client.auth.currentUser?.id;
    if (authenticatedId == null || authenticatedId != userId) {
      throw const AuthException('Authentication required.');
    }
    await _client
        .from('rsvps')
        .update({'is_public': false})
        .eq('event_id', eventId)
        .eq('user_id', authenticatedId);
  }

  Stream<List<AttendeeModel>> watchAttendees(String eventId) =>
      Stream.fromFuture(getAttendees(eventId));

  Future<List<AttendeeModel>> getAttendees(String eventId) async {
    final rows = await _client
        .from('rsvps')
        .select('user_id,created_at')
        .eq('event_id', eventId)
        .eq('status', 'going')
        .eq('is_public', true)
        .order('created_at', ascending: false)
        .limit(24);
    final ids = rows
        .map((row) => row['user_id']?.toString())
        .whereType<String>()
        .toList();
    if (ids.isEmpty) return const [];

    final profiles = await _client
        .from('public_profile_cards')
        .select('id,display_name,avatar_url')
        .inFilter('id', ids);
    final byId = {
      for (final profile in profiles)
        if (profile['id'] != null) profile['id'].toString(): profile,
    };
    return rows.take(12).map((row) {
      final userId = row['user_id'].toString();
      final profile = byId[userId];
      return AttendeeModel(
        userId: userId,
        eventId: eventId,
        displayName: profile?['display_name']?.toString() ?? 'Attendee',
        avatarUrl: profile?['avatar_url']?.toString(),
        checkedInAt: DateTime.tryParse(row['created_at']?.toString() ?? ''),
      );
    }).toList();
  }

  Future<bool> hasCheckedIn({
    required String eventId,
    required String userId,
  }) async {
    final row = await _client
        .from('rsvps')
        .select('id')
        .eq('event_id', eventId)
        .eq('user_id', userId)
        .eq('status', 'going')
        .eq('is_public', true)
        .maybeSingle();
    return row != null;
  }

  Stream<int> watchAttendeeCount(String eventId) =>
      Stream.fromFuture(getAttendees(eventId).then((rows) => rows.length));
}
