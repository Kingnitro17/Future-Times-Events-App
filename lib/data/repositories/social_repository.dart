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
    final snapshot = await _client
        .from('event_attendee_snapshots')
        .select('preview_attendees')
        .eq('event_id', eventId)
        .maybeSingle();
    final preview = snapshot?['preview_attendees'];
    if (preview is! List) return const [];
    return preview.take(12).map((value) {
      final row = value as Map<String, dynamic>;
      final userId = row['user_id']?.toString() ?? '';
      return AttendeeModel(
        userId: userId,
        eventId: eventId,
        displayName: row['display_name']?.toString() ?? 'Attendee',
        avatarUrl: row['avatar_url']?.toString(),
        checkedInAt: DateTime.tryParse(row['rsvp_at']?.toString() ?? ''),
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

  Stream<int> watchAttendeeCount(String eventId) => Stream.fromFuture(_client
      .from('event_attendee_snapshots')
      .select('going_count')
      .eq('event_id', eventId)
      .maybeSingle()
      .then((row) => int.tryParse(row?['going_count']?.toString() ?? '') ?? 0));

  Future<int> getAttendeeCount(String eventId) async {
    final row = await _client
        .from('event_attendee_snapshots')
        .select('going_count')
        .eq('event_id', eventId)
        .maybeSingle();
    return int.tryParse(row?['going_count']?.toString() ?? '') ?? 0;
  }
}
