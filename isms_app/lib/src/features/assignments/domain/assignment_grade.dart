import 'package:equatable/equatable.dart';

class AssignmentGrade extends Equatable {
  const AssignmentGrade({
    required this.id,
    required this.schoolId,
    required this.submissionId,
    required this.assignmentId,
    required this.studentId,
    this.pointsObtained,
    this.maxPoints,
    this.percentage,
    this.grade,
    this.gradePoint,
    this.teacherFeedback,
    this.rubricScores,
    this.gradedBy,
    this.gradedAt,
    this.isPublished = false,
    this.publishedAt,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String schoolId;
  final String submissionId;
  final String assignmentId;
  final String studentId;
  final double? pointsObtained;
  final double? maxPoints;
  final double? percentage;
  final String? grade;
  final double? gradePoint;
  final String? teacherFeedback;
  final Map<String, dynamic>? rubricScores;
  final String? gradedBy;
  final DateTime? gradedAt;
  final bool isPublished;
  final DateTime? publishedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory AssignmentGrade.fromMap(Map<String, dynamic> map) {
    return AssignmentGrade(
      id: map['id'] as String,
      schoolId: map['school_id'] as String,
      submissionId: map['submission_id'] as String,
      assignmentId: map['assignment_id'] as String,
      studentId: map['student_id'] as String,
      pointsObtained: (map['points_obtained'] as num?)?.toDouble(),
      maxPoints: (map['max_points'] as num?)?.toDouble(),
      percentage: (map['percentage'] as num?)?.toDouble(),
      grade: map['grade'] as String?,
      gradePoint: (map['grade_point'] as num?)?.toDouble(),
      teacherFeedback: map['teacher_feedback'] as String?,
      rubricScores: map['rubric_scores'] as Map<String, dynamic>?,
      gradedBy: map['graded_by'] as String?,
      gradedAt: map['graded_at'] != null
          ? DateTime.parse(map['graded_at'] as String)
          : null,
      isPublished: (map['is_published'] as bool?) ?? false,
      publishedAt: map['published_at'] != null
          ? DateTime.parse(map['published_at'] as String)
          : null,
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
      'submission_id': submissionId,
      'assignment_id': assignmentId,
      'student_id': studentId,
      'points_obtained': pointsObtained,
      'max_points': maxPoints,
      'percentage': percentage,
      'grade': grade,
      'grade_point': gradePoint,
      'teacher_feedback': teacherFeedback,
      'rubric_scores': rubricScores,
      'graded_by': gradedBy,
      'graded_at': gradedAt?.toIso8601String(),
      'is_published': isPublished,
      'published_at': publishedAt?.toIso8601String(),
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
    id,
    schoolId,
    submissionId,
    assignmentId,
    studentId,
    pointsObtained,
    maxPoints,
    percentage,
    grade,
    gradePoint,
    teacherFeedback,
    rubricScores,
    gradedBy,
    gradedAt,
    isPublished,
    publishedAt,
    createdAt,
    updatedAt,
  ];
}
