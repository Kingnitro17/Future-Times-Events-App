import '../../services/payments/payment_gateway.dart';

enum PaymentStatus { pending, paid, failed, refunded }

class PaymentTransaction {
  const PaymentTransaction({
    required this.id,
    required this.userId,
    required this.amount,
    required this.currency,
    required this.status,
    required this.gateway,
    this.gatewayReference,
    required this.purpose,
    required this.relatedEntityId,
    required this.metadata,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String userId;
  final double amount;
  final String currency;
  final PaymentStatus status;
  final String gateway;
  final String? gatewayReference;
  final PaymentPurpose purpose;
  final String relatedEntityId;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory PaymentTransaction.fromSupabase(Map<String, dynamic> row) {
    return PaymentTransaction(
      id: row['id']?.toString() ?? '',
      userId: row['user_id']?.toString() ?? '',
      amount: _double(row['amount']),
      currency: row['currency']?.toString() ?? 'USD',
      status: _status(row['status']),
      gateway: row['gateway']?.toString() ?? '',
      gatewayReference: row['gateway_reference']?.toString(),
      purpose: _purpose(row['purpose']),
      relatedEntityId: row['related_entity_id']?.toString() ?? '',
      metadata: _metadata(row['metadata']),
      createdAt: _date(row['created_at']),
      updatedAt: _date(row['updated_at']),
    );
  }

  Map<String, dynamic> toSupabase() => {
        'id': id,
        'user_id': userId,
        'amount': amount,
        'currency': currency,
        'status': status.name,
        'gateway': gateway,
        'gateway_reference': gatewayReference,
        'purpose': purpose.name,
        'related_entity_id': relatedEntityId,
        'metadata': metadata,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  PaymentTransaction copyWith({
    String? id,
    String? userId,
    double? amount,
    String? currency,
    PaymentStatus? status,
    String? gateway,
    String? gatewayReference,
    PaymentPurpose? purpose,
    String? relatedEntityId,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      PaymentTransaction(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        amount: amount ?? this.amount,
        currency: currency ?? this.currency,
        status: status ?? this.status,
        gateway: gateway ?? this.gateway,
        gatewayReference: gatewayReference ?? this.gatewayReference,
        purpose: purpose ?? this.purpose,
        relatedEntityId: relatedEntityId ?? this.relatedEntityId,
        metadata: metadata ?? this.metadata,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  static double _double(Object? value) =>
      value is num ? value.toDouble() : double.tryParse('$value') ?? 0;

  static PaymentStatus _status(Object? value) =>
      PaymentStatus.values.firstWhere((item) => item.name == value?.toString(),
          orElse: () => PaymentStatus.pending);

  static PaymentPurpose _purpose(Object? value) =>
      PaymentPurpose.values.firstWhere((item) => item.name == value?.toString(),
          orElse: () => PaymentPurpose.ticket);

  static Map<String, dynamic> _metadata(Object? value) {
    if (value is Map) return Map<String, dynamic>.from(value);
    return const {};
  }

  static DateTime _date(Object? value) =>
      DateTime.tryParse(value?.toString() ?? '') ??
      DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
}
