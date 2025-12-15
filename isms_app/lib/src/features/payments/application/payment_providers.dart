import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../school_registration/application/school_providers.dart';
import '../data/payments_repository.dart';
import '../domain/cash_fee_receipt.dart';
import '../domain/payment_account.dart';
import '../domain/payment_provider.dart';
import '../domain/payment_transaction.dart';

final paymentsRepositoryProvider = Provider<PaymentsRepository>((ref) {
  return PaymentsRepository();
});

final paymentProvidersProvider = FutureProvider<List<PaymentProvider>>((
  ref,
) async {
  final repo = ref.read(paymentsRepositoryProvider);
  return repo.fetchProviders();
});

final schoolPaymentAccountsProvider =
    FutureProvider.autoDispose<List<PaymentAccount>>((ref) async {
      final school = ref.watch(currentSchoolProvider);
      if (school == null) return const [];
      final repo = ref.read(paymentsRepositoryProvider);
      ref.keepAlive();
      return repo.fetchAccounts(school.id);
    });

final paymentTransactionsProvider =
    FutureProvider.autoDispose<List<PaymentTransaction>>((ref) async {
      final school = ref.watch(currentSchoolProvider);
      if (school == null) return const [];
      final repo = ref.read(paymentsRepositoryProvider);
      return repo.fetchTransactions(schoolId: school.id);
    });

final cashReceiptsProvider = FutureProvider.autoDispose<List<CashFeeReceipt>>((
  ref,
) async {
  final school = ref.watch(currentSchoolProvider);
  if (school == null) return const [];
  final repo = ref.read(paymentsRepositoryProvider);
  return repo.fetchCashReceipts(schoolId: school.id);
});

class CashReceiptRequest {
  CashReceiptRequest({
    required this.payerName,
    required this.amount,
    this.paymentDate,
    this.receiptNumber,
    this.notes,
    this.studentId,
  });

  final String payerName;
  final double amount;
  final DateTime? paymentDate;
  final String? receiptNumber;
  final String? notes;
  final String? studentId;
}

final addCashReceiptProvider = FutureProvider.family<void, CashReceiptRequest>((
  ref,
  request,
) async {
  final school = ref.read(currentSchoolProvider);
  if (school == null) {
    throw Exception('No school context available.');
  }
  final repo = ref.read(paymentsRepositoryProvider);
  await repo.addCashReceipt(
    schoolId: school.id,
    payerName: request.payerName,
    amount: request.amount,
    paymentDate: request.paymentDate,
    receiptNumber: request.receiptNumber,
    notes: request.notes,
    studentId: request.studentId,
  );
  ref.invalidate(cashReceiptsProvider);
});

class PaymentAccountRequest {
  PaymentAccountRequest({
    required this.providerKey,
    required this.fields,
    this.accountLabel,
  });

  final String providerKey;
  final Map<String, String> fields;
  final String? accountLabel;
}

final paymentAccountSubmitProvider =
    FutureProvider.family<void, PaymentAccountRequest>((ref, request) async {
      final school = ref.read(currentSchoolProvider);
      if (school == null) {
        throw Exception('No school context available.');
      }

      final repo = ref.read(paymentsRepositoryProvider);
      await repo.upsertAccount(
        schoolId: school.id,
        providerKey: request.providerKey,
        credentials: request.fields,
        accountLabel: request.accountLabel,
      );
      ref.invalidate(schoolPaymentAccountsProvider);
    });
