import 'payment_gateway.dart';

class EcoCashGateway implements PaymentGateway {
  static const _pendingMessage =
      'EcoCash integration pending merchant credentials';

  @override
  String get gatewayId => 'ecocash';

  @override
  String get displayName => 'EcoCash';

  @override
  Future<PaymentResult> charge({
    required String userId,
    required double amount,
    required String currency,
    required String reference,
    required PaymentPurpose purpose,
  }) =>
      throw UnimplementedError(_pendingMessage);

  @override
  Future<RefundResult> refund({
    required String transactionId,
    required double amount,
  }) =>
      throw UnimplementedError(_pendingMessage);

  @override
  Future<PaymentStatusResult> checkStatus(String transactionId) =>
      throw UnimplementedError(_pendingMessage);
}
