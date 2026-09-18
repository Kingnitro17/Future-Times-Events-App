import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/menu_item.dart';
import '../models/table_reservation.dart';
import '../models/venue_order.dart';
import '../models/venue_table.dart';

class VenueCommerceRepository {
  VenueCommerceRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<List<VenueTable>> getEventTables(String eventId) async {
    final rows = await _client
        .from('venue_tables')
        .select()
        .eq('event_id', eventId)
        .order('name');
    return rows.map(VenueTable.fromSupabase).toList(growable: false);
  }

  Future<void> upsertTable(Map<String, dynamic> data) async {
    final payload = Map<String, dynamic>.from(data);
    final currentUserId = _client.auth.currentUser?.id;
    if ((payload['venue_id'] == null ||
            payload['venue_id'].toString().isEmpty) &&
        currentUserId != null) {
      payload['venue_id'] = currentUserId;
    }
    if (payload['id'] != null && payload['id'].toString().isNotEmpty) {
      await _client.from('venue_tables').upsert(payload, onConflict: 'id');
    } else {
      await _client.from('venue_tables').insert(payload);
    }
  }

  Future<void> deleteTable(String tableId) async {
    await _client.from('venue_tables').delete().eq('id', tableId);
  }

  Future<List<MenuItem>> getEventMenu(String eventId) async {
    final rows = await _client
        .from('menu_items')
        .select()
        .eq('event_id', eventId)
        .order('name');
    return rows.map(MenuItem.fromSupabase).toList(growable: false);
  }

  Future<void> upsertMenuItem(Map<String, dynamic> data) async {
    final payload = Map<String, dynamic>.from(data);
    final currentUserId = _client.auth.currentUser?.id;
    if ((payload['venue_id'] == null ||
            payload['venue_id'].toString().isEmpty) &&
        currentUserId != null) {
      payload['venue_id'] = currentUserId;
    }
    if (payload['id'] != null && payload['id'].toString().isNotEmpty) {
      await _client.from('menu_items').upsert(payload, onConflict: 'id');
    } else {
      await _client.from('menu_items').insert(payload);
    }
  }

  Future<void> deleteMenuItem(String menuItemId) async {
    await _client.from('menu_items').delete().eq('id', menuItemId);
  }

  Future<List<VenueOrder>> getEventOrders(
    String eventId, {
    String? statusFilter,
  }) async {
    var query = _client
        .from('venue_orders')
        .select('*, items:venue_order_items(*)')
        .eq('event_id', eventId);
    if (statusFilter != null && statusFilter.isNotEmpty) {
      query = query.eq('status', statusFilter);
    }
    final rows = await query.order('created_at', ascending: false);
    return rows.map(VenueOrder.fromSupabase).toList(growable: false);
  }

  Future<void> updateOrderStatus(String orderId, String status) async {
    await _client.rpc('update_order_status', params: {
      'p_order_id': orderId,
      'p_status': status,
    });
  }

  Stream<List<VenueOrder>> watchEventOrders(String eventId) {
    late StreamController<List<VenueOrder>> controller;
    RealtimeChannel? channel;
    var disposed = false;

    Future<void> refresh() async {
      try {
        final orders = await getEventOrders(eventId);
        if (!disposed && !controller.isClosed) controller.add(orders);
      } catch (error, stackTrace) {
        if (!disposed && !controller.isClosed) {
          controller.addError(error, stackTrace);
        }
      }
    }

    controller = StreamController<List<VenueOrder>>(
      onListen: () {
        refresh();
        channel =
            _client.channel('public:venue_orders:$eventId').onPostgresChanges(
                  event: PostgresChangeEvent.all,
                  schema: 'public',
                  table: 'venue_orders',
                  filter: PostgresChangeFilter(
                    type: PostgresChangeFilterType.eq,
                    column: 'event_id',
                    value: eventId,
                  ),
                  callback: (_) => refresh(),
                );
        channel?.subscribe();
      },
      onCancel: () async {
        disposed = true;
        if (channel != null) await _client.removeChannel(channel!);
      },
    );
    return controller.stream;
  }

  Future<List<VenueTable>> getAvailableTables(String eventId) async {
    final rows = await _client
        .from('venue_tables')
        .select()
        .eq('event_id', eventId)
        .eq('status', 'available')
        .order('name');
    return rows.map(VenueTable.fromSupabase).toList(growable: false);
  }

  Stream<List<VenueTable>> watchAvailableTables(String eventId) {
    late StreamController<List<VenueTable>> controller;
    RealtimeChannel? channel;
    var disposed = false;

    Future<void> refresh() async {
      try {
        final tables = await getEventTables(eventId);
        if (!disposed && !controller.isClosed) controller.add(tables);
      } catch (error, stackTrace) {
        if (!disposed && !controller.isClosed) {
          controller.addError(error, stackTrace);
        }
      }
    }

    controller = StreamController<List<VenueTable>>(
      onListen: () {
        refresh();
        channel =
            _client.channel('public:venue_tables:$eventId').onPostgresChanges(
                  event: PostgresChangeEvent.all,
                  schema: 'public',
                  table: 'venue_tables',
                  filter: PostgresChangeFilter(
                    type: PostgresChangeFilterType.eq,
                    column: 'event_id',
                    value: eventId,
                  ),
                  callback: (_) => refresh(),
                );
        channel?.subscribe();
      },
      onCancel: () async {
        disposed = true;
        if (channel != null) await _client.removeChannel(channel!);
      },
    );
    return controller.stream;
  }

  Future<List<MenuItem>> getMenu(String eventId, {String? category}) async {
    var query = _client.from('menu_items').select().eq('event_id', eventId);
    if (category != null && category.isNotEmpty) {
      query = query.eq('category', category);
    }
    final rows = await query.order('name');
    return rows.map(MenuItem.fromSupabase).toList(growable: false);
  }

  Future<String> reserveTable({
    required String tableId,
    required int partySize,
    String? paymentTransactionId,
  }) async {
    final result = await _client.rpc('reserve_table', params: {
      'p_table_id': tableId,
      'p_party_size': partySize,
      'p_payment_transaction_id': paymentTransactionId,
    });
    if (result is Map) {
      return result['reservation_id']?.toString() ??
          result['id']?.toString() ??
          '';
    }
    return result?.toString() ?? '';
  }

  Future<String> placeOrder({
    required String eventId,
    required List<Map<String, dynamic>> items,
    String? tableReservationId,
    String? paymentTransactionId,
    String? note,
  }) async {
    final result = await _client.rpc('place_venue_order', params: {
      'p_event_id': eventId,
      'p_items': items,
      'p_table_reservation_id': tableReservationId,
      'p_payment_transaction_id': paymentTransactionId,
      'p_note': note,
    });
    if (result is Map) {
      return result['order_id']?.toString() ?? result['id']?.toString() ?? '';
    }
    return result?.toString() ?? '';
  }

  Future<TableReservation?> getMyReservation(String reservationId) async {
    final row = await _client
        .from('table_reservations')
        .select('*, tables:table_id(name), events:event_id(title, starts_at)')
        .eq('id', reservationId)
        .maybeSingle();
    return row == null ? null : TableReservation.fromSupabase(row);
  }

  Future<VenueOrder?> getOrder(String orderId) async {
    final row = await _client
        .from('venue_orders')
        .select(
            '*, items:venue_order_items(*) , events:event_id(title, starts_at)')
        .eq('id', orderId)
        .maybeSingle();
    return row == null ? null : VenueOrder.fromSupabase(row);
  }

  Future<List<TableReservation>> getMyReservations({int limit = 20}) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return const [];
    final rows = await _client
        .from('table_reservations')
        .select('*, tables:table_id(name), events:event_id(title, starts_at)')
        .eq('user_id', userId)
        .order('reserved_at', ascending: false)
        .limit(limit);
    return rows.map(TableReservation.fromSupabase).toList(growable: false);
  }

  Future<List<VenueOrder>> getMyOrders({int limit = 20}) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return const [];
    final rows = await _client
        .from('venue_orders')
        .select(
            '*, items:venue_order_items(*), events:event_id(title, starts_at)')
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(limit);
    return rows.map(VenueOrder.fromSupabase).toList(growable: false);
  }

  Stream<TableReservation> watchReservation(String reservationId) {
    late StreamController<TableReservation> controller;
    RealtimeChannel? channel;
    var disposed = false;

    Future<void> refresh() async {
      try {
        final reservation = await getMyReservation(reservationId);
        if (reservation != null && !disposed && !controller.isClosed) {
          controller.add(reservation);
        }
      } catch (error, stackTrace) {
        if (!disposed && !controller.isClosed) {
          controller.addError(error, stackTrace);
        }
      }
    }

    controller = StreamController<TableReservation>(
      onListen: () {
        refresh();
        channel = _client
            .channel('public:table_reservations:$reservationId')
            .onPostgresChanges(
              event: PostgresChangeEvent.all,
              schema: 'public',
              table: 'table_reservations',
              filter: PostgresChangeFilter(
                type: PostgresChangeFilterType.eq,
                column: 'id',
                value: reservationId,
              ),
              callback: (_) => refresh(),
            );
        channel?.subscribe();
      },
      onCancel: () async {
        disposed = true;
        if (channel != null) await _client.removeChannel(channel!);
      },
    );
    return controller.stream;
  }

  Stream<VenueOrder> watchOrder(String orderId) {
    late StreamController<VenueOrder> controller;
    RealtimeChannel? channel;
    var disposed = false;

    Future<void> refresh() async {
      try {
        final order = await getOrder(orderId);
        if (order != null && !disposed && !controller.isClosed) {
          controller.add(order);
        }
      } catch (error, stackTrace) {
        if (!disposed && !controller.isClosed) {
          controller.addError(error, stackTrace);
        }
      }
    }

    controller = StreamController<VenueOrder>(
      onListen: () {
        refresh();
        channel =
            _client.channel('public:venue_orders:$orderId').onPostgresChanges(
                  event: PostgresChangeEvent.all,
                  schema: 'public',
                  table: 'venue_orders',
                  filter: PostgresChangeFilter(
                    type: PostgresChangeFilterType.eq,
                    column: 'id',
                    value: orderId,
                  ),
                  callback: (_) => refresh(),
                );
        channel?.subscribe();
      },
      onCancel: () async {
        disposed = true;
        if (channel != null) await _client.removeChannel(channel!);
      },
    );
    return controller.stream;
  }

  /// Every reservation for an event. Staff-facing, so it relies on the owner
  /// read policy instead of filtering by the signed-in user.
  Future<List<TableReservation>> getEventReservations(
    String eventId, {
    String? statusFilter,
  }) async {
    var query = _client
        .from('table_reservations')
        .select('*, tables:table_id(name)')
        .eq('event_id', eventId);
    if (statusFilter != null && statusFilter.isNotEmpty) {
      query = query.eq('status', statusFilter);
    }
    final rows = await query.order('reserved_at', ascending: true);
    return rows.map(TableReservation.fromSupabase).toList(growable: false);
  }

  /// Live staff view of every reservation for an event.
  Stream<List<TableReservation>> watchEventReservations(String eventId) {
    late StreamController<List<TableReservation>> controller;
    RealtimeChannel? channel;
    var disposed = false;

    Future<void> refresh() async {
      try {
        final reservations = await getEventReservations(eventId);
        if (!disposed && !controller.isClosed) controller.add(reservations);
      } catch (error, stackTrace) {
        if (!disposed && !controller.isClosed) {
          controller.addError(error, stackTrace);
        }
      }
    }

    controller = StreamController<List<TableReservation>>(
      onListen: () {
        refresh();
        channel = _client
            .channel('public:event_reservations:$eventId')
            .onPostgresChanges(
              event: PostgresChangeEvent.all,
              schema: 'public',
              table: 'table_reservations',
              filter: PostgresChangeFilter(
                type: PostgresChangeFilterType.eq,
                column: 'event_id',
                value: eventId,
              ),
              callback: (_) => refresh(),
            );
        channel?.subscribe();
      },
      onCancel: () async {
        disposed = true;
        if (channel != null) await _client.removeChannel(channel!);
      },
    );
    return controller.stream;
  }

  /// Guest display names for a set of user ids. Mirrors the profiles lookup in
  /// OrganizerRepository.getEventAttendees. A failed lookup degrades to an
  /// empty map so the fulfillment board still renders.
  Future<Map<String, String>> getGuestNames(Iterable<String> userIds) async {
    final ids = userIds.where((id) => id.trim().isNotEmpty).toSet().toList();
    if (ids.isEmpty) return const <String, String>{};
    try {
      final rows = await _client
          .from('profiles')
          .select('id,display_name,email')
          .inFilter('id', ids);
      return {
        for (final row in rows.cast<Map<String, dynamic>>())
          row['id'].toString(): _displayName(row),
      };
    } catch (error) {
      if (kDebugMode) debugPrint('[venue] guest lookup failed: $error');
      return const <String, String>{};
    }
  }

  static String _displayName(Map<String, dynamic> row) {
    final name = row['display_name']?.toString().trim() ?? '';
    if (name.isNotEmpty) return name;
    final email = row['email']?.toString().trim() ?? '';
    return email.isEmpty ? 'Guest' : email;
  }

  /// Seats a party: the reservation moves to 'used' and its table to
  /// 'occupied'. There is no seating RPC yet, so the two writes run in order.
  Future<void> seatReservation({
    required String reservationId,
    required String tableId,
  }) async {
    await _client
        .from('table_reservations')
        .update({'status': 'used'}).eq('id', reservationId);
    await _client
        .from('venue_tables')
        .update({'status': 'occupied'}).eq('id', tableId);
  }

  /// Frees a table for the next party. The reservation keeps its 'used' history.
  Future<void> freeTable(String tableId) async {
    await _client
        .from('venue_tables')
        .update({'status': 'available'}).eq('id', tableId);
  }

  Future<TableReservation?> getReservationByQr(String qrCode) async {
    final clean = qrCode.trim();
    if (clean.isEmpty) return null;
    final row = await _client
        .from('table_reservations')
        .select('*, tables:table_id(name)')
        .eq('qr_code', clean)
        .maybeSingle();
    return row == null ? null : TableReservation.fromSupabase(row);
  }

  Future<VenueOrder?> getOrderByQr(String qrCode) async {
    final clean = qrCode.trim();
    if (clean.isEmpty) return null;
    final row = await _client
        .from('venue_orders')
        .select('*, items:venue_order_items(*)')
        .eq('qr_code', clean)
        .maybeSingle();
    return row == null ? null : VenueOrder.fromSupabase(row);
  }
}
