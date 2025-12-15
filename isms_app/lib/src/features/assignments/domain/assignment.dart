import 'package:equatable/equatable.dart';

import 'assignment_type.dart';

class Assignment extends Equatable {
  const Assignment({
    required this.id,
    required this.schoolId,
    required this.title,
    required this.classId,
    required this.teacherId,
    required this.academicYear,
    required this.dueDate,
    this.description,
    this.assignmentType = AssignmentType.homework,
    this.subjectId,
    this.sectionId,
    this.term,
    this.maxPoints = 100.0,
    this.weightage,
    this.instructions,
    this.rubric,
    this.allowLateSubmission = true,
    this.latePenaltyPerDay = 0.0,
    this.allowResubmission = false,
    this.isPublished = false,
    this.publishedAt,
    this.createdBy,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String schoolId;
  final String title;
  final String? description;
  final AssignmentType assignmentType;
  final int? subjectId;
  final int classId;
  final int? sectionId;
  final String teacherId;
  final String academicYear;
  final String? term;
  final DateTime dueDate;
  final double maxPoints;
  final double? weightage;
  final String? instructions;
  final Map<String, dynamic>? rubric;
  final bool allowLateSubmission;
  final double latePenaltyPerDay;
  final bool allowResubmission;
  final bool isPublished;
  final DateTime? publishedAt;
  final String? createdBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory Assignment.fromMap(Map<String, dynamic> map) {
    return Assignment(
      id: map['id'] as String,
      schoolId: map['school_id'] as String,
      title: map['title'] as String,
      description: map['description'] as String?,
      assignmentType: AssignmentTypeX.fromDb(
        map['assignment_type'] as String? ?? 'homework',
      ),
      subjectId: map['subject_id'] as int?,
      classId: map['class_id'] as int,
      sectionId: map['section_id'] as int?,
      teacherId: map['teacher_id'] as String,
      academicYear: map['academic_year'] as String,
      term: map['term'] as String?,
      dueDate: DateTime.parse(map['due_date'] as String),
      maxPoints: (map['max_points'] as num?)?.toDouble() ?? 100.0,
      weightage: (map['weightage'] as num?)?.toDouble(),
      instructions: map['instructions'] as String?,
      rubric: map['rubric'] as Map<String, dynamic>?,
      allowLateSubmission: (map['allow_late_submission'] as bool?) ?? true,
      latePenaltyPerDay:
          (map['late_penalty_per_day'] as num?)?.toDouble() ?? 0.0,
      allowResubmission: (map['allow_resubmission'] as bool?) ?? false,
      isPublished: (map['is_published'] as bool?) ?? false,
      publishedAt: map['published_at'] != null
          ? DateTime.parse(map['published_at'] as String)
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
      'title': title,
      'description': description,
      'assignment_type': assignmentType.dbValue,
      'subject_id': subjectId,
      'class_id': classId,
      'section_id': sectionId,
      'teacher_id': teacherId,
      'academic_year': academicYear,
      'term': term,
      'due_date': dueDate.toIso8601String(),
      'max_points': maxPoints,
      'weightage': weightage,
      'instructions': instructions,
      'rubric': rubric,
      'allow_late_submission': allowLateSubmission,
      'late_penalty_per_day': latePenaltyPerDay,
      'allow_resubmission': allowResubmission,
      'is_published': isPublished,
      'published_at': publishedAt?.toIso8601String(),
      'created_by': createdBy,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  bool get isOverdue {
    return DateTime.now().isAfter(dueDate) && !isPublished;
  }

  int get daysUntilDue {
    final now = DateTime.now();
    if (now.isAfter(dueDate)) return 0;
    return dueDate.difference(now).inDays;
  }

  @override
  List<Object?> get props => [
    id,
    schoolId,
    title,
    description,
    assignmentType,
    subjectId,
    classId,
    sectionId,
    teacherId,
    academicYear,
    term,
    dueDate,
    maxPoints,
    weightage,
    instructions,
    rubric,
    allowLateSubmission,
    latePenaltyPerDay,
    allowResubmission,
    isPublished,
    publishedAt,
    createdBy,
    createdAt,
    updatedAt,
  ];
}
