import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/error_handler.dart';
import '../../../core/errors/provider_helpers.dart';
import '../../school_registration/application/school_providers.dart';
import '../data/fee_repository.dart';
import '../domain/fee_category.dart';
import '../domain/fee_invoice.dart';
import '../domain/fee_payment.dart';
import '../domain/fee_structure.dart';
import '../domain/fee_summary.dart';

final feeRepositoryProvider = Provider<FeeRepository>((ref) {
  final repo = FeeRepository();
  final school = ref.watch(currentSchoolProvider);
  if (school != null) {
    repo.setSchoolId(school.id);
  }
  return repo;
});

// Fee Categories
final feeCategoriesProvider = FutureProvider<List<FeeCategory>>((ref) async {
  return safeProviderOperation<List<FeeCategory>>(
    ref: ref,
    operation: (schoolId) async {
      final repo = ref.read(feeRepositoryProvider);
      return await repo
          .fetchFeeCategories(schoolId: schoolId, isActive: true)
          .timeout(const Duration(seconds: 10));
    },
    onError: () => <FeeCategory>[],
    context: 'FeeCategoriesProvider',
  );
});

// Fee Structures
final feeStructuresProvider = FutureProvider<List<FeeStructure>>((ref) async {
  return safeProviderOperation<List<FeeStructure>>(
    ref: ref,
    operation: (schoolId) async {
      final repo = ref.read(feeRepositoryProvider);
      return await repo
          .fetchFeeStructures(schoolId: schoolId, isActive: true)
          .timeout(const Duration(seconds: 10));
    },
    onError: () => <FeeStructure>[],
    context: 'FeeStructuresProvider',
  );
});

final feeStructuresByCategoryProvider =
    FutureProvider.family<List<FeeStructure>, String>((ref, categoryId) async {
      return safeProviderOperation<List<FeeStructure>>(
        ref: ref,
        operation: (schoolId) async {
          final repo = ref.read(feeRepositoryProvider);
          return await repo
              .fetchFeeStructures(
                schoolId: schoolId,
                categoryId: categoryId,
                isActive: true,
              )
              .timeout(const Duration(seconds: 10));
        },
        onError: () => <FeeStructure>[],
        context: 'FeeStructuresByCategoryProvider',
      );
    });

// Fee Invoices
final feeInvoicesProvider = FutureProvider<List<FeeInvoice>>((ref) async {
  return safeProviderOperation<List<FeeInvoice>>(
    ref: ref,
    operation: (schoolId) async {
      final repo = ref.read(feeRepositoryProvider);
      return await repo
          .fetchFeeInvoices(schoolId: schoolId)
          .timeout(const Duration(seconds: 10));
    },
    onError: () => <FeeInvoice>[],
    context: 'FeeInvoicesProvider',
  );
});

final studentFeeInvoicesProvider =
    FutureProvider.family<List<FeeInvoice>, String>((ref, studentId) async {
      return safeProviderOperation<List<FeeInvoice>>(
        ref: ref,
        operation: (schoolId) async {
          final repo = ref.read(feeRepositoryProvider);
          return await repo
              .fetchFeeInvoices(schoolId: schoolId, studentId: studentId)
              .timeout(const Duration(seconds: 10));
        },
        onError: () => <FeeInvoice>[],
        context: 'StudentFeeInvoicesProvider',
      );
    });

final feeInvoiceProvider = FutureProvider.family<FeeInvoice, String>((
  ref,
  invoiceId,
) async {
  final correlationId = ErrorHandler.generateCorrelationId();

  try {
    final repo = ref.read(feeRepositoryProvider);
    return await repo
        .getFeeInvoice(invoiceId)
        .timeout(const Duration(seconds: 10));
  } catch (e) {
    final error = ErrorHandler.handleException(
      e,
      correlationId: correlationId,
      context: 'FeeInvoiceProvider',
    );
    ErrorHandler.logError(error);
    rethrow;
  }
});

// Fee Payments
final feePaymentsProvider = FutureProvider<List<FeePayment>>((ref) async {
  return safeProviderOperation<List<FeePayment>>(
    ref: ref,
    operation: (schoolId) async {
      final repo = ref.read(feeRepositoryProvider);
      return await repo
          .fetchFeePayments(schoolId: schoolId)
          .timeout(const Duration(seconds: 10));
    },
    onError: () => <FeePayment>[],
    context: 'FeePaymentsProvider',
  );
});

final invoicePaymentsProvider = FutureProvider.family<List<FeePayment>, String>(
  (ref, invoiceId) async {
    return safeProviderOperation<List<FeePayment>>(
      ref: ref,
      operation: (schoolId) async {
        final repo = ref.read(feeRepositoryProvider);
        return await repo
            .fetchFeePayments(schoolId: schoolId, invoiceId: invoiceId)
            .timeout(const Duration(seconds: 10));
      },
      onError: () => <FeePayment>[],
      context: 'InvoicePaymentsProvider',
    );
  },
);

// Fee Summary
final studentFeeSummaryProvider = FutureProvider.family<FeeSummary, String>((
  ref,
  studentId,
) async {
  return safeProviderOperation<FeeSummary>(
    ref: ref,
    operation: (schoolId) async {
      final repo = ref.read(feeRepositoryProvider);
      return await repo
          .getStudentFeeSummary(studentId: studentId, schoolId: schoolId)
          .timeout(const Duration(seconds: 10));
    },
    onError: () => const FeeSummary(
      totalInvoices: 0,
      pendingInvoices: 0,
      paidInvoices: 0,
      overdueInvoices: 0,
      totalDueAmount: 0,
      totalPaidAmount: 0,
      totalOutstanding: 0,
    ),
    context: 'StudentFeeSummaryProvider',
  );
});
