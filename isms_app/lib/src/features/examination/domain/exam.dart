import 'package:equatable/equatable.dart';

import 'exam_type.dart';

class Exam extends Equatable {
  const Exam({
    required this.id,
    required this.schoolId,
    required this.name,
    required this.examType,
    this.academicYear,
    this.term,
    this.startDate,
    this.endDate,
    this.totalMarks = 100.0,
    this.passingMarks,
    this.description,
    this.status = ExamStatus.scheduled,
    this.isActive = true,
    this.createdBy,
    this.createdAt,
    this.updatedAt,
  });

  final int id;
  final String schoolId;
  final String name;
  final ExamType examType;
  final String? academicYear;
  final Term? term;
  final DateTime? startDate;
  final DateTime? endDate;
  final double totalMarks;
  final double? passingMarks;
  final String? description;
  final ExamStatus status;
  final bool isActive;
  final String? createdBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory Exam.fromMap(Map<String, dynamic> map) {
    return Exam(
      id: map['id'] as int,
      schoolId: map['school_id'] as String? ?? '',
      name: map['name'] as String,
      examType: ExamTypeX.fromDb(
        map['exam_type'] as String? ?? map['type'] as String? ?? 'test',
      ),
      academicYear: map['academic_year'] as String?,
      term: TermX.fromDb(map['term'] as String?),
      startDate: map['start_date'] != null
          ? DateTime.parse(map['start_date'] as String)
          : null,
      endDate: map['end_date'] != null
          ? DateTime.parse(map['end_date'] as String)
          : null,
      totalMarks: (map['total_marks'] as num?)?.toDouble() ?? 100.0,
      passingMarks: (map['passing_marks'] as num?)?.toDouble(),
      description: map['description'] as String?,
      status: ExamStatusX.fromDb(map['status'] as String? ?? 'scheduled'),
      isActive: (map['is_active'] as bool?) ?? true,
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
      'name': name,
      'exam_type': examType.dbValue,
      'academic_year': academicYear,
      'term': term?.dbValue,
      'start_date': startDate?.toIso8601String().split('T')[0],
      'end_date': endDate?.toIso8601String().split('T')[0],
      'total_marks': totalMarks,
      'passing_marks': passingMarks,
      'description': description,
      'status': status.dbValue,
      'is_active': isActive,
      'created_by': createdBy,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
    id,
    schoolId,
    name,
    examType,
    academicYear,
    term,
    startDate,
    endDate,
    totalMarks,
    passingMarks,
    description,
    status,
    isActive,
    createdBy,
    createdAt,
    updatedAt,
  ];
}
