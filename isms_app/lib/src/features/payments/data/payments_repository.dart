import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/network/supabase_client.dart';
import '../domain/cash_fee_receipt.dart';
import '../domain/payment_account.dart';
import '../domain/payment_provider.dart';
import '../domain/payment_transaction.dart';
import '../services/payment_gateway_service.dart';

class PaymentsRepository {
  SupabaseClient get _client => SupabaseManager.client;

  Future<List<PaymentProvider>> fetchProviders() async {
    final response = await _client
        .from('payment_providers')
        .select()
        .eq('is_active', true)
        .order('display_name');

    return (response as List)
        .map((row) => PaymentProvider.fromMap(row as Map<String, dynamic>))
        .toList();
  }

  Future<List<PaymentAccount>> fetchAccounts(String schoolId) async {
    final response = await _client
        .from('school_payment_accounts')
        .select('*, payment_providers(*)')
        .eq('school_id', schoolId)
        .order('created_at', ascending: false);

    return (response as List)
        .map((row) => PaymentAccount.fromMap(row as Map<String, dynamic>))
        .toList();
  }

  Future<PaymentAccount> upsertAccount({
    required String schoolId,
    required String providerKey,
    required Map<String, dynamic> credentials,
    Map<String, dynamic>? metadata,
    String? accountLabel,
  }) async {
    final response =
        await _client.rpc(
              'upsert_school_payment_account',
              params: {
                'p_school_id': schoolId,
                'p_provider_key': providerKey,
                'p_credentials': credentials,
                'p_metadata': metadata ?? <String, dynamic>{},
                'p_account_label': accountLabel,
              },
            )
            as String;

    final rows = await _client
        .from('school_payment_accounts')
        .select('*, payment_providers(*)')
        .eq('id', response)
        .maybeSingle();

    if (rows == null) {
      throw Exception('Payment account not found after upsert');
    }

    return PaymentAccount.fromMap(Map<String, dynamic>.from(rows));
  }

  Future<void> updateAccountStatus({
    required String accountId,
    required String status,
    Map<String, dynamic>? metadata,
  }) async {
    await _client
        .from('school_payment_accounts')
        .update({'status': status, if (metadata != null) 'metadata': metadata})
        .eq('id', accountId);
  }

  Future<void> updateAccountLabel({
    required String accountId,
    required String accountLabel,
  }) async {
    await _client
        .from('school_payment_accounts')
        .update({'account_label': accountLabel})
        .eq('id', accountId);
  }

  Future<void> deleteAccount(String accountId) async {
    await _client.from('school_payment_accounts').delete().eq('id', accountId);
  }

  Future<List<PaymentTransaction>> fetchTransactions({
    required String schoolId,
    int limit = 20,
  }) async {
    final response = await _client
        .from('payment_transactions')
        .select()
        .eq('school_id', schoolId)
        .order('initiated_at', ascending: false)
        .limit(limit);

    return (response as List)
        .map((row) => PaymentTransaction.fromMap(row as Map<String, dynamic>))
        .toList();
  }

  Future<List<CashFeeReceipt>> fetchCashReceipts({
    required String schoolId,
    int limit = 10,
  }) async {
    final response = await _client
        .from('cash_fee_receipts')
        .select()
        .eq('school_id', schoolId)
        .order('payment_date', ascending: false)
        .limit(limit);

    return (response as List)
        .map((row) => CashFeeReceipt.fromMap(row as Map<String, dynamic>))
        .toList();
  }

  Future<void> addCashReceipt({
    required String schoolId,
    required String payerName,
    required double amount,
    DateTime? paymentDate,
    String? receiptNumber,
    String? notes,
    String? studentId,
  }) async {
    await _client.from('cash_fee_receipts').insert({
      'school_id': schoolId,
      'payer_name': payerName,
      'amount': amount,
      'payment_date': (paymentDate ?? DateTime.now()).toIso8601String(),
      'receipt_number': receiptNumber,
      'notes': notes,
      'student_id': studentId,
    });
  }

  /// Create a payment transaction
  Future<PaymentTransaction> createPaymentTransaction({
    required String schoolId,
    required double amount,
    required String currency,
    required String providerKey,
    String? accountId,
    String? payerName,
    String? payerEmail,
    String? payerPhone,
    String? referenceCode,
    Map<String, dynamic>? metadata,
  }) async {
    final response = await _client.from('payment_transactions').insert({
      'school_id': schoolId,
      'amount': amount,
      'currency': currency,
      'provider_key': providerKey,
      'account_id': accountId,
      'payer_name': payerName,
      'payer_email': payerEmail,
      'payer_phone': payerPhone,
      'reference_code': referenceCode,
      'status': 'pending',
      'initiated_at': DateTime.now().toIso8601String(),
      'metadata': metadata ?? {},
    }).select();

    if (response.isEmpty) {
      throw Exception('Failed to create payment transaction');
    }

    return PaymentTransaction.fromMap(response.first);
  }

  /// Update payment transaction status
  Future<void> updateTransactionStatus({
    required String transactionId,
    required String status,
    String? externalReference,
    String? errorCode,
    String? errorMessage,
    Map<String, dynamic>? rawResponse,
  }) async {
    final updateData = {
      'status': status,
      'completed_at': DateTime.now().toIso8601String(),
      if (externalReference != null) 'external_reference': externalReference,
      if (errorCode != null) 'error_code': errorCode,
      if (errorMessage != null) 'error_message': errorMessage,
      if (rawResponse != null) 'raw_response': rawResponse,
    };

    await _client
        .from('payment_transactions')
        .update(updateData)
        .eq('id', transactionId);
  }

  /// Process payment through gateway
  Future<Map<String, dynamic>> processPayment({
    required String schoolId,
    required double amount,
    required String currency,
    required String providerKey,
    required Map<String, dynamic> paymentData,
    String? payerName,
    String? payerEmail,
    String? payerPhone,
  }) async {
    // Create transaction record
    final transaction = await createPaymentTransaction(
      schoolId: schoolId,
      amount: amount,
      currency: currency,
      providerKey: providerKey,
      payerName: payerName,
      payerEmail: payerEmail,
      payerPhone: payerPhone,
      referenceCode: paymentData['reference'],
    );

    try {
      // Initialize payment gateway
      final providerType = PaymentProviderType.values.firstWhere(
        (type) => type.name == providerKey,
        orElse: () => PaymentProviderType.cash,
      );

      final gateway = PaymentGatewayService(
        provider: providerType,
        config: PaymentGatewayConfig.fromEnv(providerType),
      );

      // Create payment intent
      final intentResult = await gateway.createPaymentIntent(
        amount: amount,
        currency: currency,
        reference: transaction.id,
        customerEmail: payerEmail,
        customerPhone: payerPhone,
        metadata: {
          'school_id': schoolId,
          'transaction_id': transaction.id,
          'payer_name': payerName,
        },
      );

      // Update transaction with gateway reference
      await updateTransactionStatus(
        transactionId: transaction.id,
        status: 'processing',
        externalReference: intentResult['id'],
        rawResponse: intentResult,
      );

      return {
        'success': true,
        'transaction_id': transaction.id,
        'gateway_reference': intentResult['id'],
        'client_secret': intentResult['client_secret'],
        'next_action': intentResult['next_action'],
      };
    } catch (e) {
      // Update transaction as failed
      await updateTransactionStatus(
        transactionId: transaction.id,
        status: 'failed',
        errorMessage: e.toString(),
      );

      rethrow;
    }
  }

  /// Confirm payment completion
  Future<void> confirmPayment({
    required String transactionId,
    required String paymentMethodId,
    Map<String, dynamic>? confirmationData,
  }) async {
    final transaction = await _client
        .from('payment_transactions')
        .select()
        .eq('id', transactionId)
        .maybeSingle();

    if (transaction == null) {
      throw Exception('Transaction not found');
    }

    final transactionData = PaymentTransaction.fromMap(
      Map<String, dynamic>.from(transaction),
    );

    final providerType = PaymentProviderType.values.firstWhere(
      (type) => type.name == transactionData.providerKey,
      orElse: () => PaymentProviderType.cash,
    );

    final gateway = PaymentGatewayService(
      provider: providerType,
      config: PaymentGatewayConfig.fromEnv(providerType),
    );

    try {
      final confirmationResult = await gateway.confirmPayment(
        paymentIntentId: transactionData.externalReference!,
        paymentMethodId: paymentMethodId,
        confirmationData: confirmationData,
      );

      if (confirmationResult['status'] == 'succeeded') {
        await updateTransactionStatus(
          transactionId: transactionId,
          status: 'succeeded',
          rawResponse: confirmationResult,
        );
      } else {
        await updateTransactionStatus(
          transactionId: transactionId,
          status: 'failed',
          errorMessage: 'Payment confirmation failed',
          rawResponse: confirmationResult,
        );
      }
    } catch (e) {
      await updateTransactionStatus(
        transactionId: transactionId,
        status: 'failed',
        errorMessage: e.toString(),
      );
      rethrow;
    }
  }
}
