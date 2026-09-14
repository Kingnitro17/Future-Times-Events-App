import 'dart:math';

import 'payment_gateway.dart';

class ManualGateway implements PaymentGateway {
  @override
  String get gatewayId => 'manual';

  @override
  String get displayName => 'Manual';

  @override
  Future<PaymentResult> charge({
    required String userId,
    required double amount,
    required String currency,
    required String reference,
    required PaymentPurpose purpose,
  }) async {
    final transactionId = _uuid();
    return PaymentSuccess(
      transactionId: transactionId,
      gatewayReference: reference.isEmpty ? transactionId : reference,
      paidAt: DateTime.now(),
    );
  }

  @override
  Future<RefundResult> refund({
    required String transactionId,
    required double amount,
  }) async =>
      RefundSuccess(
        transactionId: transactionId,
        refundedAt: DateTime.now(),
      );

  @override
  Future<PaymentStatusResult> checkStatus(String transactionId) async =>
      PaymentPaid(paidAt: DateTime.now());

  String _uuid() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final hex = bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0'));
    final value = hex.join();
    return '${value.substring(0, 8)}-${value.substring(8, 12)}-'
        '${value.substring(12, 16)}-${value.substring(16, 20)}-'
        '${value.substring(20)}';
  }
}
