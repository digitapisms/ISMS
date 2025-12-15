import 'package:equatable/equatable.dart';

import '../../examination/domain/exam_type.dart';

class Timetable extends Equatable {
  const Timetable({
    required this.id,
    required this.schoolId,
    required this.name,
    required this.classId,
    required this.academicYear,
    this.sectionId,
    this.term,
    this.effectiveFrom,
    this.effectiveTo,
    this.isActive = true,
    this.createdBy,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String schoolId;
  final String name;
  final int classId;
  final int? sectionId;
  final String academicYear;
  final Term? term;
  final DateTime? effectiveFrom;
  final DateTime? effectiveTo;
  final bool isActive;
  final String? createdBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory Timetable.fromMap(Map<String, dynamic> map) {
    return Timetable(
      id: map['id'] as String,
      schoolId: map['school_id'] as String,
      name: map['name'] as String,
      classId: map['class_id'] as int,
      sectionId: map['section_id'] as int?,
      academicYear: map['academic_year'] as String,
      term: TermX.fromDb(map['term'] as String?),
      effectiveFrom: map['effective_from'] != null
          ? DateTime.parse(map['effective_from'] as String)
          : null,
      effectiveTo: map['effective_to'] != null
          ? DateTime.parse(map['effective_to'] as String)
          : null,
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
      'class_id': classId,
      'section_id': sectionId,
      'academic_year': academicYear,
      'term': term?.dbValue,
      'effective_from': effectiveFrom?.toIso8601String().split('T')[0],
      'effective_to': effectiveTo?.toIso8601String().split('T')[0],
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
    classId,
    sectionId,
    academicYear,
    term,
    effectiveFrom,
    effectiveTo,
    isActive,
    createdBy,
    createdAt,
    updatedAt,
  ];
}
