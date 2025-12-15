import 'package:equatable/equatable.dart';

import 'book_type.dart';

class BookReturn extends Equatable {
  const BookReturn({
    required this.id,
    required this.schoolId,
    required this.issueId,
    required this.returnedBy,
    required this.returnDate,
    this.conditionOnReturn = BookCondition.good,
    this.daysOverdue = 0,
    this.fineAmount = 0.0,
    this.finePaid = false,
    this.damageNotes,
    this.notes,
    this.createdAt,
  });

  final String id;
  final String schoolId;
  final String issueId;
  final String returnedBy;
  final DateTime returnDate;
  final BookCondition conditionOnReturn;
  final int daysOverdue;
  final double fineAmount;
  final bool finePaid;
  final String? damageNotes;
  final String? notes;
  final DateTime? createdAt;

  factory BookReturn.fromMap(Map<String, dynamic> map) {
    return BookReturn(
      id: map['id'] as String,
      schoolId: map['school_id'] as String,
      issueId: map['issue_id'] as String,
      returnedBy: map['returned_by'] as String,
      returnDate: DateTime.parse(map['return_date'] as String),
      conditionOnReturn: BookConditionX.fromDb(
        map['condition_on_return'] as String? ?? 'good',
      ),
      daysOverdue: (map['days_overdue'] as int?) ?? 0,
      fineAmount: (map['fine_amount'] as num?)?.toDouble() ?? 0.0,
      finePaid: (map['fine_paid'] as bool?) ?? false,
      damageNotes: map['damage_notes'] as String?,
      notes: map['notes'] as String?,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'school_id': schoolId,
      'issue_id': issueId,
      'returned_by': returnedBy,
      'return_date': returnDate.toIso8601String().split('T')[0],
      'condition_on_return': conditionOnReturn.dbValue,
      'days_overdue': daysOverdue,
      'fine_amount': fineAmount,
      'fine_paid': finePaid,
      'damage_notes': damageNotes,
      'notes': notes,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
        id,
        schoolId,
        issueId,
        returnedBy,
        returnDate,
        conditionOnReturn,
        daysOverdue,
        fineAmount,
        finePaid,
        damageNotes,
        notes,
        createdAt,
      ];
}

