import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/ft_service.dart';
import '../models/ft_service_availability.dart';
import '../models/ft_service_booking.dart';

class FtServicesRepository {
  FtServicesRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;
  static const _bookingSelection =
      '*,service:ft_services(name,image_url),event:events(title)';

  Future<List<FtService>> listServices({String? category}) async {
    var query = _client.from('ft_services').select().eq('is_active', true);
    if (category != null && category.trim().isNotEmpty) {
      query = query.eq('category', category.trim());
    }
    final rows = await query.order('sort_order').order('name');
    return rows
        .map<FtService>((row) => FtService.fromSupabase(row))
        .toList(growable: false);
  }

  Future<Map<String, List<FtService>>> listActiveServicesGrouped() async {
    final services = await listServices();
    final grouped = <String, List<FtService>>{};
    for (final service in services) {
      grouped.putIfAbsent(service.category, () => <FtService>[]).add(service);
    }
    return Map.unmodifiable({
      for (final entry in grouped.entries)
        entry.key: List<FtService>.unmodifiable(entry.value),
    });
  }

  Future<FtService?> getService(String id) async {
    final row =
        await _client.from('ft_services').select().eq('id', id).maybeSingle();
    return row == null ? null : FtService.fromSupabase(row);
  }

  Future<FtServiceAvailability> checkAvailability({
    required String serviceId,
    required DateTime start,
    required DateTime end,
  }) async {
    final result = await _client.rpc(
      'check_service_availability',
      params: {
        'p_service_id': serviceId,
        'p_start_time': start.toUtc().toIso8601String(),
        'p_end_time': end.toUtc().toIso8601String(),
      },
    );
    return FtServiceAvailability.fromSupabase(result);
  }

  Future<String> requestBooking({
    required String serviceId,
    required String eventId,
    required int quantity,
    required DateTime start,
    required DateTime end,
    String? notes,
  }) async {
    final result = await _client.rpc(
      'request_service_booking',
      params: {
        'p_service_id': serviceId,
        'p_event_id': eventId,
        'p_quantity': quantity,
        'p_start_time': start.toUtc().toIso8601String(),
        'p_end_time': end.toUtc().toIso8601String(),
        'p_notes': notes,
      },
    );
    if (result == null || result.toString().isEmpty) {
      throw StateError('Booking request did not return a booking id.');
    }
    return result.toString();
  }

  Future<String> confirmBooking({
    required String bookingId,
    required String paymentTransactionId,
  }) async {
    final result = await _client.rpc(
      'confirm_service_booking',
      params: {
        'p_booking_id': bookingId,
        'p_payment_transaction_id': paymentTransactionId,
      },
    );
    if (result == null || result.toString().isEmpty) {
      throw StateError(
          'Booking confirmation failed due to an inventory conflict.');
    }
    return result.toString();
  }

  Future<List<FtServiceBooking>> myBookings({int limit = 30}) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return const [];
    final rows = await _client
        .from('ft_service_bookings')
        .select(_bookingSelection)
        .eq('organizer_id', userId)
        .order('created_at', ascending: false)
        .limit(limit);
    return rows
        .map<FtServiceBooking>((row) => FtServiceBooking.fromSupabase(row))
        .toList(growable: false);
  }

  Future<FtServiceBooking?> getBooking(String id) async {
    final row = await _client
        .from('ft_service_bookings')
        .select(_bookingSelection)
        .eq('id', id)
        .maybeSingle();
    return row == null ? null : FtServiceBooking.fromSupabase(row);
  }

  Stream<List<FtServiceBooking>> watchMyBookings() {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return Stream.value(const []);
    return _watchBookings(
      channelName: 'public:ft_service_bookings:organizer:$userId',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'organizer_id',
        value: userId,
      ),
      load: myBookings,
    );
  }

  Future<List<FtServiceBooking>> adminPendingReview() async {
    final rows = await _client
        .from('ft_service_bookings')
        .select(_bookingSelection)
        .eq('status', 'pending_review')
        .order('created_at', ascending: true);
    return rows
        .map<FtServiceBooking>((row) => FtServiceBooking.fromSupabase(row))
        .toList(growable: false);
  }

  Future<void> adminReview({
    required String bookingId,
    required String decision,
    String? reason,
  }) async {
    if (decision != 'approve' && decision != 'reject') {
      throw ArgumentError.value(decision, 'decision', 'Use approve or reject.');
    }
    await _client.rpc(
      'admin_review_service_booking',
      params: {
        'p_booking_id': bookingId,
        'p_decision': decision,
        'p_reason': reason,
      },
    );
  }

  Stream<List<FtServiceBooking>> watchAdminPending() => _watchBookings(
        channelName: 'public:ft_service_bookings:admin_pending',
        load: adminPendingReview,
      );

  Stream<List<FtServiceBooking>> _watchBookings({
    required String channelName,
    required Future<List<FtServiceBooking>> Function() load,
    PostgresChangeFilter? filter,
  }) {
    late final StreamController<List<FtServiceBooking>> controller;
    RealtimeChannel? channel;
    var closed = false;

    Future<void> refresh() async {
      try {
        final bookings = await load();
        if (!closed && !controller.isClosed) controller.add(bookings);
      } catch (error, stackTrace) {
        if (!closed && !controller.isClosed) {
          controller.addError(error, stackTrace);
        }
      }
    }

    controller = StreamController<List<FtServiceBooking>>(
      onListen: () {
        refresh();
        channel = _client.channel(channelName).onPostgresChanges(
              event: PostgresChangeEvent.all,
              schema: 'public',
              table: 'ft_service_bookings',
              filter: filter,
              callback: (_) => refresh(),
            )..subscribe();
      },
      onCancel: () async {
        closed = true;
        if (channel != null) await _client.removeChannel(channel!);
      },
    );
    return controller.stream;
  }
}
