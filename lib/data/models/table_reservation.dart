class TableReservation {
  const TableReservation({
    required this.id,
    required this.tableId,
    required this.userId,
    required this.eventId,
    required this.partySize,
    required this.status,
    required this.qrCode,
    required this.total,
    required this.currency,
    this.paymentTransactionId,
    required this.reservedAt,
    this.tableName,
    this.eventTitle,
    this.eventStartsAt,
  });

  final String id;
  final String tableId;
  final String userId;
  final String eventId;
  final int partySize;
  final String status;
  final String qrCode;
  final double total;
  final String currency;
  final String? paymentTransactionId;
  final DateTime reservedAt;
  final String? tableName;
  final String? eventTitle;
  final DateTime? eventStartsAt;

  factory TableReservation.fromSupabase(Map<String, dynamic> row) =>
      TableReservation(
        id: _string(row['id']),
        tableId: _string(row['table_id']),
        userId: _string(row['user_id']),
        eventId: _string(row['event_id']),
        partySize: _int(row['party_size']),
        status: _string(row['status'], 'pending'),
        qrCode: _string(row['qr_code']),
        total: _double(row['total']),
        currency: _string(row['currency'], 'USD'),
        paymentTransactionId: _nullable(row['payment_transaction_id']),
        reservedAt: _date(row['reserved_at']),
        tableName:
            _nullable(row['table_name'] ?? _nestedMap(row['tables'])['name']),
        eventTitle: _nullable(row['event_title'] ??
            _nestedMap(_nestedMap(row['events']))['title']),
        eventStartsAt: _optionalDate(
          row['event_starts_at'] ??
              _nestedMap(_nestedMap(row['events']))['starts_at'],
        ),
      );

  Map<String, dynamic> toSupabase() => {
        'id': id,
        'table_id': tableId,
        'user_id': userId,
        'event_id': eventId,
        'party_size': partySize,
        'status': status,
        'qr_code': qrCode,
        'total': total,
        'currency': currency,
        'payment_transaction_id': paymentTransactionId,
        'reserved_at': reservedAt.toIso8601String(),
      };

  TableReservation copyWith({
    String? id,
    String? tableId,
    String? userId,
    String? eventId,
    int? partySize,
    String? status,
    String? qrCode,
    double? total,
    String? currency,
    String? paymentTransactionId,
    DateTime? reservedAt,
    String? tableName,
    String? eventTitle,
    DateTime? eventStartsAt,
  }) =>
      TableReservation(
        id: id ?? this.id,
        tableId: tableId ?? this.tableId,
        userId: userId ?? this.userId,
        eventId: eventId ?? this.eventId,
        partySize: partySize ?? this.partySize,
        status: status ?? this.status,
        qrCode: qrCode ?? this.qrCode,
        total: total ?? this.total,
        currency: currency ?? this.currency,
        paymentTransactionId: paymentTransactionId ?? this.paymentTransactionId,
        reservedAt: reservedAt ?? this.reservedAt,
        tableName: tableName ?? this.tableName,
        eventTitle: eventTitle ?? this.eventTitle,
        eventStartsAt: eventStartsAt ?? this.eventStartsAt,
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
