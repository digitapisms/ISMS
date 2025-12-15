import 'package:equatable/equatable.dart';

class SchoolReportOverview extends Equatable {
  const SchoolReportOverview({
    required this.totalStudents,
    required this.newStudents30d,
    required this.totalApplications,
    required this.pendingApplications,
    required this.underReviewApplications,
    required this.approvedApplications,
    required this.rejectedApplications,
    required this.staffCount,
    required this.teacherCount,
    required this.classCount,
    required this.sectionCount,
    required this.notifications30d,
    this.lastActivityAt,
  });

  final int totalStudents;
  final int newStudents30d;
  final int totalApplications;
  final int pendingApplications;
  final int underReviewApplications;
  final int approvedApplications;
  final int rejectedApplications;
  final int staffCount;
  final int teacherCount;
  final int classCount;
  final int sectionCount;
  final int notifications30d;
  final DateTime? lastActivityAt;

  factory SchoolReportOverview.empty() => const SchoolReportOverview(
    totalStudents: 0,
    newStudents30d: 0,
    totalApplications: 0,
    pendingApplications: 0,
    underReviewApplications: 0,
    approvedApplications: 0,
    rejectedApplications: 0,
    staffCount: 0,
    teacherCount: 0,
    classCount: 0,
    sectionCount: 0,
    notifications30d: 0,
  );

  factory SchoolReportOverview.fromMap(Map<String, dynamic> map) {
    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      if (value is DateTime) return value;
      if (value is String) return DateTime.tryParse(value);
      return null;
    }

    return SchoolReportOverview(
      totalStudents: _asInt(map['total_students']),
      newStudents30d: _asInt(map['new_students_30d']),
      totalApplications: _asInt(map['total_applications']),
      pendingApplications: _asInt(map['pending_applications']),
      underReviewApplications: _asInt(map['under_review_applications']),
      approvedApplications: _asInt(map['approved_applications']),
      rejectedApplications: _asInt(map['rejected_applications']),
      staffCount: _asInt(map['staff_count']),
      teacherCount: _asInt(map['teacher_count']),
      classCount: _asInt(map['class_count']),
      sectionCount: _asInt(map['section_count']),
      notifications30d: _asInt(map['notifications_30d']),
      lastActivityAt: parseDate(map['last_activity_at']),
    );
  }

  double get applicationConversionRate {
    if (totalApplications == 0) return 0;
    return (approvedApplications / totalApplications) * 100;
  }

  Map<String, int> get applicationStatusBreakdown => {
    'Pending': pendingApplications,
    'Under review': underReviewApplications,
    'Approved': approvedApplications,
    'Rejected': rejectedApplications,
  };

  @override
  List<Object?> get props => [
    totalStudents,
    newStudents30d,
    totalApplications,
    pendingApplications,
    underReviewApplications,
    approvedApplications,
    rejectedApplications,
    staffCount,
    teacherCount,
    classCount,
    sectionCount,
    notifications30d,
    lastActivityAt,
  ];

  static int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.round();
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}
