import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_error.dart';
import '../../../core/errors/error_handler.dart';
import '../../../core/errors/provider_helpers.dart';
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
  final correlationId = ErrorHandler.generateCorrelationId();
  
  try {
    final repo = ref.read(paymentsRepositoryProvider);
    return await repo.fetchProviders().timeout(
      const Duration(seconds: 10),
      onTimeout: () => <PaymentProvider>[],
    );
  } catch (e) {
    final error = ErrorHandler.handleException(
      e,
      correlationId: correlationId,
      context: 'PaymentProvidersProvider',
    );
    ErrorHandler.logError(error);
    return <PaymentProvider>[];
  }
});

final schoolPaymentAccountsProvider =
    FutureProvider.autoDispose<List<PaymentAccount>>((ref) async {
      return safeProviderOperation<List<PaymentAccount>>(
        ref: ref,
        operation: (schoolId) async {
          final repo = ref.read(paymentsRepositoryProvider);
          return await repo.fetchAccounts(schoolId).timeout(
            const Duration(seconds: 10),
          );
        },
        onError: () => <PaymentAccount>[],
        context: 'SchoolPaymentAccountsProvider',
      );
    });

final paymentTransactionsProvider =
    FutureProvider.autoDispose<List<PaymentTransaction>>((ref) async {
      return safeProviderOperation<List<PaymentTransaction>>(
        ref: ref,
        operation: (schoolId) async {
          final repo = ref.read(paymentsRepositoryProvider);
          return await repo.fetchTransactions(schoolId: schoolId)
              .timeout(const Duration(seconds: 10));
        },
        onError: () => <PaymentTransaction>[],
        context: 'PaymentTransactionsProvider',
      );
    });

final filteredPaymentTransactionsProvider = FutureProvider.autoDispose
    .family<List<PaymentTransaction>, PaymentFilters>((ref, filters) async {
      return safeProviderOperation<List<PaymentTransaction>>(
        ref: ref,
        operation: (schoolId) async {
          final repo = ref.read(paymentsRepositoryProvider);
          final transactions = await repo.fetchTransactions(schoolId: schoolId)
              .timeout(const Duration(seconds: 10));

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

            return true;
          }).toList();
        },
        onError: () => <PaymentTransaction>[],
        context: 'FilteredPaymentTransactionsProvider',
      );
    });

final paymentSearchProvider = FutureProvider.autoDispose
    .family<List<PaymentTransaction>, String>((ref, query) async {
      return safeProviderOperation<List<PaymentTransaction>>(
        ref: ref,
        operation: (schoolId) async {
          final repo = ref.read(paymentsRepositoryProvider);
          final transactions = await repo.fetchTransactions(schoolId: schoolId)
              .timeout(const Duration(seconds: 10));

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

            return false;
          }).toList();
        },
        onError: () => <PaymentTransaction>[],
        context: 'PaymentSearchProvider',
      );
    });

final cashReceiptsProvider = FutureProvider.autoDispose<List<CashFeeReceipt>>((
  ref,
) async {
  return safeProviderOperation<List<CashFeeReceipt>>(
    ref: ref,
    operation: (schoolId) async {
      final repo = ref.read(paymentsRepositoryProvider);
      return await repo.fetchCashReceipts(schoolId: schoolId)
          .timeout(const Duration(seconds: 10));
    },
    onError: () => <CashFeeReceipt>[],
    context: 'CashReceiptsProvider',
  );
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
  final correlationId = ErrorHandler.generateCorrelationId();
  
  try {
    final schoolId = await getSchoolIdSafely(ref);
    if (schoolId == null) {
      throw ValidationError.missingField('school_id');
    }
    
    final repo = ref.read(paymentsRepositoryProvider);
    await repo.addCashReceipt(
      schoolId: schoolId,
      payerName: request.payerName,
      amount: request.amount,
      paymentDate: request.paymentDate,
      receiptNumber: request.receiptNumber,
      notes: request.notes,
      studentId: request.studentId,
    ).timeout(const Duration(seconds: 10));
    ref.invalidate(cashReceiptsProvider);
  } catch (e) {
    final error = ErrorHandler.handleException(
      e,
      correlationId: correlationId,
      context: 'AddCashReceiptProvider',
    );
    ErrorHandler.logError(error);
    rethrow;
  }
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
      final correlationId = ErrorHandler.generateCorrelationId();
      
      try {
        final schoolId = await getSchoolIdSafely(ref);
        if (schoolId == null) {
          throw ValidationError.missingField('school_id');
        }

        final repo = ref.read(paymentsRepositoryProvider);
        await repo.upsertAccount(
          schoolId: schoolId,
          providerKey: request.providerKey,
          credentials: request.fields,
          accountLabel: request.accountLabel,
        ).timeout(const Duration(seconds: 10));
        ref.invalidate(schoolPaymentAccountsProvider);
      } catch (e) {
        final error = ErrorHandler.handleException(
          e,
          correlationId: correlationId,
          context: 'PaymentAccountSubmitProvider',
        );
        ErrorHandler.logError(error);
        rethrow;
      }
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
      final correlationId = ErrorHandler.generateCorrelationId();
      
      try {
        final schoolId = await getSchoolIdSafely(ref);
        if (schoolId == null) {
          throw ValidationError.missingField('school_id');
        }

        final repo = ref.read(paymentsRepositoryProvider);
        return await repo.processPayment(
          schoolId: schoolId,
          amount: request.amount,
          currency: request.currency,
          providerKey: request.providerKey,
          paymentData: request.paymentData,
          payerName: request.payerName,
          payerEmail: request.payerEmail,
          payerPhone: request.payerPhone,
        ).timeout(const Duration(seconds: 30));
      } catch (e) {
        final error = ErrorHandler.handleException(
          e,
          correlationId: correlationId,
          context: 'ProcessPaymentProvider',
        );
        ErrorHandler.logError(error);
        rethrow;
      }
    });

/// Provider for confirming payment completion
final confirmPaymentProvider =
    FutureProvider.family<void, Map<String, dynamic>>((ref, request) async {
      final correlationId = ErrorHandler.generateCorrelationId();
      
      try {
        final repo = ref.read(paymentsRepositoryProvider);
        await repo.confirmPayment(
          transactionId: request['transaction_id'],
          paymentMethodId: request['payment_method_id'],
          confirmationData: request['confirmation_data'],
        ).timeout(const Duration(seconds: 10));
      } catch (e) {
        final error = ErrorHandler.handleException(
          e,
          correlationId: correlationId,
          context: 'ConfirmPaymentProvider',
        );
        ErrorHandler.logError(error);
        rethrow;
      }
    });

/// Provider for checking payment gateway configuration
final paymentGatewayConfigProvider =
    FutureProvider.family<PaymentGatewayConfig, String>((
      ref,
      providerKey,
    ) async {
      final correlationId = ErrorHandler.generateCorrelationId();
      
      try {
        final providerType = PaymentProviderType.values.firstWhere(
          (type) => type.name == providerKey,
          orElse: () => PaymentProviderType.cash,
        );

        return PaymentGatewayConfig.fromEnv(providerType);
      } catch (e) {
        final error = ErrorHandler.handleException(
          e,
          correlationId: correlationId,
          context: 'PaymentGatewayConfigProvider',
        );
        ErrorHandler.logError(error);
        rethrow;
      }
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
