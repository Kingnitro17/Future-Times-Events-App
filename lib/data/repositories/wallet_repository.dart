import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/wallet_item.dart';
import '../models/payment_transaction.dart';
import 'auth_repository.dart';
import 'payment_repository.dart';
import 'ticket_repository.dart';

class WalletRepository {
  WalletRepository({
    required AuthRepository authRepository,
    required TicketRepository ticketRepository,
    required PaymentRepository paymentRepository,
    SupabaseClient? client,
  })  : _auth = authRepository,
        _tickets = ticketRepository,
        _payments = paymentRepository,
        _client = client ?? Supabase.instance.client;

  final AuthRepository _auth;
  final TicketRepository _tickets;
  final PaymentRepository _payments;
  final SupabaseClient _client;

  Future<List<WalletItem>> getFeed({int limit = 50}) async {
    final tickets = await _tickets.getMyTickets();
    final payments = await _payments.getMyTransactions(limit: 20);
    final items = <WalletItem>[
      ...tickets.map(WalletItem.fromTicket),
      ...payments
          .where((payment) => payment.status == PaymentStatus.paid)
          .map(WalletItem.fromPayment),
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
            );
        channel?.subscribe();
      },
      onCancel: cancel,
    );
    return controller.stream;
  }
}
