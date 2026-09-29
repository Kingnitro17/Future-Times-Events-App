class FtServiceBooking {
  const FtServiceBooking({
    required this.id,
    required this.serviceId,
    required this.eventId,
    required this.organizerId,
    required this.quantity,
    required this.startTime,
    required this.endTime,
    required this.totalPrice,
    required this.depositAmount,
    required this.currency,
    required this.status,
    this.paymentTransactionId,
    this.reviewedBy,
    this.reviewedAt,
    this.rejectionReason,
    this.notes,
    required this.createdAt,
    this.serviceName,
    this.serviceImageUrl,
    this.eventTitle,
  });

  final String id;
  final String serviceId;
  final String eventId;
  final String organizerId;
  final int quantity;
  final DateTime startTime;
  final DateTime endTime;
  final double totalPrice;
  final double depositAmount;
  final String currency;
  final String status;
  final String? paymentTransactionId;
  final String? reviewedBy;
  final DateTime? reviewedAt;
  final String? rejectionReason;
  final String? notes;
  final DateTime createdAt;
  final String? serviceName;
  final String? serviceImageUrl;
  final String? eventTitle;

  factory FtServiceBooking.fromSupabase(Map<String, dynamic> row) {
    final service = _nestedRow(row['service']);
    final event = _nestedRow(row['event']);
    return FtServiceBooking(
      id: row['id']?.toString() ?? '',
      serviceId: row['service_id']?.toString() ?? '',
      eventId: row['event_id']?.toString() ?? '',
      organizerId: row['organizer_id']?.toString() ?? '',
      quantity: _asInt(row['quantity'], fallback: 1),
      startTime: _asDate(row['start_time']),
      endTime: _asDate(row['end_time']),
      totalPrice: _asDouble(row['total_price']),
      depositAmount: _asDouble(row['deposit_amount']),
      currency: row['currency']?.toString() ?? 'USD',
      status: row['status']?.toString() ?? 'draft',
      paymentTransactionId: row['payment_transaction_id']?.toString(),
      reviewedBy: row['reviewed_by']?.toString(),
      reviewedAt: _asNullableDate(row['reviewed_at']),
      rejectionReason: row['rejection_reason']?.toString(),
      notes: row['notes']?.toString(),
      createdAt: _asDate(row['created_at']),
      serviceName:
          row['service_name']?.toString() ?? service?['name']?.toString(),
      serviceImageUrl: row['service_image_url']?.toString() ??
          service?['image_url']?.toString(),
      eventTitle: row['event_title']?.toString() ?? event?['title']?.toString(),
    );
  }

  Map<String, dynamic> toSupabase() => {
        'id': id,
        'service_id': serviceId,
        'event_id': eventId,
        'organizer_id': organizerId,
        'quantity': quantity,
        'start_time': startTime.toIso8601String(),
        'end_time': endTime.toIso8601String(),
        'total_price': totalPrice,
        'deposit_amount': depositAmount,
        'currency': currency,
        'status': status,
        'payment_transaction_id': paymentTransactionId,
        'reviewed_by': reviewedBy,
        'reviewed_at': reviewedAt?.toIso8601String(),
        'rejection_reason': rejectionReason,
        'notes': notes,
        'created_at': createdAt.toIso8601String(),
      };

  FtServiceBooking copyWith({
    String? id,
    String? serviceId,
    String? eventId,
    String? organizerId,
    int? quantity,
    DateTime? startTime,
    DateTime? endTime,
    double? totalPrice,
    double? depositAmount,
    String? currency,
    String? status,
    String? paymentTransactionId,
    String? reviewedBy,
    DateTime? reviewedAt,
    String? rejectionReason,
    String? notes,
    DateTime? createdAt,
    String? serviceName,
    String? serviceImageUrl,
    String? eventTitle,
  }) =>
      FtServiceBooking(
        id: id ?? this.id,
        serviceId: serviceId ?? this.serviceId,
        eventId: eventId ?? this.eventId,
        organizerId: organizerId ?? this.organizerId,
        quantity: quantity ?? this.quantity,
        startTime: startTime ?? this.startTime,
        endTime: endTime ?? this.endTime,
        totalPrice: totalPrice ?? this.totalPrice,
        depositAmount: depositAmount ?? this.depositAmount,
        currency: currency ?? this.currency,
        status: status ?? this.status,
        paymentTransactionId: paymentTransactionId ?? this.paymentTransactionId,
        reviewedBy: reviewedBy ?? this.reviewedBy,
        reviewedAt: reviewedAt ?? this.reviewedAt,
        rejectionReason: rejectionReason ?? this.rejectionReason,
        notes: notes ?? this.notes,
        createdAt: createdAt ?? this.createdAt,
        serviceName: serviceName ?? this.serviceName,
        serviceImageUrl: serviceImageUrl ?? this.serviceImageUrl,
        eventTitle: eventTitle ?? this.eventTitle,
      );

  static Map<String, dynamic>? _nestedRow(Object? value) {
    if (value is Map<String, dynamic>) return value;
    if (value is List && value.isNotEmpty && value.first is Map) {
      return Map<String, dynamic>.from(value.first as Map);
    }
    return null;
  }

  static int _asInt(Object? value, {int fallback = 0}) =>
      value is int ? value : int.tryParse('$value') ?? fallback;

  static double _asDouble(Object? value) =>
      value is num ? value.toDouble() : double.tryParse('$value') ?? 0;

  static DateTime _asDate(Object? value) =>
      DateTime.tryParse(value?.toString() ?? '') ??
      DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);

  static DateTime? _asNullableDate(Object? value) =>
      value == null ? null : DateTime.tryParse(value.toString());
}
