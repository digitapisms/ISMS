import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../../../core/network/supabase_client.dart';
import '../data/payments_repository.dart';

/// Service for handling payment webhook events
class PaymentWebhookService {
  final PaymentsRepository _paymentsRepository;
  final SupabaseClient _client;

  PaymentWebhookService()
    : _paymentsRepository = PaymentsRepository(),
      _client = SupabaseManager.client;

  /// Process incoming webhook event
  Future<void> processWebhookEvent({
    required String eventType,
    required Map<String, dynamic> eventData,
    required String signature,
  }) async {
    try {
      // Verify webhook signature (implement based on your gateway)
      if (!_verifyWebhookSignature(eventData, signature)) {
        throw Exception('Invalid webhook signature');
      }

      switch (eventType) {
        case 'payment_intent.succeeded':
          await _handlePaymentSucceeded(eventData);
          break;
        case 'payment_intent.payment_failed':
          await _handlePaymentFailed(eventData);
          break;
        case 'payment_intent.processing':
          await _handlePaymentProcessing(eventData);
          break;
        case 'charge.refunded':
          await _handlePaymentRefunded(eventData);
          break;
        default:
          print('Unhandled webhook event type: $eventType');
      }
    } catch (e) {
      print('Webhook processing error: $e');
      rethrow;
    }
  }

  /// Handle successful payment
  Future<void> _handlePaymentSucceeded(Map<String, dynamic> eventData) async {
    final paymentIntent = eventData['data']['object'];
    final transactionId = paymentIntent['metadata']['transaction_id'];
    final externalReference = paymentIntent['id'];
    final amount = (paymentIntent['amount'] / 100).toDouble();
    final currency = paymentIntent['currency'];

    if (transactionId == null) {
      throw Exception('Transaction ID not found in webhook metadata');
    }

    // Update transaction status
    await _paymentsRepository.updateTransactionStatus(
      transactionId: transactionId,
      status: 'succeeded',
      externalReference: externalReference,
      rawResponse: paymentIntent,
    );

    // Update related fee invoice status if applicable
    await _updateFeeInvoiceStatus(transactionId, 'paid', amount, currency);

    print('Payment succeeded: $transactionId');
  }

  /// Handle failed payment
  Future<void> _handlePaymentFailed(Map<String, dynamic> eventData) async {
    final paymentIntent = eventData['data']['object'];
    final transactionId = paymentIntent['metadata']['transaction_id'];
    final externalReference = paymentIntent['id'];
    final error = paymentIntent['last_payment_error'];

    if (transactionId == null) {
      throw Exception('Transaction ID not found in webhook metadata');
    }

    await _paymentsRepository.updateTransactionStatus(
      transactionId: transactionId,
      status: 'failed',
      externalReference: externalReference,
      errorCode: error?['code'],
      errorMessage: error?['message'],
      rawResponse: paymentIntent,
    );

    print('Payment failed: $transactionId - ${error?['message']}');
  }

  /// Handle processing payment
  Future<void> _handlePaymentProcessing(Map<String, dynamic> eventData) async {
    final paymentIntent = eventData['data']['object'];
    final transactionId = paymentIntent['metadata']['transaction_id'];
    final externalReference = paymentIntent['id'];

    if (transactionId == null) {
      throw Exception('Transaction ID not found in webhook metadata');
    }

    await _paymentsRepository.updateTransactionStatus(
      transactionId: transactionId,
      status: 'processing',
      externalReference: externalReference,
      rawResponse: paymentIntent,
    );

    print('Payment processing: $transactionId');
  }

  /// Handle payment refund
  Future<void> _handlePaymentRefunded(Map<String, dynamic> eventData) async {
    final charge = eventData['data']['object'];
    final transactionId = charge['metadata']['transaction_id'];
    final externalReference = charge['id'];
    final refundAmount = (charge['amount_refunded'] / 100).toDouble();

    if (transactionId == null) {
      throw Exception('Transaction ID not found in webhook metadata');
    }

    await _paymentsRepository.updateTransactionStatus(
      transactionId: transactionId,
      status: 'refunded',
      externalReference: externalReference,
      rawResponse: charge,
    );

    // Update related fee invoice status
    await _updateFeeInvoiceStatus(
      transactionId,
      'refunded',
      refundAmount,
      charge['currency'],
    );

    print('Payment refunded: $transactionId - Amount: $refundAmount');
  }

  /// Update fee invoice status based on payment
  Future<void> _updateFeeInvoiceStatus(
    String transactionId,
    String status,
    double amount,
    String currency,
  ) async {
    try {
      // Find fee invoice associated with this transaction
      final invoiceResponse = await _client
          .from('fee_invoices')
          .select('id, student_id, total_amount')
          .eq('payment_transaction_id', transactionId)
          .maybeSingle();

      if (invoiceResponse != null) {
        final invoiceId = invoiceResponse['id'] as String;

        await _client
            .from('fee_invoices')
            .update({
              'payment_status': status,
              'paid_amount': amount,
              'payment_date': status == 'paid'
                  ? DateTime.now().toIso8601String()
                  : null,
              'currency': currency,
            })
            .eq('id', invoiceId);

        // Create payment record for the invoice
        await _client.from('fee_payments').insert({
          'invoice_id': invoiceId,
          'amount': amount,
          'payment_method': 'online',
          'payment_date': DateTime.now().toIso8601String(),
          'transaction_id': transactionId,
          'currency': currency,
          'status': status,
        });
      }
    } catch (e) {
      print('Error updating fee invoice status: $e');
    }
  }

  /// Verify webhook signature using Stripe's signature verification method
  bool _verifyWebhookSignature(
    Map<String, dynamic> eventData,
    String signature,
  ) {
    try {
      final webhookSecret = dotenv.env['STRIPE_WEBHOOK_SECRET'];

      if (webhookSecret == null || webhookSecret.isEmpty) {
        throw Exception(
          'STRIPE_WEBHOOK_SECRET not configured in environment variables',
        );
      }

      if (signature.isEmpty) {
        throw Exception('Webhook signature is empty');
      }

      // Extract timestamp and signatures from the signature header
      // Stripe signature format: t=timestamp,v1=signature,v0=signature
      final signatureParts = signature.split(',');

      String? timestamp;
      String? receivedSignature;

      for (final part in signatureParts) {
        if (part.startsWith('t=')) {
          timestamp = part.substring(2);
        } else if (part.startsWith('v1=')) {
          receivedSignature = part.substring(3);
        }
      }

      if (timestamp == null || receivedSignature == null) {
        throw Exception(
          'Invalid signature format. Expected t=timestamp,v1=signature',
        );
      }

      // Verify that the timestamp is recent (to prevent replay attacks)
      final currentTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final signatureTime = int.tryParse(timestamp) ?? 0;

      if ((currentTime - signatureTime).abs() > 300) {
        // 5 minutes tolerance
        throw Exception('Webhook signature timestamp is too old or invalid');
      }

      // Create the signed payload
      final payload = '$timestamp.${json.encode(eventData)}';

      // Compute HMAC SHA256 signature
      final hmac = Hmac(sha256, Uint8List.fromList(utf8.encode(webhookSecret)));
      final computedSignature = hmac.convert(utf8.encode(payload)).bytes;

      // Convert computed signature to hex
      final computedSignatureHex = computedSignature
          .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
          .join('');

      // Compare signatures using constant-time comparison to prevent timing attacks
      return _constantTimeCompare(receivedSignature, computedSignatureHex);
    } catch (e) {
      print('Webhook signature verification failed: $e');
      return false;
    }
  }

  /// Constant-time string comparison to prevent timing attacks
  bool _constantTimeCompare(String a, String b) {
    if (a.length != b.length) {
      return false;
    }

    var result = 0;
    for (var i = 0; i < a.length; i++) {
      result |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }

    return result == 0;
  }

  /// Parse webhook event from raw request
  static Map<String, dynamic> parseWebhookEvent(
    String rawBody,
    String signature,
  ) {
    try {
      final event = jsonDecode(rawBody);
      return {
        'event_type': event['type'],
        'event_data': event,
        'signature': signature,
      };
    } catch (e) {
      throw Exception('Invalid webhook payload: $e');
    }
  }
}
