import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import '../../core/constants/app_constants.dart';

/// Handles Stripe payment intent creation and confirmation.
class PaymentService {
  PaymentService._();
  static final PaymentService instance = PaymentService._();

  static void init() {
    Stripe.publishableKey = AppConstants.kStripePublishableKey;
    Stripe.merchantIdentifier = 'com.eventdistro.app';
    Stripe.urlScheme = 'eventdistro';
  }

  /// Creates a Stripe PaymentIntent via your backend.
  /// Replace the body with a real HTTP call to your server.
  Future<String> createPaymentIntent({
    required int amountInCents,
    required String currency,
    required String eventId,
  }) async {
    throw UnimplementedError(
      'createPaymentIntent: Connect this to your backend endpoint. '
      'See: https://stripe.com/docs/payments/accept-a-payment',
    );
  }

  /// Presents Stripe's native payment sheet and awaits confirmation.
  Future<PaymentResult> confirmPayment({
    required String clientSecret,
    required String eventName,
    required int amountInCents,
    required String currency,
  }) async {
    try {
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: 'EventDistro',
          style: ThemeMode.dark,
          appearance: const PaymentSheetAppearance(
            colors: PaymentSheetAppearanceColors(
              primary: Color(0xFF6610F2),
              background: Color(0xFF121212),
              componentBackground: Color(0xFF1E1E2E),
              componentText: Color(0xFFFFFFFF),
              placeholderText: Color(0xFF8A8AA3),
            ),
            shapes: PaymentSheetShape(borderRadius: 16),
          ),
        ),
      );

      await Stripe.instance.presentPaymentSheet();
      return PaymentResult.success;
    } on StripeException catch (e) {
      if (e.error.code == FailureCode.Canceled) return PaymentResult.cancelled;
      return PaymentResult.failed;
    } catch (_) {
      return PaymentResult.failed;
    }
  }

  Future<bool> isAppleOrGooglePaySupported() async {
    return Stripe.instance.isPlatformPaySupported();
  }
}

enum PaymentResult { success, cancelled, failed }
