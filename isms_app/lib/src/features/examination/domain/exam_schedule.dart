import 'package:equatable/equatable.dart';

class ExamSchedule extends Equatable {
  const ExamSchedule({
    required this.id,
    required this.schoolId,
    required this.examId,
    required this.examDate,
    this.subjectId,
    this.classId,
    this.sectionId,
    this.startTime,
    this.endTime,
    this.durationMinutes,
    this.venue,
    this.instructions,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String schoolId;
  final int examId;
  final int? subjectId;
  final int? classId;
  final int? sectionId;
  final DateTime examDate;
  final DateTime? startTime;
  final DateTime? endTime;
  final int? durationMinutes;
  final String? venue;
  final String? instructions;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory ExamSchedule.fromMap(Map<String, dynamic> map) {
    return ExamSchedule(
      id: map['id'] as String,
      schoolId: map['school_id'] as String,
      examId: map['exam_id'] as int,
      subjectId: map['subject_id'] as int?,
      classId: map['class_id'] as int?,
      sectionId: map['section_id'] as int?,
      examDate: DateTime.parse(map['exam_date'] as String),
      startTime: map['start_time'] != null
          ? DateTime.parse('2000-01-01 ${map['start_time']}')
          : null,
      endTime: map['end_time'] != null
          ? DateTime.parse('2000-01-01 ${map['end_time']}')
          : null,
      durationMinutes: map['duration_minutes'] as int?,
      venue: map['venue'] as String?,
      instructions: map['instructions'] as String?,
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
      'subject_id': subjectId,
      'class_id': classId,
      'section_id': sectionId,
      'exam_date': examDate.toIso8601String().split('T')[0],
      'start_time': startTime?.toIso8601String().split('T')[1].substring(0, 8),
      'end_time': endTime?.toIso8601String().split('T')[1].substring(0, 8),
      'duration_minutes': durationMinutes,
      'venue': venue,
      'instructions': instructions,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
    id,
    schoolId,
    examId,
    subjectId,
    classId,
    sectionId,
    examDate,
    startTime,
    endTime,
    durationMinutes,
    venue,
    instructions,
    createdAt,
    updatedAt,
  ];
}
