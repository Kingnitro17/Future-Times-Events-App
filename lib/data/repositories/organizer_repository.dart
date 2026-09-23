import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth_repository.dart';
import '../models/organizer_application.dart';

class OrganizerRepository {
  OrganizerRepository({
    required AuthRepository authRepository,
    SupabaseClient? client,
  })  : _auth = authRepository,
        _client = client ?? Supabase.instance.client;

  final AuthRepository _auth;
  final SupabaseClient _client;

  Future<OrganizerApplication> submitApplication({
    required String businessName,
    String? businessRegistration,
    required String contactPhone,
    required String contactEmail,
    required String description,
  }) async {
    final user = _auth.user;
    if (user == null) {
      throw StateError('A signed-in account is required to apply.');
    }
    final row = await _client
        .from('organizer_applications')
        .insert({
          'user_id': user.id,
          'business_name': businessName.trim(),
          if (businessRegistration != null &&
              businessRegistration.trim().isNotEmpty)
            'business_registration': businessRegistration.trim(),
          'contact_phone': contactPhone.trim(),
          'contact_email': contactEmail.trim(),
          'description': description.trim(),
          'status': 'pending',
        })
        .select()
        .single();
    return OrganizerApplication.fromSupabase(row);
  }

  Future<OrganizerApplication?> getMyApplication() async {
    final user = _auth.user;
    if (user == null) return null;
    final row = await _client
        .from('organizer_applications')
        .select()
        .eq('user_id', user.id)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();
    return row == null ? null : OrganizerApplication.fromSupabase(row);
  }

  Future<List<Map<String, dynamic>>> getMyEvents() async {
    final user = _auth.user;
    if (user == null) return const [];
    final rows = await _client
        .from('events')
        .select()
        .eq('organizer_id', user.id)
        .order('created_at', ascending: false);
    return rows.cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> getMyStats() async {
    final events = await getMyEvents();
    final eventIds = events
        .map((event) => event['id']?.toString())
        .whereType<String>()
        .toList();
    if (eventIds.isEmpty) {
      return {
        'total_events': 0,
        'tickets_sold': 0,
        'revenue': 0,
        'upcoming_count': 0,
      };
    }

    final tickets = await _client
        .from('tickets')
        .select('id')
        .inFilter('event_id', eventIds);
    final payments = await _client
        .from('payment_transactions')
        .select('amount')
        .eq('purpose', 'ticket')
        .eq('status', 'paid')
        .inFilter('related_entity_id', eventIds);
    final now = DateTime.now();
    final upcomingCount = events.where((event) {
      final startsAt = DateTime.tryParse(event['starts_at']?.toString() ?? '');
      return startsAt != null && startsAt.isAfter(now);
    }).length;
    final revenue = payments.fold<num>(
      0,
      (sum, row) => sum + (num.tryParse(row['amount']?.toString() ?? '') ?? 0),
    );

    return {
      'total_events': events.length,
      'tickets_sold': tickets.length,
      'revenue': revenue,
      'upcoming_count': upcomingCount,
    };
  }

  Future<List<Map<String, dynamic>>> getRecentTicketSales() async {
    final user = _auth.user;
    if (user == null) return const [];
    final events = await getMyEvents();
    final eventIds = events
        .map((event) => event['id']?.toString())
        .whereType<String>()
        .toList();
    if (eventIds.isEmpty) return const [];
    final rows = await _client
        .from('tickets')
        .select(
            'id,ticket_number,attendee_name,attendee_email,issued_at,event_id')
        .inFilter('event_id', eventIds)
        .order('issued_at', ascending: false)
        .limit(5);
    return rows.cast<Map<String, dynamic>>();
  }

  Future<String> createEvent(Map<String, dynamic> data) async {
    final user = _auth.user;
    if (user == null) throw StateError('A signed-in organizer is required.');
    final row = await _client
        .from('events')
        .insert({...data, 'organizer_id': user.id, 'status': 'draft'})
        .select('id')
        .single();
    return row['id'].toString();
  }

  Future<void> updateEvent(String eventId, Map<String, dynamic> data) async {
    final user = _auth.user;
    if (user == null) throw StateError('A signed-in organizer is required.');
    await _client
        .from('events')
        .update(data)
        .eq('id', eventId)
        .eq('organizer_id', user.id);
  }

  Future<Map<String, dynamic>?> getEventForEdit(String eventId) async {
    final user = _auth.user;
    if (user == null) return null;
    return _client
        .from('events')
        .select()
        .eq('id', eventId)
        .eq('organizer_id', user.id)
        .maybeSingle();
  }

  Future<List<Map<String, dynamic>>> getTicketTypes(String eventId) async {
    final rows = await _client
        .from('ticket_types')
        .select()
        .eq('event_id', eventId)
        .order('sort_order');
    return rows.cast<Map<String, dynamic>>();
  }

  Future<void> upsertTicketTypes(
    String eventId,
    List<Map<String, dynamic>> types,
  ) async {
    final existing = await getTicketTypes(eventId);
    final retainedIds = <String>{};
    for (final entry in types.asMap().entries) {
      final type = {
        ...entry.value,
        'event_id': eventId,
        'sort_order': entry.key,
      };
      final id = type['id']?.toString();
      if (id != null && id.isNotEmpty) {
        retainedIds.add(id);
        await _client.from('ticket_types').update(type).eq('id', id);
      } else {
        await _client.from('ticket_types').insert(type);
      }
    }
    for (final row in existing) {
      final id = row['id']?.toString();
      if (id != null && !retainedIds.contains(id)) {
        await _client.from('ticket_types').delete().eq('id', id);
      }
    }
  }

  Future<String> uploadEventCover(Uint8List bytes, String fileName) async {
    final path =
        '${_auth.user?.id ?? 'anonymous'}/${DateTime.now().millisecondsSinceEpoch}_$fileName';
    await _client.storage.from('events').uploadBinary(
          path,
          bytes,
          fileOptions: const FileOptions(upsert: true),
        );
    return _client.storage.from('events').getPublicUrl(path);
  }

  Future<void> submitEventForReview(String eventId) async {
    await _client.rpc(
      'submit_event_for_review',
      params: {'p_event_id': eventId},
    );
  }

  Future<Map<String, dynamic>> getEventOwnerView(String eventId) async {
    final event =
        await _client.from('events').select().eq('id', eventId).maybeSingle();
    if (event == null) {
      throw StateError('Event not found or access denied.');
    }
    if (_auth.user?.id != event['organizer_id'] &&
        _auth.currentRole != 'super_admin') {
      throw StateError('Event not found or access denied.');
    }
    final reviewLog = await _client
        .from('event_review_log')
        .select()
        .eq('event_id', eventId)
        .order('created_at', ascending: false);
    final tickets = await _client
        .from('tickets')
        .select('id,status')
        .eq('event_id', eventId);
    final payments = await _client
        .from('payment_transactions')
        .select('amount')
        .eq('purpose', 'ticket')
        .eq('status', 'paid')
        .eq('related_entity_id', eventId);
    final revenue = payments.fold<num>(
      0,
      (sum, row) => sum + (num.tryParse(row['amount']?.toString() ?? '') ?? 0),
    );
    return {
      ...event,
      'review_log': reviewLog.cast<Map<String, dynamic>>(),
      'owner_stats': {
        'tickets_sold': tickets.length,
        'check_ins':
            tickets.where((row) => row['status'] == 'checked_in').length,
        'revenue': revenue,
      },
    };
  }

  Future<List<Map<String, dynamic>>> getEventAttendees(String eventId) async {
    final event = await getEventOwnerView(eventId);
    final rows = await _client
        .from('tickets')
        .select('*, ticket_types(*)')
        .eq('event_id', event['id'])
        .order('issued_at', ascending: false);
    final userIds = rows
        .map((row) => row['user_id']?.toString())
        .whereType<String>()
        .toSet()
        .toList();
    final profiles = userIds.isEmpty
        ? <Map<String, dynamic>>[]
        : (await _client
                .from('profiles')
                .select('id,display_name,email,phone')
                .inFilter('id', userIds))
            .cast<Map<String, dynamic>>();
    final profilesById = {
      for (final profile in profiles) profile['id'].toString(): profile,
    };
    return rows.map((row) {
      final profile = profilesById[row['user_id']?.toString()];
      return {
        ...row,
        'profile': profile,
        'ticket_type': row['ticket_types'],
      };
    }).toList();
  }

  Future<void> publishEvent(String eventId) async {
    await _client.rpc(
      'publish_event',
      params: {'p_event_id': eventId},
    );
  }

  Future<void> submitForReview(String eventId) async {
    await submitEventForReview(eventId);
  }
}
