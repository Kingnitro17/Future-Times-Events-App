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
    ticket_type:ticket_types!tickets_ticket_type_id_fkey(id,name,price)
  ''';

  Future<List<WalletTicket>> getMyTickets() async {
    final user = _auth.user;
    if (user == null) return const [];
    try {
      // 1. Try RPC get_my_ticket_wallet() first
      final rpcRes = await _client.rpc('get_my_ticket_wallet');
      if (rpcRes is List && rpcRes.isNotEmpty) {
        return rpcRes
            .map((row) => WalletTicket.fromSupabase(row as Map<String, dynamic>))
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

  Future<bool> hasViewableTicketForEvent(String eventId) async {
    final tickets = await getMyTickets();
    return tickets.any(
      (ticket) => ticket.eventId == eventId && ticket.isViewable,
    );
  }
}
