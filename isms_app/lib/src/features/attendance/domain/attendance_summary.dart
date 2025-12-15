import 'package:equatable/equatable.dart';

class AttendanceSummary extends Equatable {
  const AttendanceSummary({
    required this.totalStudents,
    required this.presentCount,
    required this.absentCount,
    required this.lateCount,
    required this.excusedCount,
    required this.halfDayCount,
    required this.markedCount,
  });

  final int totalStudents;
  final int presentCount;
  final int absentCount;
  final int lateCount;
  final int excusedCount;
  final int halfDayCount;
  final int markedCount;

  int get unmarkedCount => totalStudents - markedCount;
  double get attendancePercentage {
    if (totalStudents == 0) return 0.0;
    final attended = presentCount + lateCount + halfDayCount;
    return (attended / totalStudents) * 100;
  }

  factory AttendanceSummary.fromMap(Map<String, dynamic> map) {
    return AttendanceSummary(
      totalStudents: (map['total_students'] as num?)?.toInt() ?? 0,
      presentCount: (map['present_count'] as num?)?.toInt() ?? 0,
      absentCount: (map['absent_count'] as num?)?.toInt() ?? 0,
      lateCount: (map['late_count'] as num?)?.toInt() ?? 0,
      excusedCount: (map['excused_count'] as num?)?.toInt() ?? 0,
      halfDayCount: (map['half_day_count'] as num?)?.toInt() ?? 0,
      markedCount: (map['marked_count'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  List<Object?> get props => [
    totalStudents,
    presentCount,
    absentCount,
    lateCount,
    excusedCount,
    halfDayCount,
    markedCount,
  ];
}
