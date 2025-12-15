import 'package:equatable/equatable.dart';

enum ReportCardStatus { draft, published, archived }

extension ReportCardStatusX on ReportCardStatus {
  String get dbValue {
    switch (this) {
      case ReportCardStatus.draft:
        return 'draft';
      case ReportCardStatus.published:
        return 'published';
      case ReportCardStatus.archived:
        return 'archived';
    }
  }

  String get displayName {
    switch (this) {
      case ReportCardStatus.draft:
        return 'Draft';
      case ReportCardStatus.published:
        return 'Published';
      case ReportCardStatus.archived:
        return 'Archived';
    }
  }

  static ReportCardStatus fromDb(String value) {
    switch (value) {
      case 'draft':
        return ReportCardStatus.draft;
      case 'published':
        return ReportCardStatus.published;
      case 'archived':
        return ReportCardStatus.archived;
      default:
        return ReportCardStatus.draft;
    }
  }
}

class ReportCard extends Equatable {
  const ReportCard({
    required this.id,
    required this.schoolId,
    required this.studentId,
    required this.classId,
    required this.academicYear,
    required this.term,
    this.sectionId,
    this.totalSubjects = 0,
    this.totalMarks,
    this.marksObtained,
    this.overallPercentage,
    this.overallGrade,
    this.overallGradePoint,
    this.classPosition,
    this.totalStudents,
    this.division,
    this.attendancePercentage,
    this.teacherRemarks,
    this.principalRemarks,
    this.parentSignatureRequired = true,
    this.parentSignedAt,
    this.status = ReportCardStatus.draft,
    this.generatedBy,
    this.generatedAt,
    this.createdAt,
    this.updatedAt,
  });

  final int id;
  final String schoolId;
  final String studentId;
  final int classId;
  final int? sectionId;
  final String academicYear;
  final String term;
  final int totalSubjects;
  final double? totalMarks;
  final double? marksObtained;
  final double? overallPercentage;
  final String? overallGrade;
  final double? overallGradePoint;
  final int? classPosition;
  final int? totalStudents;
  final String? division;
  final double? attendancePercentage;
  final String? teacherRemarks;
  final String? principalRemarks;
  final bool parentSignatureRequired;
  final DateTime? parentSignedAt;
  final ReportCardStatus status;
  final String? generatedBy;
  final DateTime? generatedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory ReportCard.fromMap(Map<String, dynamic> map) {
    return ReportCard(
      id: map['id'] as int,
      schoolId: map['school_id'] as String? ?? '',
      studentId: map['student_id'] as String,
      classId: map['class_id'] as int,
      sectionId: map['section_id'] as int?,
      academicYear: map['academic_year'] as String,
      term: map['term'] as String,
      totalSubjects: (map['total_subjects'] as int?) ?? 0,
      totalMarks: (map['total_marks'] as num?)?.toDouble(),
      marksObtained: (map['marks_obtained'] as num?)?.toDouble(),
      overallPercentage:
          (map['overall_percentage'] as num?)?.toDouble() ??
          (map['percentage'] as num?)?.toDouble(),
      overallGrade: map['overall_grade'] as String?,
      overallGradePoint: (map['overall_grade_point'] as num?)?.toDouble(),
      classPosition: map['class_position'] as int? ?? map['rank'] as int?,
      totalStudents: map['total_students'] as int?,
      division: map['division'] as String?,
      attendancePercentage: (map['attendance_percentage'] as num?)?.toDouble(),
      teacherRemarks: map['teacher_remarks'] as String?,
      principalRemarks: map['principal_remarks'] as String?,
      parentSignatureRequired:
          (map['parent_signature_required'] as bool?) ?? true,
      parentSignedAt: map['parent_signed_at'] != null
          ? DateTime.parse(map['parent_signed_at'] as String)
          : null,
      status: ReportCardStatusX.fromDb(map['status'] as String? ?? 'draft'),
      generatedBy: map['generated_by'] as String?,
      generatedAt: map['generated_at'] != null
          ? DateTime.parse(map['generated_at'] as String)
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
      'student_id': studentId,
      'class_id': classId,
      'section_id': sectionId,
      'academic_year': academicYear,
      'term': term,
      'total_subjects': totalSubjects,
      'total_marks': totalMarks,
      'marks_obtained': marksObtained,
      'overall_percentage': overallPercentage,
      'overall_grade': overallGrade,
      'overall_grade_point': overallGradePoint,
      'class_position': classPosition,
      'total_students': totalStudents,
      'division': division,
      'attendance_percentage': attendancePercentage,
      'teacher_remarks': teacherRemarks,
      'principal_remarks': principalRemarks,
      'parent_signature_required': parentSignatureRequired,
      'parent_signed_at': parentSignedAt?.toIso8601String(),
      'status': status.dbValue,
      'generated_by': generatedBy,
      'generated_at': generatedAt?.toIso8601String(),
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
    id,
    schoolId,
    studentId,
    classId,
    sectionId,
    academicYear,
    term,
    totalSubjects,
    totalMarks,
    marksObtained,
    overallPercentage,
    overallGrade,
    overallGradePoint,
    classPosition,
    totalStudents,
    division,
    attendancePercentage,
    teacherRemarks,
    principalRemarks,
    parentSignatureRequired,
    parentSignedAt,
    status,
    generatedBy,
    generatedAt,
    createdAt,
    updatedAt,
  ];
}
