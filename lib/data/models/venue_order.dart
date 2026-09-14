class VenueOrder {
  const VenueOrder({
    required this.id,
    required this.userId,
    required this.venueId,
    required this.eventId,
    this.tableReservationId,
    required this.status,
    required this.total,
    required this.currency,
    required this.qrCode,
    this.paymentTransactionId,
    this.note,
    required this.createdAt,
    required this.items,
    this.eventTitle,
    this.eventStartsAt,
  });

  final String id;
  final String userId;
  final String venueId;
  final String eventId;
  final String? tableReservationId;
  final String status;
  final double total;
  final String currency;
  final String qrCode;
  final String? paymentTransactionId;
  final String? note;
  final DateTime createdAt;
  final List<VenueOrderItem> items;
  final String? eventTitle;
  final DateTime? eventStartsAt;

  factory VenueOrder.fromSupabase(Map<String, dynamic> row) {
    final rawItems =
        row['items'] is List ? row['items'] as List : const <dynamic>[];
    return VenueOrder(
      id: _string(row['id']),
      userId: _string(row['user_id']),
      venueId: _string(row['venue_id']),
      eventId: _string(row['event_id']),
      tableReservationId: _nullable(row['table_reservation_id']),
      status: _string(row['status'], 'pending'),
      total: _double(row['total']),
      currency: _string(row['currency'], 'USD'),
      qrCode: _string(row['qr_code']),
      paymentTransactionId: _nullable(row['payment_transaction_id']),
      note: _nullable(row['note']),
      createdAt: _date(row['created_at']),
      items: rawItems
          .map((item) => VenueOrderItem.fromSupabase(
                Map<String, dynamic>.from(item as Map),
                orderId: _string(row['id']),
              ))
          .toList(growable: false),
      eventTitle: _nullable(
          row['event_title'] ?? _nestedMap(_nestedMap(row['events']))['title']),
      eventStartsAt: _optionalDate(
        row['event_starts_at'] ??
            _nestedMap(_nestedMap(row['events']))['starts_at'],
      ),
    );
  }

  Map<String, dynamic> toSupabase() => {
        'id': id,
        'user_id': userId,
        'venue_id': venueId,
        'event_id': eventId,
        'table_reservation_id': tableReservationId,
        'status': status,
        'total': total,
        'currency': currency,
        'qr_code': qrCode,
        'payment_transaction_id': paymentTransactionId,
        'note': note,
        'created_at': createdAt.toIso8601String(),
      };

  VenueOrder copyWith({
    String? id,
    String? userId,
    String? venueId,
    String? eventId,
    String? tableReservationId,
    String? status,
    double? total,
    String? currency,
    String? qrCode,
    String? paymentTransactionId,
    String? note,
    DateTime? createdAt,
    List<VenueOrderItem>? items,
    String? eventTitle,
    DateTime? eventStartsAt,
  }) =>
      VenueOrder(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        venueId: venueId ?? this.venueId,
        eventId: eventId ?? this.eventId,
        tableReservationId: tableReservationId ?? this.tableReservationId,
        status: status ?? this.status,
        total: total ?? this.total,
        currency: currency ?? this.currency,
        qrCode: qrCode ?? this.qrCode,
        paymentTransactionId: paymentTransactionId ?? this.paymentTransactionId,
        note: note ?? this.note,
        createdAt: createdAt ?? this.createdAt,
        items: items ?? this.items,
        eventTitle: eventTitle ?? this.eventTitle,
        eventStartsAt: eventStartsAt ?? this.eventStartsAt,
      );
}

class VenueOrderItem {
  const VenueOrderItem({
    required this.orderId,
    required this.menuItemId,
    required this.itemName,
    required this.quantity,
    required this.unitPrice,
  });

  final String orderId;
  final String menuItemId;
  final String itemName;
  final int quantity;
  final double unitPrice;

  factory VenueOrderItem.fromSupabase(
    Map<String, dynamic> row, {
    String orderId = '',
  }) =>
      VenueOrderItem(
        orderId: orderId.isNotEmpty ? orderId : _string(row['order_id']),
        menuItemId: _string(row['menu_item_id']),
        itemName: _string(row['item_name']),
        quantity: _int(row['quantity']),
        unitPrice: _double(row['unit_price']),
      );

  Map<String, dynamic> toSupabase() => {
        'order_id': orderId,
        'menu_item_id': menuItemId,
        'item_name': itemName,
        'quantity': quantity,
        'unit_price': unitPrice,
      };

  VenueOrderItem copyWith({
    String? orderId,
    String? menuItemId,
    String? itemName,
    int? quantity,
    double? unitPrice,
  }) =>
      VenueOrderItem(
        orderId: orderId ?? this.orderId,
        menuItemId: menuItemId ?? this.menuItemId,
        itemName: itemName ?? this.itemName,
        quantity: quantity ?? this.quantity,
        unitPrice: unitPrice ?? this.unitPrice,
      );
}

String _string(Object? value, [String fallback = '']) =>
    value?.toString() ?? fallback;

String? _nullable(Object? value) => value?.toString();

int _int(Object? value) => int.tryParse(value?.toString() ?? '') ?? 0;

double _double(Object? value) =>
    double.tryParse(value?.toString() ?? '') ?? 0.0;

Map<String, dynamic> _nestedMap(Object? value) => value is Map<String, dynamic>
    ? value
    : value is Map
        ? Map<String, dynamic>.from(value)
        : <String, dynamic>{};

DateTime _date(Object? value) {
  if (value == null) return DateTime.fromMillisecondsSinceEpoch(0);
  if (value is DateTime) return value;
  if (value is String) {
    return DateTime.tryParse(value) ?? DateTime.fromMillisecondsSinceEpoch(0);
  }
  return DateTime.fromMillisecondsSinceEpoch(0);
}

DateTime? _optionalDate(Object? value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  if (value is String) {
    return DateTime.tryParse(value);
  }
  return null;
}
