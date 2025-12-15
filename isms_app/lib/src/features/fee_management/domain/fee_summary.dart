import 'package:equatable/equatable.dart';

/// Student fee summary model
class FeeSummary extends Equatable {
  const FeeSummary({
    required this.totalInvoices,
    required this.pendingInvoices,
    required this.paidInvoices,
    required this.overdueInvoices,
    required this.totalDueAmount,
    required this.totalPaidAmount,
    required this.totalOutstanding,
  });

  final int totalInvoices;
  final int pendingInvoices;
  final int paidInvoices;
  final int overdueInvoices;
  final double totalDueAmount;
  final double totalPaidAmount;
  final double totalOutstanding;

  factory FeeSummary.fromMap(Map<String, dynamic> map) {
    return FeeSummary(
      totalInvoices: map['total_invoices'] as int? ?? 0,
      pendingInvoices: map['pending_invoices'] as int? ?? 0,
      paidInvoices: map['paid_invoices'] as int? ?? 0,
      overdueInvoices: map['overdue_invoices'] as int? ?? 0,
      totalDueAmount: (map['total_due_amount'] as num?)?.toDouble() ?? 0,
      totalPaidAmount: (map['total_paid_amount'] as num?)?.toDouble() ?? 0,
      totalOutstanding: (map['total_outstanding'] as num?)?.toDouble() ?? 0,
    );
  }

  @override
  List<Object?> get props => [
    totalInvoices,
    pendingInvoices,
    paidInvoices,
    overdueInvoices,
    totalDueAmount,
    totalPaidAmount,
    totalOutstanding,
  ];
}
