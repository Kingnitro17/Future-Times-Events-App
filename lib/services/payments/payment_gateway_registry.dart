import 'ecocash_gateway.dart';
import 'manual_gateway.dart';
import 'paynow_gateway.dart';
import 'payment_gateway.dart';

class PaymentGatewayRegistry {
  PaymentGatewayRegistry._();

  static final Map<String, PaymentGateway> _gateways = {
    'paynow': PaynowGateway(),
    'ecocash': EcoCashGateway(),
    'manual': ManualGateway(),
  };

  static PaymentGateway getGateway(String id) {
    final gateway = _gateways[id.trim().toLowerCase()];
    if (gateway == null) {
      throw ArgumentError.value(id, 'id', 'Unsupported payment gateway');
    }
    return gateway;
  }

  static Map<String, PaymentGateway> get gateways =>
      Map.unmodifiable(_gateways);
}
