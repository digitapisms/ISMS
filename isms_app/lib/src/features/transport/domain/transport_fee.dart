import 'package:equatable/equatable.dart';

import 'transport_type.dart';

class TransportFee extends Equatable {
  const TransportFee({
    required this.id,
    required this.schoolId,
    required this.assignmentId,
    required this.studentId,
    required this.routeId,
    required this.feeMonth,
    required this.amount,
    this.dueDate,
    this.paidDate,
    this.paymentMethod,
    this.paymentReference,
    this.challanNumber,
    this.voucherNumber,
    this.status = FeeStatus.pending,
    this.waivedBy,
    this.waivedAt,
    this.waiverReason,
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String schoolId;
  final String assignmentId;
  final String studentId;
  final int routeId;
  final DateTime feeMonth;
  final double amount;
  final DateTime? dueDate;
  final DateTime? paidDate;
  final String? paymentMethod;
  final String? paymentReference;
  final String? challanNumber;
  final String? voucherNumber;
  final FeeStatus status;
  final String? waivedBy;
  final DateTime? waivedAt;
  final String? waiverReason;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory TransportFee.fromMap(Map<String, dynamic> map) {
    return TransportFee(
      id: map['id'] as String,
      schoolId: map['school_id'] as String,
      assignmentId: map['assignment_id'] as String,
      studentId: map['student_id'] as String,
      routeId: map['route_id'] as int,
      feeMonth: DateTime.parse(map['fee_month'] as String),
      amount: (map['amount'] as num).toDouble(),
      dueDate: map['due_date'] != null
          ? DateTime.parse(map['due_date'] as String)
          : null,
      paidDate: map['paid_date'] != null
          ? DateTime.parse(map['paid_date'] as String)
          : null,
      paymentMethod: map['payment_method'] as String?,
      paymentReference: map['payment_reference'] as String?,
      challanNumber: map['challan_number'] as String?,
      voucherNumber: map['voucher_number'] as String?,
      status: FeeStatusX.fromDb(map['status'] as String? ?? 'pending'),
      waivedBy: map['waived_by'] as String?,
      waivedAt: map['waived_at'] != null
          ? DateTime.parse(map['waived_at'] as String)
          : null,
      waiverReason: map['waiver_reason'] as String?,
      notes: map['notes'] as String?,
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
      'assignment_id': assignmentId,
      'student_id': studentId,
      'route_id': routeId,
      'fee_month': feeMonth.toIso8601String().split('T')[0],
      'amount': amount,
      'due_date': dueDate?.toIso8601String().split('T')[0],
      'paid_date': paidDate?.toIso8601String().split('T')[0],
      'payment_method': paymentMethod,
      'payment_reference': paymentReference,
      'challan_number': challanNumber,
      'voucher_number': voucherNumber,
      'status': status.dbValue,
      'waived_by': waivedBy,
      'waived_at': waivedAt?.toIso8601String(),
      'waiver_reason': waiverReason,
      'notes': notes,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  bool get isOverdue {
    if (status != FeeStatus.pending) return false;
    if (dueDate == null) return false;
    return DateTime.now().isAfter(dueDate!);
  }

  @override
  List<Object?> get props => [
        id,
        schoolId,
        assignmentId,
        studentId,
        routeId,
        feeMonth,
        amount,
        dueDate,
        paidDate,
        paymentMethod,
        paymentReference,
        challanNumber,
        voucherNumber,
        status,
        waivedBy,
        waivedAt,
        waiverReason,
        notes,
        createdAt,
        updatedAt,
      ];
}

