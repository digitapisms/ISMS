import 'package:equatable/equatable.dart';

class AttendanceStats extends Equatable {
  const AttendanceStats({
    required this.totalDays,
    required this.presentDays,
    required this.absentDays,
    required this.lateDays,
    required this.excusedDays,
    required this.halfDayDays,
    required this.attendancePercentage,
  });

  final int totalDays;
  final int presentDays;
  final int absentDays;
  final int lateDays;
  final int excusedDays;
  final int halfDayDays;
  final double attendancePercentage;

  int get attendedDays => presentDays + lateDays + halfDayDays;

  factory AttendanceStats.fromMap(Map<String, dynamic> map) {
    return AttendanceStats(
      totalDays: (map['total_days'] as num?)?.toInt() ?? 0,
      presentDays: (map['present_days'] as num?)?.toInt() ?? 0,
      absentDays: (map['absent_days'] as num?)?.toInt() ?? 0,
      lateDays: (map['late_days'] as num?)?.toInt() ?? 0,
      excusedDays: (map['excused_days'] as num?)?.toInt() ?? 0,
      halfDayDays: (map['half_day_days'] as num?)?.toInt() ?? 0,
      attendancePercentage:
          (map['attendance_percentage'] as num?)?.toDouble() ?? 0.0,
    );
  }

  @override
  List<Object?> get props => [
    totalDays,
    presentDays,
    absentDays,
    lateDays,
    excusedDays,
    halfDayDays,
    attendancePercentage,
  ];
}
