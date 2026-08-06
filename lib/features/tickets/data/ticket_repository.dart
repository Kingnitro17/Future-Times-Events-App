import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/supabase/supabase_service.dart';
import '../../../shared/models/models.dart';
import '../../../shared/models/enums.dart';

/// Ticket repository — claims and retrieval.
///
/// SECURITY: Raw QR tokens are generated here, hashed before DB storage,
/// and stored only in FlutterSecureStorage. The hash goes to Supabase.
class TicketRepository {
  TicketRepository();

  SupabaseClient get _client => SupabaseService.client;
  final _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  // ── Ticket Listing ─────────────────────────────────────────────────────────

  /// Fetch all tickets for the currently signed-in user.
  Future<List<Ticket>> getMyTickets() async {
    final user = SupabaseService.currentUser;
    if (user == null) throw const NotAuthenticatedFailure();

    try {
      final data = await _client
          .from('tickets')
          .select('''
            id, ticket_number, ticket_sequence, event_id, ticket_type_id,
            claim_id, user_id, attendee_name, attendee_email, attendee_phone,
            status, quantity, issued_at, checked_in_at, gate,
            cancellation_reason,
            events (
              id, title, starts_at, venue_name, city, cover_image_url
            ),
            ticket_types ( name, price )
          ''')
          .eq('user_id', user.id)
          .order('issued_at', ascending: false);

      return (data as List<dynamic>)
          .map((e) => Ticket.fromJson(e as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw ServerFailure(e.code);
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }

  /// Fetch a single ticket by ID.
  Future<Ticket?> getTicketById(String id) async {
    try {
      final data = await _client
          .from('tickets')
          .select('''
            id, ticket_number, ticket_sequence, event_id, ticket_type_id,
            claim_id, user_id, attendee_name, attendee_email, attendee_phone,
            status, quantity, issued_at, checked_in_at, gate,
            cancellation_reason,
            events (
              id, title, starts_at, ends_at, venue_name, city,
              cover_image_url, address, lat, lng
            ),
            ticket_types ( name, price )
          ''')
          .eq('id', id)
          .maybeSingle();

      if (data == null) return null;
      return Ticket.fromJson(data as Map<String, dynamic>);
    } on PostgrestException catch (e) {
      throw ServerFailure(e.code);
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }

  // ── Free Ticket Claim ──────────────────────────────────────────────────────

  /// Claim a free ticket using the claim_ticket_atomic RPC.
  ///
  /// SECURITY FLOW:
  /// 1. Generate 32 cryptographically-secure random bytes
  /// 2. SHA-256 hash the bytes → send hash to server
  /// 3. Server inserts ticket with qr_token_hash
  /// 4. Store raw token in secure storage keyed by ticket_id
  Future<({String ticketId, String ticketNumber, String rawToken})>
      claimFreeTicket({
    required String eventId,
    required String ticketTypeId,
    required String attendeeName,
    required String attendeeEmail,
    String? attendeePhone,
  }) async {
    final user = SupabaseService.currentUser;
    if (user == null) throw const NotAuthenticatedFailure();

    // 1. Generate secure random token
    final rawToken = _generateSecureToken();
    final tokenHash = _sha256Hash(rawToken);

    // 2. Generate ticket number (server may override this)
    final ticketNumber = _generateTicketNumber();

    // 3. Call atomic claim RPC
    try {
      final result = await _client.rpc('claim_ticket_atomic', params: {
        'p_event_id': eventId,
        'p_ticket_type_id': ticketTypeId,
        'p_attendee_name': attendeeName,
        'p_attendee_email': attendeeEmail,
        if (attendeePhone != null) 'p_attendee_phone': attendeePhone,
        'p_qr_token_hash': tokenHash,
        'p_ticket_number': ticketNumber,
        'p_idempotency_key':
            '${user.id}-${ticketTypeId}-${DateTime.now().millisecondsSinceEpoch}',
      });

      if (result == null || result is! Map<String, dynamic>) {
        throw const ServerFailure('claim_null_response');
      }

      final rpcResult = result as Map<String, dynamic>;

      if (rpcResult['result'] == 'duplicate') {
        throw const DuplicateClaimFailure();
      }
      if (rpcResult['result'] == 'sold_out') {
        throw const TicketSoldOutFailure();
      }
      if (rpcResult['result'] == 'limit_exceeded') {
        throw const TicketLimitExceededFailure();
      }
      if (rpcResult['result'] == 'sales_closed') {
        throw const TicketSalesClosedFailure();
      }
      if (rpcResult['result'] != 'success') {
        throw ServerFailure(rpcResult['result'] as String?);
      }

      final ticketId = rpcResult['ticket_id'] as String? ?? '';
      final confirmedNumber =
          rpcResult['ticket_number'] as String? ?? ticketNumber;

      // 4. Store raw token in secure storage (NEVER in regular prefs)
      await _storeRawToken(ticketId, rawToken);

      return (
        ticketId: ticketId,
        ticketNumber: confirmedNumber,
        rawToken: rawToken,
      );
    } on AppFailure {
      rethrow;
    } on PostgrestException catch (e) {
      throw ServerFailure(e.code);
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }

  // ── QR Token Management ────────────────────────────────────────────────────

  /// Retrieve the raw QR token for a ticket from secure storage.
  /// Returns null if not found (ticket from another device).
  Future<String?> getRawToken(String ticketId) async {
    return _storage.read(key: _tokenKey(ticketId));
  }

  /// Store raw token in secure storage. Called after successful claim.
  Future<void> _storeRawToken(String ticketId, String rawToken) async {
    await _storage.write(key: _tokenKey(ticketId), value: rawToken);
  }

  /// Delete token (e.g. after cancellation).
  Future<void> deleteRawToken(String ticketId) async {
    await _storage.delete(key: _tokenKey(ticketId));
  }

  // ── Utilities ─────────────────────────────────────────────────────────────

  String _tokenKey(String ticketId) => 'qr_token_$ticketId';

  /// Generate 32 cryptographically-secure random bytes, base64url-encoded.
  String _generateSecureToken() {
    final rng = Random.secure();
    final bytes = Uint8List.fromList(
      List.generate(32, (_) => rng.nextInt(256)),
    );
    return base64Url.encode(bytes).replaceAll('=', '');
  }

  /// Compute SHA-256 hash of a string, hex-encoded.
  String _sha256Hash(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Generate a draft ticket number (server may override with sequential number).
  String _generateTicketNumber() {
    final now = DateTime.now();
    return 'FT-${now.year.toString().substring(2)}'
        '${now.month.toString().padLeft(2, '0')}'
        '-${Random.secure().nextInt(999999).toString().padLeft(6, '0')}';
  }
}
