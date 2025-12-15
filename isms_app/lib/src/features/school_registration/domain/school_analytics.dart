import 'package:equatable/equatable.dart';

class SchoolAnalytics extends Equatable {
  const SchoolAnalytics({
    required this.totalStudents,
    required this.pendingApplications,
    required this.staffCount,
    required this.teacherCount,
    this.lastApplicationAt,
    this.lastStudentCreatedAt,
  });

  final int totalStudents;
  final int pendingApplications;
  final int staffCount;
  final int teacherCount;
  final DateTime? lastApplicationAt;
  final DateTime? lastStudentCreatedAt;

  factory SchoolAnalytics.empty() => const SchoolAnalytics(
    totalStudents: 0,
    pendingApplications: 0,
    staffCount: 0,
    teacherCount: 0,
  );

  SchoolAnalytics copyWith({
    int? totalStudents,
    int? pendingApplications,
    int? staffCount,
    int? teacherCount,
    DateTime? lastApplicationAt,
    DateTime? lastStudentCreatedAt,
  }) {
    return SchoolAnalytics(
      totalStudents: totalStudents ?? this.totalStudents,
      pendingApplications: pendingApplications ?? this.pendingApplications,
      staffCount: staffCount ?? this.staffCount,
      teacherCount: teacherCount ?? this.teacherCount,
      lastApplicationAt: lastApplicationAt ?? this.lastApplicationAt,
      lastStudentCreatedAt: lastStudentCreatedAt ?? this.lastStudentCreatedAt,
    );
  }

  int get totalAdults => staffCount + teacherCount;

  @override
  List<Object?> get props => [
    totalStudents,
    pendingApplications,
    staffCount,
    teacherCount,
    lastApplicationAt,
    lastStudentCreatedAt,
  ];
}
