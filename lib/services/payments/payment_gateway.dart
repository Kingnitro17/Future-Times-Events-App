enum PaymentPurpose { ticket, table, order }

sealed class PaymentResult {
  const PaymentResult();
}

class PaymentSuccess extends PaymentResult {
  const PaymentSuccess({
    required this.transactionId,
    required this.gatewayReference,
    required this.paidAt,
  });

  final String transactionId;
  final String gatewayReference;
  final DateTime paidAt;
}

class PaymentFailure extends PaymentResult {
  const PaymentFailure({required this.code, required this.message});

  final String code;
  final String message;
}

class PaymentPending extends PaymentResult {
  const PaymentPending({required this.transactionId});

  final String transactionId;
}

sealed class RefundResult {
  const RefundResult();
}

class RefundSuccess extends RefundResult {
  const RefundSuccess({
    required this.transactionId,
    required this.refundedAt,
  });

  final String transactionId;
  final DateTime refundedAt;
}

class RefundFailure extends RefundResult {
  const RefundFailure({required this.code, required this.message});

  final String code;
  final String message;
}

sealed class PaymentStatusResult {
  const PaymentStatusResult();
}

class PaymentPaid extends PaymentStatusResult {
  const PaymentPaid({required this.paidAt});

  final DateTime paidAt;
}

class PaymentPendingStatus extends PaymentStatusResult {
  const PaymentPendingStatus();
}

class PaymentFailed extends PaymentStatusResult {
  const PaymentFailed({required this.reason});

  final String reason;
}

class PaymentRefunded extends PaymentStatusResult {
  const PaymentRefunded({required this.refundedAt});

  final DateTime refundedAt;
}

abstract class PaymentGateway {
  String get gatewayId;

  String get displayName;

  Future<PaymentResult> charge({
    required String userId,
    required double amount,
    required String currency,
    required String reference,
    required PaymentPurpose purpose,
  });

  Future<RefundResult> refund({
    required String transactionId,
    required double amount,
  });

  Future<PaymentStatusResult> checkStatus(String transactionId);
}
