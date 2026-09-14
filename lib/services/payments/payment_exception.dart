class PaymentException implements Exception {
  const PaymentException(this.code, this.message);

  final String code;
  final String message;

  @override
  String toString() => 'PaymentException($code): $message';
}
