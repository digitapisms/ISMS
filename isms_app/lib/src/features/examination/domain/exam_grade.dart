import 'package:equatable/equatable.dart';

class ExamGrade extends Equatable {
  const ExamGrade({
    required this.id,
    required this.schoolId,
    required this.examId,
    required this.studentId,
    required this.marksObtained,
    required this.totalMarks,
    this.examScheduleId,
    this.subjectId,
    this.percentage,
    this.grade,
    this.gradePoint,
    this.remarks,
    this.isAbsent = false,
    this.isExempted = false,
    this.enteredBy,
    this.approvedBy,
    this.approvedAt,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String schoolId;
  final int examId;
  final String? examScheduleId;
  final String studentId;
  final int? subjectId;
  final double marksObtained;
  final double totalMarks;
  final double? percentage;
  final String? grade;
  final double? gradePoint;
  final String? remarks;
  final bool isAbsent;
  final bool isExempted;
  final String? enteredBy;
  final String? approvedBy;
  final DateTime? approvedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory ExamGrade.fromMap(Map<String, dynamic> map) {
    return ExamGrade(
      id: map['id'] as String,
      schoolId: map['school_id'] as String,
      examId: map['exam_id'] as int,
      examScheduleId: map['exam_schedule_id'] as String?,
      studentId: map['student_id'] as String,
      subjectId: map['subject_id'] as int?,
      marksObtained: (map['marks_obtained'] as num).toDouble(),
      totalMarks: (map['total_marks'] as num).toDouble(),
      percentage: (map['percentage'] as num?)?.toDouble(),
      grade: map['grade'] as String?,
      gradePoint: (map['grade_point'] as num?)?.toDouble(),
      remarks: map['remarks'] as String?,
      isAbsent: (map['is_absent'] as bool?) ?? false,
      isExempted: (map['is_exempted'] as bool?) ?? false,
      enteredBy: map['entered_by'] as String?,
      approvedBy: map['approved_by'] as String?,
      approvedAt: map['approved_at'] != null
          ? DateTime.parse(map['approved_at'] as String)
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
      'exam_id': examId,
      'exam_schedule_id': examScheduleId,
      'student_id': studentId,
      'subject_id': subjectId,
      'marks_obtained': marksObtained,
      'total_marks': totalMarks,
      'percentage': percentage,
      'grade': grade,
      'grade_point': gradePoint,
      'remarks': remarks,
      'is_absent': isAbsent,
      'is_exempted': isExempted,
      'entered_by': enteredBy,
      'approved_by': approvedBy,
      'approved_at': approvedAt?.toIso8601String(),
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
    id,
    schoolId,
    examId,
    examScheduleId,
    studentId,
    subjectId,
    marksObtained,
    totalMarks,
    percentage,
    grade,
    gradePoint,
    remarks,
    isAbsent,
    isExempted,
    enteredBy,
    approvedBy,
    approvedAt,
    createdAt,
    updatedAt,
  ];
}
