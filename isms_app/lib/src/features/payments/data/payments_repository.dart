import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/network/supabase_client.dart';
import '../domain/cash_fee_receipt.dart';
import '../domain/payment_account.dart';
import '../domain/payment_provider.dart';
import '../domain/payment_transaction.dart';

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
}
