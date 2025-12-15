import 'package:equatable/equatable.dart';

import 'assignment_type.dart';

class AssignmentSubmission extends Equatable {
  const AssignmentSubmission({
    required this.id,
    required this.schoolId,
    required this.assignmentId,
    required this.studentId,
    this.submissionText,
    this.submissionStatus = SubmissionStatus.notStarted,
    this.submittedAt,
    this.isLate = false,
    this.daysLate = 0,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String schoolId;
  final String assignmentId;
  final String studentId;
  final String? submissionText;
  final SubmissionStatus submissionStatus;
  final DateTime? submittedAt;
  final bool isLate;
  final int daysLate;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory AssignmentSubmission.fromMap(Map<String, dynamic> map) {
    return AssignmentSubmission(
      id: map['id'] as String,
      schoolId: map['school_id'] as String,
      assignmentId: map['assignment_id'] as String,
      studentId: map['student_id'] as String,
      submissionText: map['submission_text'] as String?,
      submissionStatus: SubmissionStatusX.fromDb(
        map['submission_status'] as String? ?? 'not_started',
      ),
      submittedAt: map['submitted_at'] != null
          ? DateTime.parse(map['submitted_at'] as String)
          : null,
      isLate: (map['is_late'] as bool?) ?? false,
      daysLate: (map['days_late'] as int?) ?? 0,
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
      'submission_text': submissionText,
      'submission_status': submissionStatus.dbValue,
      'submitted_at': submittedAt?.toIso8601String(),
      'is_late': isLate,
      'days_late': daysLate,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
    id,
    schoolId,
    assignmentId,
    studentId,
    submissionText,
    submissionStatus,
    submittedAt,
    isLate,
    daysLate,
    createdAt,
    updatedAt,
  ];
}
