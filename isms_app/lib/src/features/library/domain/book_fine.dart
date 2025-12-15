import 'package:equatable/equatable.dart';

import 'book_type.dart';

enum FineType {
  overdue,
  damage,
  loss,
}

extension FineTypeX on FineType {
  String get dbValue {
    switch (this) {
      case FineType.overdue:
        return 'overdue';
      case FineType.damage:
        return 'damage';
      case FineType.loss:
        return 'loss';
    }
  }

  String get displayName {
    switch (this) {
      case FineType.overdue:
        return 'Overdue';
      case FineType.damage:
        return 'Damage';
      case FineType.loss:
        return 'Loss';
    }
  }

  static FineType fromDb(String value) {
    switch (value) {
      case 'overdue':
        return FineType.overdue;
      case 'damage':
        return FineType.damage;
      case 'loss':
        return FineType.loss;
      default:
        return FineType.overdue;
    }
  }
}

class BookFine extends Equatable {
  const BookFine({
    required this.id,
    required this.schoolId,
    required this.issueId,
    required this.amount,
    this.returnId,
    this.studentId,
    this.staffId,
    this.fineType = FineType.overdue,
    this.daysOverdue = 0,
    this.description,
    this.status = FineStatus.pending,
    this.paidAt,
    this.paidBy,
    this.paymentMethod,
    this.waivedBy,
    this.waivedAt,
    this.waiverReason,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String schoolId;
  final String issueId;
  final String? returnId;
  final String? studentId;
  final String? staffId;
  final FineType fineType;
  final double amount;
  final int daysOverdue;
  final String? description;
  final FineStatus status;
  final DateTime? paidAt;
  final String? paidBy;
  final String? paymentMethod;
  final String? waivedBy;
  final DateTime? waivedAt;
  final String? waiverReason;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory BookFine.fromMap(Map<String, dynamic> map) {
    return BookFine(
      id: map['id'] as String,
      schoolId: map['school_id'] as String,
      issueId: map['issue_id'] as String,
      returnId: map['return_id'] as String?,
      studentId: map['student_id'] as String?,
      staffId: map['staff_id'] as String?,
      fineType: FineTypeX.fromDb(map['fine_type'] as String? ?? 'overdue'),
      amount: (map['amount'] as num).toDouble(),
      daysOverdue: (map['days_overdue'] as int?) ?? 0,
      description: map['description'] as String?,
      status: FineStatusX.fromDb(map['status'] as String? ?? 'pending'),
      paidAt: map['paid_at'] != null
          ? DateTime.parse(map['paid_at'] as String)
          : null,
      paidBy: map['paid_by'] as String?,
      paymentMethod: map['payment_method'] as String?,
      waivedBy: map['waived_by'] as String?,
      waivedAt: map['waived_at'] != null
          ? DateTime.parse(map['waived_at'] as String)
          : null,
      waiverReason: map['waiver_reason'] as String?,
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
      'issue_id': issueId,
      'return_id': returnId,
      'student_id': studentId,
      'staff_id': staffId,
      'fine_type': fineType.dbValue,
      'amount': amount,
      'days_overdue': daysOverdue,
      'description': description,
      'status': status.dbValue,
      'paid_at': paidAt?.toIso8601String(),
      'paid_by': paidBy,
      'payment_method': paymentMethod,
      'waived_by': waivedBy,
      'waived_at': waivedAt?.toIso8601String(),
      'waiver_reason': waiverReason,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
        id,
        schoolId,
        issueId,
        returnId,
        studentId,
        staffId,
        fineType,
        amount,
        daysOverdue,
        description,
        status,
        paidAt,
        paidBy,
        paymentMethod,
        waivedBy,
        waivedAt,
        waiverReason,
        createdAt,
        updatedAt,
      ];
}

