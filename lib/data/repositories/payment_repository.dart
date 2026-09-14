import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/models/payment_transaction.dart';
import '../../services/payments/payment_exception.dart';
import '../../services/payments/payment_gateway.dart';
import '../../services/payments/payment_gateway_registry.dart';

class PaymentRepository {
  PaymentRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<PaymentTransaction> initiateCharge({
    required String userId,
    required double amount,
    required String currency,
    required PaymentPurpose purpose,
    required String gatewayId,
    required String relatedEntityId,
  }) async {
    final reference =
        '${purpose.name}:$relatedEntityId:$userId:${DateTime.now().millisecondsSinceEpoch}';
    final existing = await _client
        .from('payment_transactions')
        .select()
        .eq('gateway_reference', reference)
        .eq('status', 'pending')
        .maybeSingle();
    if (existing != null) return PaymentTransaction.fromSupabase(existing);

    final row = await _client
        .from('payment_transactions')
        .insert({
          'user_id': userId,
          'amount': amount,
          'currency': currency,
          'status': 'pending',
          'gateway': gatewayId,
          'gateway_reference': reference,
          'purpose': purpose.name,
          'related_entity_id': relatedEntityId,
          'metadata': <String, dynamic>{},
        })
        .select()
        .single();
    var transaction = PaymentTransaction.fromSupabase(row);
    final gateway = PaymentGatewayRegistry.getGateway(gatewayId);

    try {
      final result = await gateway.charge(
        userId: userId,
        amount: amount,
        currency: currency,
        reference: reference,
        purpose: purpose,
      );
      if (result is PaymentSuccess) {
        final success = result;
        transaction = await _update(transaction.id, {
          'status': 'paid',
          'gateway_reference': success.gatewayReference,
          'updated_at': success.paidAt.toIso8601String(),
        });
      } else if (result is PaymentFailure) {
        final failure = result;
        await _update(transaction.id, {
          'status': 'failed',
          'updated_at': DateTime.now().toIso8601String(),
        });
        throw PaymentException(failure.code, failure.message);
      }
      return transaction;
    } on PaymentException {
      rethrow;
    } catch (error) {
      await _update(transaction.id, {
        'status': 'failed',
        'updated_at': DateTime.now().toIso8601String(),
      });
      throw PaymentException('gateway_error', error.toString());
    }
  }

  Future<PaymentTransaction?> getById(String id) async {
    final row = await _client
        .from('payment_transactions')
        .select()
        .eq('id', id)
        .maybeSingle();
    return row == null ? null : PaymentTransaction.fromSupabase(row);
  }

  Future<List<PaymentTransaction>> getMyTransactions({int limit = 50}) async {
    final rows = await _client
        .from('payment_transactions')
        .select()
        .order('created_at', ascending: false)
        .limit(limit);
    return rows
        .cast<Map<String, dynamic>>()
        .map(PaymentTransaction.fromSupabase)
        .toList();
  }

  Future<PaymentTransaction> refund(String transactionId, double amount) async {
    final transaction = await getById(transactionId);
    if (transaction == null) {
      throw const PaymentException(
          'not_found', 'Payment transaction not found.');
    }
    final gateway = PaymentGatewayRegistry.getGateway(transaction.gateway);
    try {
      final result = await gateway.refund(
        transactionId: transactionId,
        amount: amount,
      );
      if (result is RefundSuccess) {
        return await _update(transactionId, {
          'status': 'refunded',
          'updated_at': result.refundedAt.toIso8601String(),
        });
      }
      final failure = result as RefundFailure;
      throw PaymentException(failure.code, failure.message);
    } on PaymentException {
      rethrow;
    } catch (error) {
      throw PaymentException('refund_failed', error.toString());
    }
  }

  Future<PaymentTransaction> markAsPaidManually({
    required String transactionId,
    required String gatewayReference,
  }) async {
    final transaction = await getById(transactionId);
    if (transaction == null) {
      throw const PaymentException(
          'not_found', 'Payment transaction not found.');
    }
    if (transaction.gateway != 'manual') {
      throw const PaymentException(
          'invalid_gateway', 'Only manual transactions can be marked paid.');
    }
    return _update(transactionId, {
      'status': 'paid',
      'gateway_reference': gatewayReference,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  Future<PaymentTransaction> _update(
      String id, Map<String, dynamic> values) async {
    final row = await _client
        .from('payment_transactions')
        .update(values)
        .eq('id', id)
        .select()
        .single();
    return PaymentTransaction.fromSupabase(row);
  }
}
