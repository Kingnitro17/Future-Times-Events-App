import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminRepository {
  AdminRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<Map<String, dynamic>> getDashboardKpis() async {
    try {
      final response = await _client.rpc('admin_dashboard_kpis');
      if (response is Map<String, dynamic>) return response;
      if (response is List && response.isNotEmpty && response.first is Map) {
        return Map<String, dynamic>.from(response.first as Map);
      }
    } catch (error) {
      if (kDebugMode) {
        debugPrint('[admin] admin_dashboard_kpis unavailable: $error');
      }
    }
    // The RPC is absent until the admin dashboard migration is applied, so
    // fall back to counting the tables the client can already read.
    return _countKpisFromTables();
  }

  Future<Map<String, dynamic>> _countKpisFromTables() async {
    final events = (await _client.from('events').select('id,status'))
        .cast<Map<String, dynamic>>();
    final profiles = (await _client.from('profiles').select('id,role'))
        .cast<Map<String, dynamic>>();
    final tickets =
        (await _client.from('tickets').select('id,status,ticket_type_id'))
            .cast<Map<String, dynamic>>();
    final ticketTypes = (await _client.from('ticket_types').select('id,price'))
        .cast<Map<String, dynamic>>();

    final prices = {
      for (final type in ticketTypes)
        type['id'].toString(): num.tryParse(type['price']?.toString() ?? '') ?? 0,
    };
    const soldStatuses = {'issued', 'checked_in'};
    final sold = tickets
        .where((ticket) => soldStatuses.contains(ticket['status']?.toString()))
        .toList();
    final revenue = sold.fold<num>(
      0,
      (total, ticket) =>
          total + (prices[ticket['ticket_type_id']?.toString()] ?? 0),
    );

    int countEvents(Set<String> statuses) => events
        .where((event) => statuses.contains(event['status']?.toString()))
        .length;

    return {
      'total_events': events.length,
      'published_events': countEvents(const {'published', 'live', 'ended'}),
      'pending_reviews': countEvents(const {'pending_review'}),
      'total_users': profiles.length,
      'total_organizers': profiles
          .where((profile) => profile['role'] == 'organizer' ||
              profile['role'] == 'super_admin')
          .length,
      'tickets_sold': sold.length,
      'revenue': revenue,
    };
  }

  Future<List<Map<String, dynamic>>> getUsers({
    String? search,
    String? roleFilter,
  }) async {
    var query = _client.from('profiles').select();
    if (roleFilter != null && roleFilter.isNotEmpty) {
      query = query.eq('role', roleFilter);
    }
    final term = search?.trim() ?? '';
    if (term.isNotEmpty) {
      final escaped = term.replaceAll('%', r'\%').replaceAll('_', r'\_');
      query = query.or('display_name.ilike.%$escaped%,email.ilike.%$escaped%');
    }
    final rows = await query.order('created_at', ascending: false).limit(200);
    return rows.cast<Map<String, dynamic>>();
  }

  Future<void> setUserRole(String userId, String role) async {
    await _client.rpc('admin_set_user_role', params: {
      'p_user_id': userId,
      'p_role': role,
    });
  }

  Future<List<Map<String, dynamic>>> getOrganizerApplications({
    String? statusFilter,
  }) async {
    var query = _client.from('organizer_applications').select();
    if (statusFilter != null && statusFilter.isNotEmpty) {
      query = query.eq('status', statusFilter);
    }
    final rows = await query.order('created_at', ascending: false);
    final applications = rows.cast<Map<String, dynamic>>();
    if (applications.isEmpty) return const [];

    final userIds = applications
        .map((application) => application['user_id']?.toString())
        .whereType<String>()
        .toSet()
        .toList();
    final profiles = (await _client
            .from('profiles')
            .select('id,display_name,email,role')
            .inFilter('id', userIds))
        .cast<Map<String, dynamic>>();
    final byId = {
      for (final profile in profiles) profile['id'].toString(): profile,
    };
    return applications
        .map((application) => {
              ...application,
              'applicant': byId[application['user_id']?.toString()],
            })
        .toList();
  }

  Future<void> approveOrganizerApplication(String applicationId) async {
    await _client.rpc('approve_organizer_application', params: {
      'p_application_id': applicationId,
    });
  }

  Future<void> rejectOrganizerApplication(
    String applicationId,
    String reason,
  ) async {
    await _client.rpc('reject_organizer_application', params: {
      'p_application_id': applicationId,
      'p_reason': reason,
    });
  }

  Future<int> getPendingReviewCount() async {
    final rows = await _client
        .from('events')
        .select('id')
        .eq('status', 'pending_review');
    return rows.length;
  }

  Future<List<Map<String, dynamic>>> getRecentEvents({int limit = 10}) async {
    final rows = await _client
        .from('events')
        .select()
        .order('created_at', ascending: false)
        .limit(limit);
    final events = rows.cast<Map<String, dynamic>>();
    final organizerIds = events
        .map((event) => event['organizer_id']?.toString())
        .whereType<String>()
        .toSet()
        .toList();
    if (organizerIds.isEmpty) return events;

    final profiles = await _client
        .from('profiles')
        .select('id,display_name')
        .inFilter('id', organizerIds);
    final names = {
      for (final profile in profiles)
        profile['id'].toString(): profile['display_name']?.toString(),
    };
    return events
        .map((event) => {
              ...event,
              'organizer_display_name':
                  names[event['organizer_id']?.toString()],
            })
        .toList();
  }

  Future<List<Map<String, dynamic>>> getRecentSignups({int limit = 10}) async {
    final rows = await _client
        .from('profiles')
        .select()
        .order('created_at', ascending: false)
        .limit(limit);
    return rows.cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> getPendingReviewEvents() async {
    final rows = await _client
        .from('events')
        .select()
        .eq('status', 'pending_review')
        .order('submitted_at', ascending: true);
    final events = rows.cast<Map<String, dynamic>>();
    if (events.isEmpty) return const [];

    final eventIds = events
        .map((event) => event['id']?.toString())
        .whereType<String>()
        .toList();
    final organizerIds = events
        .map((event) => event['organizer_id']?.toString())
        .whereType<String>()
        .toSet()
        .toList();
    final ticketTypes = await _client
        .from('ticket_types')
        .select('id,event_id')
        .inFilter('event_id', eventIds);
    final counts = <String, int>{};
    for (final row in ticketTypes) {
      final eventId = row['event_id']?.toString();
      if (eventId != null) counts[eventId] = (counts[eventId] ?? 0) + 1;
    }
    final profiles = organizerIds.isEmpty
        ? const <Map<String, dynamic>>[]
        : (await _client
                .from('profiles')
                .select('id,display_name')
                .inFilter('id', organizerIds))
            .cast<Map<String, dynamic>>();
    final names = {
      for (final profile in profiles)
        profile['id'].toString(): profile['display_name']?.toString(),
    };
    return events
        .map((event) => {
              ...event,
              'organizer_display_name':
                  names[event['organizer_id']?.toString()],
              'ticket_types_count': counts[event['id']?.toString()] ?? 0,
            })
        .toList();
  }

  Future<void> approveEvent(String eventId) async {
    await _client.rpc('approve_event', params: {'p_event_id': eventId});
  }

  Future<void> rejectEvent(String eventId, String reason) async {
    await _client.rpc('reject_event', params: {
      'p_event_id': eventId,
      'p_reason': reason,
    });
  }

  Future<List<Map<String, dynamic>>> getAllEvents({
    String? statusFilter,
    String? search,
  }) async {
    final rows = (statusFilter != null &&
                statusFilter.isNotEmpty &&
                statusFilter != 'all'
            ? await _client
                .from('events')
                .select()
                .eq('status', statusFilter)
                .order('created_at', ascending: false)
            : await _client
                .from('events')
                .select()
                .order('created_at', ascending: false))
        .cast<Map<String, dynamic>>();
    final organizerIds = rows
        .map((event) => event['organizer_id']?.toString())
        .whereType<String>()
        .toSet()
        .toList();
    final eventIds = rows
        .map((event) => event['id']?.toString())
        .whereType<String>()
        .toList();
    final profiles = organizerIds.isEmpty
        ? const <Map<String, dynamic>>[]
        : (await _client
                .from('profiles')
                .select('id,display_name')
                .inFilter('id', organizerIds))
            .cast<Map<String, dynamic>>();
    final names = {
      for (final profile in profiles)
        profile['id'].toString(): profile['display_name']?.toString(),
    };
    final ticketTypes = eventIds.isEmpty
        ? const <Map<String, dynamic>>[]
        : (await _client
                .from('ticket_types')
                .select('event_id,quantity_total')
                .inFilter('event_id', eventIds))
            .cast<Map<String, dynamic>>();
    final capacity = <String, int>{};
    for (final row in ticketTypes) {
      final id = row['event_id']?.toString();
      if (id != null) {
        capacity[id] = (capacity[id] ?? 0) +
            (int.tryParse(row['quantity_total']?.toString() ?? '') ?? 0);
      }
    }
    final tickets = eventIds.isEmpty
        ? const <Map<String, dynamic>>[]
        : (await _client
                .from('tickets')
                .select('event_id')
                .inFilter('event_id', eventIds))
            .cast<Map<String, dynamic>>();
    final sold = <String, int>{};
    for (final row in tickets) {
      final id = row['event_id']?.toString();
      if (id != null) sold[id] = (sold[id] ?? 0) + 1;
    }
    final enriched = rows.map((event) {
      final id = event['id']?.toString();
      return {
        ...event,
        'organizer_display_name': names[event['organizer_id']?.toString()],
        'tickets_sold': sold[id] ?? 0,
        'capacity': capacity[id] ?? 0,
      };
    }).toList();
    final normalized = search?.trim().toLowerCase() ?? '';
    if (normalized.isEmpty) return enriched;
    return enriched.where((event) {
      final title = event['title']?.toString().toLowerCase() ?? '';
      final organizer =
          event['organizer_display_name']?.toString().toLowerCase() ?? '';
      return title.contains(normalized) || organizer.contains(normalized);
    }).toList();
  }

  Future<Map<String, dynamic>> getEventAdminView(String eventId) async {
    final event =
        await _client.from('events').select().eq('id', eventId).maybeSingle();
    if (event == null) throw StateError('Event not found.');
    final organizerId = event['organizer_id']?.toString();
    final organizer = organizerId == null
        ? null
        : await _client
            .from('profiles')
            .select()
            .eq('id', organizerId)
            .maybeSingle();
    final reviewLog = await _client
        .from('event_review_log')
        .select()
        .eq('event_id', eventId)
        .order('created_at', ascending: false);
    final ticketTypes = (await _client
            .from('ticket_types')
            .select()
            .eq('event_id', eventId)
            .order('sort_order'))
        .cast<Map<String, dynamic>>();
    final tickets = (await _client
            .from('tickets')
            .select('*, ticket_types(*)')
            .eq('event_id', eventId)
            .order('issued_at', ascending: false))
        .cast<Map<String, dynamic>>();
    final userIds = tickets
        .map((ticket) => ticket['user_id']?.toString())
        .whereType<String>()
        .toSet()
        .toList();
    final profiles = userIds.isEmpty
        ? const <Map<String, dynamic>>[]
        : (await _client
                .from('profiles')
                .select('id,display_name,email,phone')
                .inFilter('id', userIds))
            .cast<Map<String, dynamic>>();
    final profilesById = {
      for (final profile in profiles) profile['id'].toString(): profile,
    };
    final attendees = tickets.map((ticket) {
      return {
        ...ticket,
        'profile': profilesById[ticket['user_id']?.toString()],
      };
    }).toList();
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
      'organizer_profile': organizer,
      'review_log': reviewLog.cast<Map<String, dynamic>>(),
      'ticket_types': ticketTypes,
      'attendees': attendees,
      'stats': {
        'tickets_sold': attendees.length,
        'check_ins':
            attendees.where((row) => row['status'] == 'checked_in').length,
        'revenue': revenue,
      },
    };
  }

  Future<void> forceUnpublishEvent(String eventId, String reason) async {
    await _client.from('events').update({
      'status': 'archived',
      'rejection_reason': reason.trim(),
      'reviewed_at': DateTime.now().toIso8601String(),
    }).eq('id', eventId);
  }

  Future<void> forcePublishEvent(String eventId) async {
    await _client.rpc('publish_event', params: {'p_event_id': eventId});
  }
}
