import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../school_registration/application/school_providers.dart';
import '../data/payments_repository.dart';
import '../domain/cash_fee_receipt.dart';
import '../domain/payment_account.dart';
import '../domain/payment_filters.dart';
import '../domain/payment_provider.dart';
import '../domain/payment_transaction.dart';
import '../services/payment_gateway_service.dart';

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

final filteredPaymentTransactionsProvider = FutureProvider.autoDispose
    .family<List<PaymentTransaction>, PaymentFilters>((ref, filters) async {
      final school = ref.watch(currentSchoolProvider);
      if (school == null) return const [];
      final repo = ref.read(paymentsRepositoryProvider);
      final transactions = await repo.fetchTransactions(schoolId: school.id);

      return transactions.where((transaction) {
        // Filter by status
        if (filters.status != null &&
            transaction.status.toLowerCase() != filters.status!.toLowerCase()) {
          return false;
        }

        // Filter by date range
        if (filters.startDate != null &&
            transaction.initiatedAt != null &&
            transaction.initiatedAt!.isBefore(filters.startDate!)) {
          return false;
        }

        if (filters.endDate != null &&
            transaction.initiatedAt != null &&
            transaction.initiatedAt!.isAfter(filters.endDate!)) {
          return false;
        }

        // Filter by amount range
        if (filters.minAmount != null &&
            transaction.amount < filters.minAmount!) {
          return false;
        }

        if (filters.maxAmount != null &&
            transaction.amount > filters.maxAmount!) {
          return false;
        }

        // Filter by payment method
        // TODO: PaymentTransaction doesn't have paymentMethod property
        // if (filters.paymentMethod != null &&
        //     transaction.paymentMethod != filters.paymentMethod) {
        //   return false;
        // }

        return true;
      }).toList();
    });

final paymentSearchProvider = FutureProvider.autoDispose
    .family<List<PaymentTransaction>, String>((ref, query) async {
      final school = ref.watch(currentSchoolProvider);
      if (school == null) return const [];
      final repo = ref.read(paymentsRepositoryProvider);
      final transactions = await repo.fetchTransactions(schoolId: school.id);

      if (query.isEmpty) return transactions;

      final lowercaseQuery = query.toLowerCase();

      return transactions.where((transaction) {
        // Search by payer name
        if (transaction.payerName?.toLowerCase().contains(lowercaseQuery) ==
            true) {
          return true;
        }

        // Search by reference code
        if (transaction.referenceCode?.toLowerCase().contains(lowercaseQuery) ==
            true) {
          return true;
        }

        // Search by external reference
        if (transaction.externalReference?.toLowerCase().contains(
              lowercaseQuery,
            ) ==
            true) {
          return true;
        }

        // Search by amount
        if (transaction.amount.toString().contains(lowercaseQuery)) {
          return true;
        }

        // Search by payment method - TODO: PaymentTransaction doesn't have paymentMethod property
        // if (transaction.paymentMethod?.toLowerCase().contains(lowercaseQuery) ==
        //     true) {
        //   return true;
        // }

        return false;
      }).toList();
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

/// Payment processing request model
class PaymentProcessingRequest {
  PaymentProcessingRequest({
    required this.amount,
    required this.currency,
    required this.providerKey,
    required this.paymentData,
    this.payerName,
    this.payerEmail,
    this.payerPhone,
  });

  final double amount;
  final String currency;
  final String providerKey;
  final Map<String, dynamic> paymentData;
  final String? payerName;
  final String? payerEmail;
  final String? payerPhone;
}

/// Provider for processing payments through gateway
final processPaymentProvider =
    FutureProvider.family<Map<String, dynamic>, PaymentProcessingRequest>((
      ref,
      request,
    ) async {
      final school = ref.read(currentSchoolProvider);
      if (school == null) {
        throw Exception('No school context available.');
      }

      final repo = ref.read(paymentsRepositoryProvider);
      return repo.processPayment(
        schoolId: school.id,
        amount: request.amount,
        currency: request.currency,
        providerKey: request.providerKey,
        paymentData: request.paymentData,
        payerName: request.payerName,
        payerEmail: request.payerEmail,
        payerPhone: request.payerPhone,
      );
    });

/// Provider for confirming payment completion
final confirmPaymentProvider =
    FutureProvider.family<void, Map<String, dynamic>>((ref, request) async {
      final repo = ref.read(paymentsRepositoryProvider);
      await repo.confirmPayment(
        transactionId: request['transaction_id'],
        paymentMethodId: request['payment_method_id'],
        confirmationData: request['confirmation_data'],
      );
    });

/// Provider for checking payment gateway configuration
final paymentGatewayConfigProvider =
    FutureProvider.family<PaymentGatewayConfig, String>((
      ref,
      providerKey,
    ) async {
      final providerType = PaymentProviderType.values.firstWhere(
        (type) => type.name == providerKey,
        orElse: () => PaymentProviderType.cash,
      );

      return PaymentGatewayConfig.fromEnv(providerType);
    });

/// Provider for payment gateway service
final paymentGatewayServiceProvider =
    Provider.family<PaymentGatewayService, String>((ref, providerKey) {
      final providerType = PaymentProviderType.values.firstWhere(
        (type) => type.name == providerKey,
        orElse: () => PaymentProviderType.cash,
      );

      final config = PaymentGatewayConfig.fromEnv(providerType);
      return PaymentGatewayService(provider: providerType, config: config);
    });
