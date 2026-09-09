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
    id,ticket_id,ticket_number,event_id,status,issued_at,purchased_at,
    checked_in_at,gate,qr_code,
    attendee_name,attendee_email,
    events(id,title,slug,starts_at,date,time,venue,venue_name,address,image_url,category),
    ticket_type:ticket_types(id,name,price)
  ''';

  /// Load user's ticket wallet
  Future<List<WalletTicket>> getMyTickets() async {
    final user = _auth.user;
    if (user == null) return const [];
    try {
      // 1. Try RPC get_my_ticket_wallet() first
      final rpcRes = await _client.rpc('get_my_ticket_wallet');
      if (rpcRes is List) {
        return rpcRes
            .map(
                (row) => WalletTicket.fromSupabase(row as Map<String, dynamic>))
            .toList()
          ..sort((a, b) => b.issuedAt.compareTo(a.issuedAt));
      }
    } catch (error) {
      if (kDebugMode) {
        debugPrint('[tickets] get_my_ticket_wallet RPC fallback: $error');
      }
    }

    // 2. Direct query fallback
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
      final tickets = unique.values.map(WalletTicket.fromSupabase).toList()
        ..sort((a, b) => b.issuedAt.compareTo(a.issuedAt));
      return tickets;
    } on PostgrestException catch (error) {
      if (kDebugMode) debugPrint('[tickets] wallet failed: ${error.code}');
      throw const DataFailure('Your tickets could not be loaded. Try again.');
    }
  }

  /// Check if user has an active viewable ticket for this event
  Future<bool> hasViewableTicketForEvent(String eventId) async {
    final tickets = await getMyTickets();
    return tickets.any(
      (ticket) => ticket.eventId == eventId && ticket.isViewable,
    );
  }

  /// Claim a free ticket in-app
  Future<WalletTicket> claimFreeTicket({
    required String eventId,
    required String ticketTypeId,
    required String attendeeName,
    required String attendeeEmail,
    String? attendeePhone,
  }) async {
    final user = _auth.user;
    if (user == null) {
      throw const AuthFailure('Sign in is required to claim a ticket.');
    }

    final name = attendeeName.trim().isNotEmpty
        ? attendeeName.trim()
        : (_auth.profile?['display_name']?.toString() ??
            user.email?.split('@').first ??
            'Attendee');
    final email = attendeeEmail.trim().isNotEmpty
        ? attendeeEmail.trim()
        : (user.email ?? '');

    // 1. Try atomic claim_free_ticket RPC first
    try {
      final res = await _client.rpc('claim_free_ticket', params: {
        'p_event_id': eventId,
        'p_ticket_type_id': ticketTypeId,
        'p_attendee_name': name,
        'p_attendee_email': email,
        if (attendeePhone != null && attendeePhone.trim().isNotEmpty)
          'p_attendee_phone': attendeePhone.trim(),
      });

      if (res is Map<String, dynamic> && res['success'] == true) {
        final tickets = await getMyTickets();
        final matched = tickets.where((t) => t.eventId == eventId).toList();
        if (matched.isNotEmpty) return matched.first;

        return WalletTicket(
          id: res['ticket_id']?.toString() ?? '',
          ticketNumber: res['ticket_number']?.toString() ?? '',
          eventId: eventId,
          status: res['status']?.toString() ?? 'issued',
          issuedAt: DateTime.tryParse(res['issued_at']?.toString() ?? '') ??
              DateTime.now(),
          attendeeName: name,
          attendeeEmail: email,
          eventTitle: 'Event',
          eventStart: null,
          venue: 'Venue TBA',
          imageUrl: '',
          ticketType: 'General Admission',
          qrPayload: res['qr_code']?.toString(),
        );
      }
    } on PostgrestException catch (e) {
      if (kDebugMode) {
        debugPrint('[tickets] claim_free_ticket RPC error: ${e.message}');
      }
      if (e.message.toLowerCase().contains('sold out')) {
        throw const DataFailure('This ticket type is currently sold out.');
      }
      if (e.message.toLowerCase().contains('already')) {
        final tickets = await getMyTickets();
        final matched = tickets.where((t) => t.eventId == eventId).toList();
        if (matched.isNotEmpty) return matched.first;
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[tickets] claim RPC general error: $e');
    }

    // 2. Direct table insert fallback
    try {
      final now = DateTime.now();
      final ticketNumber =
          'FT-${now.year.toString().substring(2)}${now.month.toString().padLeft(2, '0')}-${now.millisecondsSinceEpoch.toString().substring(7)}';
      final qrPayload =
          'FTE-TKT-${now.millisecondsSinceEpoch}-${user.id.replaceAll('-', '').substring(0, 6)}';

      final inserted = await _client.from('tickets').insert({
        'ticket_number': ticketNumber,
        'ticket_id': ticketNumber,
        'event_id': eventId,
        'ticket_type_id': ticketTypeId,
        'user_id': user.id,
        'attendee_name': name,
        'attendee_email': email,
        if (attendeePhone != null && attendeePhone.trim().isNotEmpty)
          'attendee_phone': attendeePhone.trim(),
        'status': 'issued',
        'issued_at': now.toIso8601String(),
        'purchased_at': now.toIso8601String(),
        'qr_code': qrPayload,
      }).select().single();

      // Automatically register RSVP
      try {
        await _client.from('rsvps').upsert({
          'event_id': eventId,
          'user_id': user.id,
          'status': 'going',
          'is_public': true,
        }, onConflict: 'event_id,user_id');
      } catch (_) {}

      final tickets = await getMyTickets();
      final matched =
          tickets.where((t) => t.id == inserted['id'].toString()).toList();
      if (matched.isNotEmpty) return matched.first;

      return WalletTicket.fromSupabase(inserted);
    } on PostgrestException catch (e) {
      if (kDebugMode) {
        debugPrint('[tickets] direct insert failed: ${e.code} ${e.message}');
      }
      throw DataFailure(e.message.isNotEmpty
          ? e.message
          : 'Could not complete your ticket claim. Please try again.');
    } catch (e) {
      throw const DataFailure(
          'Could not claim your ticket. Check your connection and try again.');
    }
  }

  /// Validate and check-in a ticket via QR code or reference
  Future<Map<String, dynamic>> validateAndCheckInTicket({
    required String qrPayload,
    String? gate,
  }) async {
    final clean = qrPayload.trim();
    if (clean.isEmpty) {
      return {'valid': false, 'message': 'Empty QR payload.'};
    }

    // 1. Try server-side validation RPC
    try {
      final res = await _client.rpc('validate_and_check_in_ticket', params: {
        'p_qr_payload': clean,
        'p_gate': gate ?? 'Main Gate',
      });
      if (res is Map<String, dynamic>) {
        return res;
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[tickets] validate RPC fallback: $e');
    }

    // 2. Direct table fallback for verification
    try {
      final row = await _client
          .from('tickets')
          .select(
              'id, ticket_number, status, attendee_name, checked_in_at, event_id')
          .or('qr_code.eq.$clean,ticket_number.eq.$clean,id.eq.$clean')
          .maybeSingle();

      if (row == null) {
        return {'valid': false, 'message': 'Ticket not found.'};
      }

      final status = row['status']?.toString();
      if (status == 'cancelled' || status == 'revoked') {
        return {'valid': false, 'message': 'This ticket is $status.'};
      }
      if (status == 'checked_in') {
        return {
          'valid': false,
          'already_checked_in': true,
          'message': 'Ticket was already checked in at ${row['checked_in_at']}.',
        };
      }

      final checkInTime = DateTime.now().toIso8601String();
      final effectiveGate = gate ?? 'Main Gate';
      await _client.from('tickets').update({
        'status': 'checked_in',
        'checked_in_at': checkInTime,
        'gate': effectiveGate,
      }).eq('id', row['id']);

      return {
        'valid': true,
        'status': 'checked_in',
        'message': 'Check-in successful! Welcome, ${row['attendee_name']}.',
        'ticket_number': row['ticket_number'],
        'attendee_name': row['attendee_name'],
        'checked_in_at': checkInTime,
        'gate': effectiveGate,
      };
    } catch (e) {
      return {
        'valid': false,
        'message': 'Verification could not be completed. Check connection.'
      };
    }
  }
}
