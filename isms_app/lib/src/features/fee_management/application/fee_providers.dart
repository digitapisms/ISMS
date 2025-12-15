import 'package:flutter_riverpod/flutter_riverpod.dart';

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
  final school = ref.watch(currentSchoolProvider);
  if (school == null) return [];
  final repo = ref.read(feeRepositoryProvider);
  return repo.fetchFeeCategories(schoolId: school.id, isActive: true);
});

// Fee Structures
final feeStructuresProvider = FutureProvider<List<FeeStructure>>((ref) async {
  final school = ref.watch(currentSchoolProvider);
  if (school == null) return [];
  final repo = ref.read(feeRepositoryProvider);
  return repo.fetchFeeStructures(schoolId: school.id, isActive: true);
});

final feeStructuresByCategoryProvider =
    FutureProvider.family<List<FeeStructure>, String>((ref, categoryId) async {
      final school = ref.watch(currentSchoolProvider);
      if (school == null) return [];
      final repo = ref.read(feeRepositoryProvider);
      return repo.fetchFeeStructures(
        schoolId: school.id,
        categoryId: categoryId,
        isActive: true,
      );
    });

// Fee Invoices
final feeInvoicesProvider = FutureProvider<List<FeeInvoice>>((ref) async {
  final school = ref.watch(currentSchoolProvider);
  if (school == null) return [];
  final repo = ref.read(feeRepositoryProvider);
  return repo.fetchFeeInvoices(schoolId: school.id);
});

final studentFeeInvoicesProvider =
    FutureProvider.family<List<FeeInvoice>, String>((ref, studentId) async {
      final school = ref.watch(currentSchoolProvider);
      if (school == null) return [];
      final repo = ref.read(feeRepositoryProvider);
      return repo.fetchFeeInvoices(schoolId: school.id, studentId: studentId);
    });

final feeInvoiceProvider = FutureProvider.family<FeeInvoice, String>((
  ref,
  invoiceId,
) async {
  final repo = ref.read(feeRepositoryProvider);
  return repo.getFeeInvoice(invoiceId);
});

// Fee Payments
final feePaymentsProvider = FutureProvider<List<FeePayment>>((ref) async {
  final school = ref.watch(currentSchoolProvider);
  if (school == null) return [];
  final repo = ref.read(feeRepositoryProvider);
  return repo.fetchFeePayments(schoolId: school.id);
});

final invoicePaymentsProvider = FutureProvider.family<List<FeePayment>, String>(
  (ref, invoiceId) async {
    final school = ref.watch(currentSchoolProvider);
    if (school == null) return [];
    final repo = ref.read(feeRepositoryProvider);
    return repo.fetchFeePayments(schoolId: school.id, invoiceId: invoiceId);
  },
);

// Fee Summary
final studentFeeSummaryProvider = FutureProvider.family<FeeSummary, String>((
  ref,
  studentId,
) async {
  final school = ref.watch(currentSchoolProvider);
  if (school == null) {
    return const FeeSummary(
      totalInvoices: 0,
      pendingInvoices: 0,
      paidInvoices: 0,
      overdueInvoices: 0,
      totalDueAmount: 0,
      totalPaidAmount: 0,
      totalOutstanding: 0,
    );
  }
  final repo = ref.read(feeRepositoryProvider);
  return repo.getStudentFeeSummary(studentId: studentId, schoolId: school.id);
});
