import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/wallet_item.dart';
import '../models/payment_transaction.dart';
import '../../services/payments/payment_gateway.dart';
import 'ft_services_repository.dart';
import 'auth_repository.dart';
import 'payment_repository.dart';
import 'ride_repository.dart';
import 'ticket_repository.dart';
import 'venue_commerce_repository.dart';
import 'product_repository.dart';

class WalletRepository {
  WalletRepository({
    required AuthRepository authRepository,
    required TicketRepository ticketRepository,
    required PaymentRepository paymentRepository,
    required RideRepository rideRepository,
    required VenueCommerceRepository venueCommerceRepository,
    FtServicesRepository? ftServicesRepository,
    ProductRepository? productRepository,
    SupabaseClient? client,
  })  : _auth = authRepository,
        _tickets = ticketRepository,
        _payments = paymentRepository,
        _rides = rideRepository,
        _venueCommerce = venueCommerceRepository,
        _ftServices =
            ftServicesRepository ?? FtServicesRepository(client: client),
        _products = productRepository ?? ProductRepository(client: client),
        _client = client ?? Supabase.instance.client;

  final AuthRepository _auth;
  final TicketRepository _tickets;
  final PaymentRepository _payments;
  final RideRepository _rides;
  final VenueCommerceRepository _venueCommerce;
  final ProductRepository _products;
  final FtServicesRepository _ftServices;
  final SupabaseClient _client;

  Future<List<WalletItem>> getFeed({int limit = 50}) async {
    final tickets = await _tickets.getMyTickets();
    final payments = await _payments.getMyTransactions(limit: 20);
    final rides = await _rides.getMyRides(limit: 20);
    final reservations = await _venueCommerce.getMyReservations(limit: 20);
    final orders = await _venueCommerce.getMyOrders(limit: 20);
    final serviceBookings = await _ftServices.myBookings(limit: 30);
    final preorders = await _products.getMyPreorders(limit: 50);
    final ticketImagesByEvent = <String, String>{
      for (final ticket in tickets)
        if (ticket.imageUrl.trim().isNotEmpty)
          ticket.eventId: ticket.imageUrl,
    };
    String? paymentImage(PaymentTransaction payment) {
      final eventId = switch (payment.purpose) {
        PaymentPurpose.ticket =>
          payment.metadata['event_id']?.toString() ??
              tickets
                  .where((ticket) =>
                      ticket.id == payment.relatedEntityId ||
                      ticket.eventId == payment.relatedEntityId)
                  .firstOrNull
                  ?.eventId,
        PaymentPurpose.table => reservations
            .where((reservation) =>
                reservation.tableId == payment.relatedEntityId ||
                reservation.id == payment.relatedEntityId)
            .firstOrNull
            ?.eventId,
        PaymentPurpose.order => orders
            .where((order) =>
                order.eventId == payment.relatedEntityId ||
                order.id == payment.relatedEntityId)
            .firstOrNull
            ?.eventId,
        PaymentPurpose.service =>
          payment.metadata['event_id']?.toString(),
      };
      return ticketImagesByEvent[eventId];
    }

    String paymentTitle(PaymentTransaction payment) {
      switch (payment.purpose) {
        case PaymentPurpose.ticket:
          final ticket = tickets
              .where((ticket) =>
                  ticket.id == payment.relatedEntityId ||
                  ticket.eventId == payment.relatedEntityId)
              .firstOrNull;
          return ticket == null
              ? 'Ticket payment'
              : '${ticket.ticketType} — ${ticket.eventTitle}';
        case PaymentPurpose.table:
          final reservation = reservations
              .where((reservation) =>
                  reservation.tableId == payment.relatedEntityId ||
                  reservation.id == payment.relatedEntityId)
              .firstOrNull;
          return reservation == null
              ? 'Table reservation'
              : '${reservation.tableName ?? 'Table'} reservation — '
                  '${reservation.eventTitle ?? 'Event'}';
        case PaymentPurpose.order:
          final order = orders
              .where((order) =>
                  order.eventId == payment.relatedEntityId ||
                  order.id == payment.relatedEntityId)
              .firstOrNull;
          if (order == null) return 'Venue order';
          final firstItem = order.items.firstOrNull;
          final purchase = firstItem == null
              ? 'Venue order'
              : '${firstItem.quantity}x ${firstItem.itemName}';
          return '$purchase — ${order.eventTitle ?? 'Event'}';
        case PaymentPurpose.service:
          return 'Service deposit';
      }
    }

    final items = <WalletItem>[
      ...tickets.map(WalletItem.fromTicket),
      ...payments.map(
        (payment) => WalletItemPayment.fromPayment(
          payment,
          displayTitle: paymentTitle(payment),
          imageUrl: paymentImage(payment),
        ),
      ),
      ...rides.map(WalletItem.fromRide),
      ...reservations.map(WalletItem.fromReservation),
      ...orders.map(WalletItem.fromOrder),
      ...serviceBookings.map(WalletItem.fromFtService),
      ...preorders.map(WalletItem.fromPreorder),
    ]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return items.take(limit).toList(growable: false);
  }

  Stream<List<WalletItem>> watchFeed() {
    late StreamController<List<WalletItem>> controller;
    RealtimeChannel? channel;
    Timer? debounce;
    var disposed = false;

    Future<void> refresh() async {
      try {
        final feed = await getFeed();
        if (!disposed && !controller.isClosed) controller.add(feed);
      } catch (error, stackTrace) {
        if (!disposed && !controller.isClosed) {
          controller.addError(error, stackTrace);
        }
      }
    }

    void scheduleRefresh() {
      debounce?.cancel();
      debounce = Timer(const Duration(milliseconds: 500), refresh);
    }

    Future<void> cancel() async {
      disposed = true;
      debounce?.cancel();
      if (channel != null) {
        await _client.removeChannel(channel!);
        channel = null;
      }
    }

    controller = StreamController<List<WalletItem>>(
      onListen: () {
        refresh();
        final userId = _auth.user?.id;
        if (userId == null) return;
        channel = _client
            .channel('public:wallet_feed:$userId')
            .onPostgresChanges(
              event: PostgresChangeEvent.all,
              schema: 'public',
              table: 'tickets',
              filter: PostgresChangeFilter(
                type: PostgresChangeFilterType.eq,
                column: 'user_id',
                value: userId,
              ),
              callback: (_) => scheduleRefresh(),
            )
            .onPostgresChanges(
              event: PostgresChangeEvent.all,
              schema: 'public',
              table: 'payment_transactions',
              filter: PostgresChangeFilter(
                type: PostgresChangeFilterType.eq,
                column: 'user_id',
                value: userId,
              ),
              callback: (_) => scheduleRefresh(),
            )
            .onPostgresChanges(
              event: PostgresChangeEvent.all,
              schema: 'public',
              table: 'rides',
              filter: PostgresChangeFilter(
                type: PostgresChangeFilterType.eq,
                column: 'user_id',
                value: userId,
              ),
              callback: (_) => scheduleRefresh(),
            )
            .onPostgresChanges(
              event: PostgresChangeEvent.all,
              schema: 'public',
              table: 'table_reservations',
              filter: PostgresChangeFilter(
                type: PostgresChangeFilterType.eq,
                column: 'user_id',
                value: userId,
              ),
              callback: (_) => scheduleRefresh(),
            )
            .onPostgresChanges(
              event: PostgresChangeEvent.all,
              schema: 'public',
              table: 'venue_orders',
              filter: PostgresChangeFilter(
                type: PostgresChangeFilterType.eq,
                column: 'user_id',
                value: userId,
              ),
              callback: (_) => scheduleRefresh(),
            )
            .onPostgresChanges(
              event: PostgresChangeEvent.all,
              schema: 'public',
              table: 'ft_service_bookings',
              filter: PostgresChangeFilter(
                type: PostgresChangeFilterType.eq,
                column: 'organizer_id',
                value: userId,
              ),
              callback: (_) => scheduleRefresh(),
            )
            .onPostgresChanges(
              event: PostgresChangeEvent.all,
              schema: 'public',
              table: 'product_preorders',
              filter: PostgresChangeFilter(
                type: PostgresChangeFilterType.eq,
                column: 'user_id',
                value: userId,
              ),
              callback: (_) => scheduleRefresh(),
            );
        channel?.subscribe();
      },
      onCancel: cancel,
    );
    return controller.stream;
  }
}
