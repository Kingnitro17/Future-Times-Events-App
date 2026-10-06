import 'payment_transaction.dart';
import 'venue_order.dart';
import 'wallet_ticket.dart';
import 'ride.dart';
import 'table_reservation.dart';
import '../../core/geo/geo_point.dart';
import '../../services/payments/payment_gateway.dart';
import 'ft_service_booking.dart';
import 'organizer_product.dart';

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

  factory WalletItem.fromRide(RideBooking ride) = WalletItemRide.fromRide;

  factory WalletItem.fromReservation(TableReservation reservation) =
      WalletItemReservation.fromReservation;

  factory WalletItem.fromOrder(VenueOrder order) = WalletItemOrder.fromOrder;

  factory WalletItem.fromFtService(FtServiceBooking booking) =
      WalletItemFtService.fromBooking;

  factory WalletItem.fromPreorder(ProductPreorder preorder) =
      WalletItemPreorder.fromPreorder;
}

final class WalletItemPreorder extends WalletItem {
  const WalletItemPreorder({
    required super.id,
    required super.title,
    required super.subtitle,
    required super.statusLabel,
    required super.createdAt,
    required super.eventId,
    required this.quantity,
    required this.unitPrice,
    required this.currency,
  }) : super(kind: 'preorder', deepLink: '/wallet');

  final int quantity;
  final double unitPrice;
  final String currency;

  factory WalletItemPreorder.fromPreorder(ProductPreorder preorder) =>
      WalletItemPreorder(
        id: preorder.id,
        title: preorder.productName,
        subtitle:
            '${preorder.quantity} ${preorder.quantity == 1 ? 'item' : 'items'}',
        statusLabel: preorder.status.replaceAll('_', ' '),
        createdAt: preorder.createdAt,
        eventId: preorder.eventId,
        quantity: preorder.quantity,
        unitPrice: preorder.unitPrice,
        currency: preorder.currency,
      );
}

final class WalletItemFtService extends WalletItem {
  const WalletItemFtService({
    required super.id,
    required super.title,
    required super.subtitle,
    required super.statusLabel,
    required super.createdAt,
    required super.eventId,
    required super.qrPayload,
    required super.deepLink,
    required this.bookingStatus,
  }) : super(kind: 'ft_service');

  final String bookingStatus;

  factory WalletItemFtService.fromBooking(FtServiceBooking booking) {
    final status = booking.status;
    return WalletItemFtService(
      id: booking.id,
      title: booking.serviceName?.trim().isNotEmpty == true
          ? booking.serviceName!
          : 'Future Times service',
      subtitle: booking.eventTitle?.trim().isNotEmpty == true
          ? booking.eventTitle!
          : 'Event booking',
      statusLabel: _statusLabel(status),
      createdAt: booking.createdAt,
      eventId: booking.eventId,
      qrPayload: booking.id,
      deepLink: '/wallet',
      bookingStatus: status,
    );
  }

  static String _statusLabel(String status) {
    final normalized = status.replaceAll('_', ' ').trim();
    if (normalized.isEmpty) return 'Unknown';
    return normalized[0].toUpperCase() + normalized.substring(1);
  }
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

  factory WalletItemRide.fromRide(RideBooking ride) {
    final status = switch (ride.status) {
      RideStatus.completed => 'Completed',
      RideStatus.cancelled => 'Cancelled',
      RideStatus.failed => 'Failed',
      _ => 'Active',
    };
    final pickup = ride.pickup.address ?? _coordinates(ride.pickup);
    final dropoff = ride.dropoff.address ?? _coordinates(ride.dropoff);
    return WalletItemRide(
      id: ride.id,
      title:
          '${ride.providerId == 'tap_and_go' ? 'Tap & Go' : ride.providerId} ride',
      subtitle: '$pickup → $dropoff',
      statusLabel: status,
      createdAt: ride.createdAt,
      eventId: ride.eventId,
      deepLink: '/ride/book',
    );
  }

  static String _coordinates(GeoPoint point) =>
      '${point.lat.toStringAsFixed(4)}, ${point.lng.toStringAsFixed(4)}';
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

  factory WalletItemReservation.fromReservation(TableReservation reservation) =>
      WalletItemReservation(
        id: reservation.id,
        title: reservation.eventTitle ?? 'Table reservation',
        subtitle:
            '${reservation.tableName ?? 'Table'} · ${reservation.partySize} ${reservation.partySize == 1 ? 'guest' : 'guests'}',
        statusLabel: reservation.status.replaceAll('_', ' '),
        createdAt: reservation.reservedAt,
        eventId: reservation.eventId,
        qrPayload: reservation.qrCode.isEmpty ? null : reservation.qrCode,
        deepLink: '/wallet',
      );
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
    required this.total,
    required this.currency,
    required this.itemCount,
    this.tableReservationId,
  }) : super(kind: 'order');

  final double total;
  final String currency;
  final int itemCount;
  final String? tableReservationId;

  factory WalletItemOrder.fromOrder(VenueOrder order) {
    final itemCount =
        order.items.fold<int>(0, (sum, item) => sum + item.quantity);
    final preview = order.items.take(2).map((item) => item.itemName).join(', ');
    final remaining = order.items.length - 2;
    final title = (order.eventTitle ?? '').trim();
    final subtitle = preview.isEmpty
        ? '${order.currency} ${order.total.toStringAsFixed(2)}'
        : remaining > 0
            ? '$preview +$remaining more'
            : preview;
    return WalletItemOrder(
      id: order.id,
      title: title.isEmpty ? 'Venue order' : title,
      subtitle: subtitle,
      statusLabel: order.status.replaceAll('_', ' '),
      createdAt: order.createdAt,
      eventId: order.eventId,
      qrPayload: order.qrCode.trim().isEmpty ? null : order.qrCode,
      deepLink: '/wallet',
      total: order.total,
      currency: order.currency,
      itemCount: itemCount,
      tableReservationId: order.tableReservationId,
    );
  }
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
        PaymentPurpose.service => 'Service deposit',
      };
}
