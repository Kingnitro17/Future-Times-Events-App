import 'payment_transaction.dart';
import 'wallet_ticket.dart';
import '../../services/payments/payment_gateway.dart';

sealed class WalletItem {
  const WalletItem({
    required this.id,
    required this.kind,
    required this.title,
    required this.subtitle,
    required this.statusLabel,
    required this.createdAt,
    this.eventId,
    this.qrPayload,
    this.deepLink,
  });

  final String id;
  final String kind;
  final String title;
  final String subtitle;
  final String statusLabel;
  final DateTime createdAt;
  final String? eventId;
  final String? qrPayload;
  final String? deepLink;

  factory WalletItem.fromTicket(WalletTicket ticket) =
      WalletItemTicket.fromTicket;

  factory WalletItem.fromPayment(PaymentTransaction payment) =
      WalletItemPayment.fromPayment;
}

final class WalletItemTicket extends WalletItem {
  const WalletItemTicket({
    required super.id,
    required super.title,
    required super.subtitle,
    required super.statusLabel,
    required super.createdAt,
    required super.eventId,
    required super.qrPayload,
    required super.deepLink,
    required this.ticketNumber,
    required this.ticketType,
  }) : super(kind: 'ticket');

  final String ticketNumber;
  final String ticketType;

  factory WalletItemTicket.fromTicket(WalletTicket ticket) {
    return WalletItemTicket(
      id: ticket.id,
      title: ticket.eventTitle,
      subtitle: '${ticket.ticketType} · ${ticket.ticketNumber}',
      statusLabel: ticket.status.replaceAll('_', ' '),
      createdAt: ticket.issuedAt,
      eventId: ticket.eventId,
      qrPayload: ticket.effectiveQrPayload,
      deepLink: '/tickets',
      ticketNumber: ticket.ticketNumber,
      ticketType: ticket.ticketType,
    );
  }
}

final class WalletItemRide extends WalletItem {
  const WalletItemRide({
    required super.id,
    required super.title,
    required super.subtitle,
    required super.statusLabel,
    required super.createdAt,
    super.eventId,
    super.qrPayload,
    super.deepLink,
  }) : super(kind: 'ride');
}

final class WalletItemReservation extends WalletItem {
  const WalletItemReservation({
    required super.id,
    required super.title,
    required super.subtitle,
    required super.statusLabel,
    required super.createdAt,
    super.eventId,
    super.qrPayload,
    super.deepLink,
  }) : super(kind: 'reservation');
}

final class WalletItemOrder extends WalletItem {
  const WalletItemOrder({
    required super.id,
    required super.title,
    required super.subtitle,
    required super.statusLabel,
    required super.createdAt,
    super.eventId,
    super.qrPayload,
    super.deepLink,
  }) : super(kind: 'order');
}

final class WalletItemPayment extends WalletItem {
  const WalletItemPayment({
    required super.id,
    required super.title,
    required super.subtitle,
    required super.statusLabel,
    required super.createdAt,
    required super.deepLink,
    required this.amount,
    required this.currency,
    required this.gateway,
    required this.purpose,
  }) : super(kind: 'payment');

  final double amount;
  final String currency;
  final String gateway;
  final PaymentPurpose purpose;

  factory WalletItemPayment.fromPayment(PaymentTransaction payment) {
    if (payment.status != PaymentStatus.paid) {
      throw StateError('Only paid transactions can be added to the wallet.');
    }
    return WalletItemPayment(
      id: payment.id,
      title: _purposeTitle(payment.purpose),
      subtitle: '${payment.currency} ${payment.amount.toStringAsFixed(2)}',
      statusLabel: 'Paid',
      createdAt: payment.createdAt,
      deepLink: '/payments/${payment.id}',
      amount: payment.amount,
      currency: payment.currency,
      gateway: payment.gateway,
      purpose: payment.purpose,
    );
  }

  static String _purposeTitle(PaymentPurpose purpose) => switch (purpose) {
        PaymentPurpose.ticket => 'Ticket payment',
        PaymentPurpose.table => 'Table payment',
        PaymentPurpose.order => 'Order payment',
      };
}
