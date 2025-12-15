import 'package:equatable/equatable.dart';

class TimetableEntry extends Equatable {
  const TimetableEntry({
    required this.id,
    required this.schoolId,
    required this.timetableId,
    required this.dayOfWeek,
    required this.periodId,
    this.subjectId,
    this.teacherId,
    this.roomId,
    this.notes,
    this.isSubstitute = false,
    this.substituteTeacherId,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String schoolId;
  final String timetableId;
  final int dayOfWeek; // 1=Monday, 2=Tuesday, ..., 7=Sunday
  final int periodId;
  final int? subjectId;
  final String? teacherId;
  final int? roomId;
  final String? notes;
  final bool isSubstitute;
  final String? substituteTeacherId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory TimetableEntry.fromMap(Map<String, dynamic> map) {
    return TimetableEntry(
      id: map['id'] as String,
      schoolId: map['school_id'] as String,
      timetableId: map['timetable_id'] as String,
      dayOfWeek: map['day_of_week'] as int,
      periodId: map['period_id'] as int,
      subjectId: map['subject_id'] as int?,
      teacherId: map['teacher_id'] as String?,
      roomId: map['room_id'] as int?,
      notes: map['notes'] as String?,
      isSubstitute: (map['is_substitute'] as bool?) ?? false,
      substituteTeacherId: map['substitute_teacher_id'] as String?,
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
      'timetable_id': timetableId,
      'day_of_week': dayOfWeek,
      'period_id': periodId,
      'subject_id': subjectId,
      'teacher_id': teacherId,
      'room_id': roomId,
      'notes': notes,
      'is_substitute': isSubstitute,
      'substitute_teacher_id': substituteTeacherId,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  String get dayName {
    switch (dayOfWeek) {
      case 1:
        return 'Monday';
      case 2:
        return 'Tuesday';
      case 3:
        return 'Wednesday';
      case 4:
        return 'Thursday';
      case 5:
        return 'Friday';
      case 6:
        return 'Saturday';
      case 7:
        return 'Sunday';
      default:
        return 'Unknown';
    }
  }

  @override
  List<Object?> get props => [
    id,
    schoolId,
    timetableId,
    dayOfWeek,
    periodId,
    subjectId,
    teacherId,
    roomId,
    notes,
    isSubstitute,
    substituteTeacherId,
    createdAt,
    updatedAt,
  ];
}
