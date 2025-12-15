import 'package:equatable/equatable.dart';

import '../../examination/domain/exam_type.dart';

class TeacherAssignment extends Equatable {
  const TeacherAssignment({
    required this.id,
    required this.schoolId,
    required this.teacherId,
    required this.academicYear,
    this.subjectId,
    this.classId,
    this.sectionId,
    this.term,
    this.isPrimary = true,
    this.workloadHours,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String schoolId;
  final String teacherId;
  final int? subjectId;
  final int? classId;
  final int? sectionId;
  final String academicYear;
  final Term? term;
  final bool isPrimary;
  final double? workloadHours;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory TeacherAssignment.fromMap(Map<String, dynamic> map) {
    return TeacherAssignment(
      id: map['id'] as String,
      schoolId: map['school_id'] as String,
      teacherId: map['teacher_id'] as String,
      subjectId: map['subject_id'] as int?,
      classId: map['class_id'] as int?,
      sectionId: map['section_id'] as int?,
      academicYear: map['academic_year'] as String,
      term: TermX.fromDb(map['term'] as String?),
      isPrimary: (map['is_primary'] as bool?) ?? true,
      workloadHours: (map['workload_hours'] as num?)?.toDouble(),
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
      'teacher_id': teacherId,
      'subject_id': subjectId,
      'class_id': classId,
      'section_id': sectionId,
      'academic_year': academicYear,
      'term': term?.dbValue,
      'is_primary': isPrimary,
      'workload_hours': workloadHours,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
    id,
    schoolId,
    teacherId,
    subjectId,
    classId,
    sectionId,
    academicYear,
    term,
    isPrimary,
    workloadHours,
    createdAt,
    updatedAt,
  ];
}
