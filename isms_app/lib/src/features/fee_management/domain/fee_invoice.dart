import 'package:equatable/equatable.dart';

import 'invoice_status.dart';

/// Fee invoice/challan model
class FeeInvoice extends Equatable {
  const FeeInvoice({
    required this.id,
    required this.schoolId,
    required this.studentId,
    required this.invoiceNumber,
    required this.dueDate,
    required this.totalAmount,
    this.invoiceType = InvoiceType.fee,
    this.issueDate,
    this.status = InvoiceStatus.pending,
    this.paidAmount = 0,
    this.discountAmount = 0,
    this.lateFeeAmount = 0,
    this.currency = 'PKR',
    this.notes,
    this.metadata,
    this.createdBy,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String schoolId;
  final String studentId;
  final String invoiceNumber;
  final InvoiceType invoiceType;
  final DateTime? issueDate;
  final DateTime dueDate;
  final InvoiceStatus status;
  final double totalAmount;
  final double paidAmount;
  final double discountAmount;
  final double lateFeeAmount;
  final String currency;
  final String? notes;
  final Map<String, dynamic>? metadata;
  final String? createdBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  double get outstandingAmount => totalAmount - paidAmount;
  bool get isPaid => status == InvoiceStatus.paid;
  bool get isOverdue =>
      status == InvoiceStatus.overdue ||
      (status == InvoiceStatus.pending && dueDate.isBefore(DateTime.now()));
  bool get isPartiallyPaid => status == InvoiceStatus.partial;

  factory FeeInvoice.fromMap(Map<String, dynamic> map) {
    return FeeInvoice(
      id: map['id'] as String,
      schoolId: map['school_id'] as String,
      studentId: map['student_id'] as String,
      invoiceNumber: map['invoice_number'] as String,
      invoiceType: InvoiceType.fromDb(map['invoice_type'] as String? ?? 'fee'),
      issueDate: map['issue_date'] != null
          ? DateTime.parse(map['issue_date'] as String)
          : null,
      dueDate: DateTime.parse(map['due_date'] as String),
      status: InvoiceStatus.fromDb(map['status'] as String? ?? 'pending'),
      totalAmount: (map['total_amount'] as num).toDouble(),
      paidAmount: (map['paid_amount'] as num?)?.toDouble() ?? 0,
      discountAmount: (map['discount_amount'] as num?)?.toDouble() ?? 0,
      lateFeeAmount: (map['late_fee_amount'] as num?)?.toDouble() ?? 0,
      currency: map['currency'] as String? ?? 'PKR',
      notes: map['notes'] as String?,
      metadata: map['metadata'] != null
          ? Map<String, dynamic>.from(map['metadata'] as Map)
          : null,
      createdBy: map['created_by'] as String?,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'school_id': schoolId,
      'student_id': studentId,
      'invoice_number': invoiceNumber,
      'invoice_type': invoiceType.dbValue,
      'issue_date': issueDate?.toIso8601String().split('T')[0],
      'due_date': dueDate.toIso8601String().split('T')[0],
      'status': status.dbValue,
      'total_amount': totalAmount,
      'paid_amount': paidAmount,
      'discount_amount': discountAmount,
      'late_fee_amount': lateFeeAmount,
      'currency': currency,
      'notes': notes,
      'metadata': metadata,
      'created_by': createdBy,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
    id,
    schoolId,
    studentId,
    invoiceNumber,
    invoiceType,
    issueDate,
    dueDate,
    status,
    totalAmount,
    paidAmount,
    discountAmount,
    lateFeeAmount,
    currency,
    notes,
    metadata,
    createdBy,
    createdAt,
    updatedAt,
  ];
}
