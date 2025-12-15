import 'package:equatable/equatable.dart';

import 'attendance_status.dart';

class AttendanceRecord extends Equatable {
  const AttendanceRecord({
    required this.id,
    required this.schoolId,
    required this.studentId,
    required this.attendanceDate,
    required this.status,
    this.classId,
    this.sectionId,
    this.markedBy,
    this.markedAt,
    this.notes,
    this.periodNumber,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String schoolId;
  final String studentId;
  final DateTime attendanceDate;
  final AttendanceStatus status;
  final int? classId;
  final int? sectionId;
  final String? markedBy;
  final DateTime? markedAt;
  final String? notes;
  final int? periodNumber;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory AttendanceRecord.fromMap(Map<String, dynamic> map) {
    return AttendanceRecord(
      id: map['id'] as String,
      schoolId: map['school_id'] as String,
      studentId: map['student_id'] as String,
      attendanceDate: DateTime.parse(map['attendance_date'] as String),
      status: AttendanceStatus.fromDb(map['status'] as String? ?? 'present'),
      classId: map['class_id'] as int?,
      sectionId: map['section_id'] as int?,
      markedBy: map['marked_by'] as String?,
      markedAt: map['marked_at'] != null
          ? DateTime.parse(map['marked_at'] as String)
          : null,
      notes: map['notes'] as String?,
      periodNumber: map['period_number'] as int?,
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
      'attendance_date': attendanceDate.toIso8601String().split('T')[0],
      'status': status.dbValue,
      if (classId != null) 'class_id': classId,
      if (sectionId != null) 'section_id': sectionId,
      if (markedBy != null) 'marked_by': markedBy,
      if (notes != null) 'notes': notes,
      if (periodNumber != null) 'period_number': periodNumber,
    };
  }

  @override
  List<Object?> get props => [
    id,
    schoolId,
    studentId,
    attendanceDate,
    status,
    classId,
    sectionId,
    markedBy,
    markedAt,
    notes,
    periodNumber,
    createdAt,
    updatedAt,
  ];
}
