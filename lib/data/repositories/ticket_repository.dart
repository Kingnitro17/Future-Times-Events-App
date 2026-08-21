import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/errors/app_failure.dart';
import '../models/wallet_ticket.dart';
import 'auth_repository.dart';

class TicketRepository {
  TicketRepository(
      {required AuthRepository authRepository, SupabaseClient? client})
      : _auth = authRepository,
        _client = client ?? Supabase.instance.client;
  final AuthRepository _auth;
  final SupabaseClient _client;

  static const _selection = '''
    id,ticket_number,event_id,status,issued_at,checked_in_at,gate,
    attendee_name,attendee_email,
    events(id,title,slug,starts_at,date,time,venue,venue_name,address,image_url,category),
    ticket_type:ticket_types!tickets_ticket_type_id_fkey(id,name,price)
  ''';

  Future<List<WalletTicket>> getMyTickets() async {
    final user = _auth.user;
    if (user == null) return const [];
    try {
      final byId = await _client
          .from('tickets')
          .select(_selection)
          .eq('user_id', user.id)
          .order('issued_at', ascending: false);
      final byEmail = user.email == null
          ? <Map<String, dynamic>>[]
          : await _client
              .from('tickets')
              .select(_selection)
              .ilike('attendee_email', user.email!)
              .order('issued_at', ascending: false);
      final unique = <String, Map<String, dynamic>>{};
      for (final row in [...byId, ...byEmail]) {
        unique[row['id'].toString()] = row;
      }
      final tickets = unique.values.map(_map).toList()
        ..sort((a, b) => b.issuedAt.compareTo(a.issuedAt));
      return tickets;
    } on PostgrestException catch (error) {
      if (kDebugMode) debugPrint('[tickets] wallet failed: ${error.code}');
      throw const DataFailure('Your tickets could not be loaded. Try again.');
    }
  }

  WalletTicket _map(Map<String, dynamic> row) {
    final event = row['events'] as Map<String, dynamic>? ?? const {};
    final type = row['ticket_type'] as Map<String, dynamic>? ?? const {};
    final date = event['date']?.toString();
    final time = event['time']?.toString();
    final startsAt = event['starts_at']?.toString() ??
        (date == null ? null : '${date}T${time ?? '00:00:00'}');
    return WalletTicket(
      id: row['id'].toString(),
      ticketNumber: row['ticket_number']?.toString() ?? row['id'].toString(),
      eventId: row['event_id'].toString(),
      status: row['status']?.toString() ?? 'issued',
      issuedAt: DateTime.tryParse(row['issued_at']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      checkedInAt: DateTime.tryParse(row['checked_in_at']?.toString() ?? ''),
      gate: row['gate']?.toString(),
      attendeeName: row['attendee_name']?.toString() ?? 'Ticket holder',
      attendeeEmail: row['attendee_email']?.toString() ?? '',
      eventTitle: event['title']?.toString() ?? 'Event',
      eventStart: DateTime.tryParse(startsAt ?? ''),
      venue: event['venue_name']?.toString() ??
          event['venue']?.toString() ??
          'Venue TBA',
      imageUrl: event['image_url']?.toString() ?? '',
      ticketType: type['name']?.toString() ?? 'General Admission',
    );
  }
}
