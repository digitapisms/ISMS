import 'package:equatable/equatable.dart';

import 'book_type.dart';

class BookIssue extends Equatable {
  const BookIssue({
    required this.id,
    required this.schoolId,
    required this.bookId,
    required this.issuedBy,
    required this.issueDate,
    required this.dueDate,
    this.bookCopyId,
    this.studentId,
    this.staffId,
    this.returnDate,
    this.status = IssueStatus.issued,
    this.renewalCount = 0,
    this.maxRenewals = 1,
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String schoolId;
  final int bookId;
  final int? bookCopyId;
  final String? studentId;
  final String? staffId;
  final String issuedBy;
  final DateTime issueDate;
  final DateTime dueDate;
  final DateTime? returnDate;
  final IssueStatus status;
  final int renewalCount;
  final int maxRenewals;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory BookIssue.fromMap(Map<String, dynamic> map) {
    return BookIssue(
      id: map['id'] as String,
      schoolId: map['school_id'] as String,
      bookId: map['book_id'] as int,
      bookCopyId: map['book_copy_id'] as int?,
      studentId: map['student_id'] as String?,
      staffId: map['staff_id'] as String?,
      issuedBy: map['issued_by'] as String,
      issueDate: DateTime.parse(map['issue_date'] as String),
      dueDate: DateTime.parse(map['due_date'] as String),
      returnDate: map['return_date'] != null
          ? DateTime.parse(map['return_date'] as String)
          : null,
      status: IssueStatusX.fromDb(map['status'] as String? ?? 'issued'),
      renewalCount: (map['renewal_count'] as int?) ?? 0,
      maxRenewals: (map['max_renewals'] as int?) ?? 1,
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
      'book_id': bookId,
      'book_copy_id': bookCopyId,
      'student_id': studentId,
      'staff_id': staffId,
      'issued_by': issuedBy,
      'issue_date': issueDate.toIso8601String().split('T')[0],
      'due_date': dueDate.toIso8601String().split('T')[0],
      'return_date': returnDate?.toIso8601String().split('T')[0],
      'status': status.dbValue,
      'renewal_count': renewalCount,
      'max_renewals': maxRenewals,
      'notes': notes,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  bool get isOverdue {
    if (status != IssueStatus.issued) return false;
    return DateTime.now().isAfter(dueDate);
  }

  int get daysOverdue {
    if (!isOverdue) return 0;
    return DateTime.now().difference(dueDate).inDays;
  }

  bool get canRenew {
    return status == IssueStatus.issued && renewalCount < maxRenewals;
  }

  @override
  List<Object?> get props => [
        id,
        schoolId,
        bookId,
        bookCopyId,
        studentId,
        staffId,
        issuedBy,
        issueDate,
        dueDate,
        returnDate,
        status,
        renewalCount,
        maxRenewals,
        notes,
        createdAt,
        updatedAt,
      ];
}

