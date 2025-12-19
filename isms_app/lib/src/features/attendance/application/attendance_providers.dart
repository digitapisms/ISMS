import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../school_registration/application/school_providers.dart';
import '../../student_management/domain/student.dart';
import '../data/attendance_repository.dart';
import '../domain/attendance_record.dart';
import '../domain/attendance_stats.dart';
import '../domain/attendance_summary.dart';

final attendanceRepositoryProvider = Provider<AttendanceRepository>((ref) {
  return AttendanceRepository();
});

/// Provider for fetching students for attendance marking
final studentsForAttendanceProvider =
    FutureProvider.family<List<Student>, AttendanceFilter>((ref, filter) async {
      try {
        final school = ref.watch(currentSchoolProvider);
        if (school == null) return const [];
        final repo = ref.read(attendanceRepositoryProvider);
        return await repo.fetchStudentsForAttendance(
          schoolId: school.id,
          classId: filter.classId,
          sectionId: filter.sectionId,
        );
      } catch (e) {
        debugPrint('Error fetching students for attendance: $e');
        return const [];
      }
    });

/// Provider for class attendance on a specific date
final classAttendanceProvider =
    FutureProvider.family<List<AttendanceRecord>, ClassAttendanceFilter>((
      ref,
      filter,
    ) async {
      try {
        final school = ref.watch(currentSchoolProvider);
        if (school == null) return const [];
        final repo = ref.read(attendanceRepositoryProvider);
        return await repo.fetchClassAttendance(
          schoolId: school.id,
          classId: filter.classId,
          sectionId: filter.sectionId,
          attendanceDate: filter.attendanceDate,
        );
      } catch (e) {
        debugPrint('Error fetching class attendance: $e');
        return const [];
      }
    });

/// Provider for student attendance history
final studentAttendanceProvider =
    FutureProvider.family<List<AttendanceRecord>, StudentAttendanceFilter>((
      ref,
      filter,
    ) async {
      final school = ref.watch(currentSchoolProvider);
      if (school == null) return const [];
      final repo = ref.read(attendanceRepositoryProvider);
      return repo.fetchStudentAttendance(
        schoolId: school.id,
        studentId: filter.studentId,
        startDate: filter.startDate,
        endDate: filter.endDate,
        limit: filter.limit,
      );
    });

/// Provider for student attendance statistics
final studentAttendanceStatsProvider =
    FutureProvider.family<AttendanceStats, StudentAttendanceStatsFilter>((
      ref,
      filter,
    ) async {
      final repo = ref.read(attendanceRepositoryProvider);
      return repo.getStudentAttendanceStats(
        studentId: filter.studentId,
        startDate: filter.startDate,
        endDate: filter.endDate,
      );
    });

/// Provider for class attendance summary
final classAttendanceSummaryProvider =
    FutureProvider.family<AttendanceSummary, ClassAttendanceSummaryFilter>((
      ref,
      filter,
    ) async {
      try {
        final school = ref.watch(currentSchoolProvider);
        if (school == null) {
          return const AttendanceSummary(
            totalStudents: 0,
            presentCount: 0,
            absentCount: 0,
            lateCount: 0,
            excusedCount: 0,
            halfDayCount: 0,
            markedCount: 0,
          );
        }
        final repo = ref.read(attendanceRepositoryProvider);
        return await repo.getClassAttendanceSummary(
          schoolId: school.id,
          classId: filter.classId,
          sectionId: filter.sectionId,
          attendanceDate: filter.attendanceDate,
        );
      } catch (e) {
        debugPrint('Error fetching attendance summary: $e');
        return const AttendanceSummary(
          totalStudents: 0,
          presentCount: 0,
          absentCount: 0,
          lateCount: 0,
          excusedCount: 0,
          halfDayCount: 0,
          markedCount: 0,
        );
      }
    });

// Filter classes
class AttendanceFilter {
  AttendanceFilter({required this.classId, this.sectionId});

  final int classId;
  final int? sectionId;
}

class ClassAttendanceFilter {
  ClassAttendanceFilter({
    required this.classId,
    this.sectionId,
    required this.attendanceDate,
  });

  final int classId;
  final int? sectionId;
  final DateTime attendanceDate;
}

class StudentAttendanceFilter {
  StudentAttendanceFilter({
    required this.studentId,
    this.startDate,
    this.endDate,
    this.limit,
  });

  final String studentId;
  final DateTime? startDate;
  final DateTime? endDate;
  final int? limit;
}

class StudentAttendanceStatsFilter {
  StudentAttendanceStatsFilter({
    required this.studentId,
    required this.startDate,
    required this.endDate,
  });

  final String studentId;
  final DateTime startDate;
  final DateTime endDate;
}

class ClassAttendanceSummaryFilter {
  ClassAttendanceSummaryFilter({
    required this.classId,
    this.sectionId,
    required this.attendanceDate,
  });

  final int classId;
  final int? sectionId;
  final DateTime attendanceDate;
}
