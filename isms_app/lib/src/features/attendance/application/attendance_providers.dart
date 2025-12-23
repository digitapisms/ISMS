import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/provider_helpers.dart';
import '../../../core/tenant/tenant_context.dart';
import '../../authentication/application/auth_providers.dart';
import '../../student_management/domain/student.dart';
import '../data/attendance_repository.dart';
import '../domain/attendance_record.dart';
import '../domain/attendance_stats.dart';
import '../domain/attendance_summary.dart';

final attendanceRepositoryProvider = Provider<AttendanceRepository>((ref) {
  return AttendanceRepository();
});

/// Provider for fetching students for attendance marking
final studentsForAttendanceProvider = FutureProvider.family<List<Student>, AttendanceFilter>((
  ref,
  filter,
) async {
  debugPrint(
    'StudentsForAttendanceProvider: Fetching students for class ${filter.classId}, section ${filter.sectionId}',
  );

  // Get school ID immediately - no waiting
  final tenantSchool = ref.read(tenantContextProvider);
  final authUser = ref.read(authStateProvider);
  final schoolId = tenantSchool?.id ?? authUser?.schoolId;

  if (schoolId == null) {
    debugPrint('StudentsForAttendanceProvider: No school ID available');
    throw Exception(
      'School context is required. Please ensure you are signed in.',
    );
  }

  debugPrint('StudentsForAttendanceProvider: School ID: $schoolId');

  final repo = ref.read(attendanceRepositoryProvider);

  try {
    debugPrint('StudentsForAttendanceProvider: Starting fetch...');
    final result = await repo
        .fetchStudentsForAttendance(
          schoolId: schoolId,
          classId: filter.classId,
          sectionId: filter.sectionId,
        )
        .timeout(
          const Duration(seconds: 15),
          onTimeout: () {
            debugPrint('StudentsForAttendanceProvider: Timeout occurred');
            throw Exception(
              'Request timed out. Please check your internet connection and try again.',
            );
          },
        );

    debugPrint(
      'StudentsForAttendanceProvider: Successfully fetched ${result.length} students',
    );
    return result;
  } catch (e, stackTrace) {
    debugPrint('StudentsForAttendanceProvider: Error caught - $e');
    debugPrint('StudentsForAttendanceProvider: Stack - $stackTrace');

    // Always throw an Exception so UI can handle it
    final errorString = e.toString().toLowerCase();
    if (errorString.contains('networkerror') ||
        errorString.contains('clientexception') ||
        errorString.contains('network error')) {
      throw Exception(
        'Network error: Unable to connect to the server. Please check your internet connection and try again.',
      );
    }

    // Re-throw as Exception if not already
    if (e is Exception) {
      rethrow;
    }
    throw Exception('Failed to load students: ${e.toString()}');
  }
});

/// Provider for class attendance on a specific date
final classAttendanceProvider =
    FutureProvider.family<List<AttendanceRecord>, ClassAttendanceFilter>((
      ref,
      filter,
    ) async {
      // Get school ID immediately - no waiting
      final tenantSchool = ref.read(tenantContextProvider);
      final authUser = ref.read(authStateProvider);
      final schoolId = tenantSchool?.id ?? authUser?.schoolId;

      if (schoolId == null) {
        // Return empty list silently for attendance records (not critical)
        return const <AttendanceRecord>[];
      }

      final repo = ref.read(attendanceRepositoryProvider);
      try {
        return await repo
            .fetchClassAttendance(
              schoolId: schoolId,
              classId: filter.classId,
              sectionId: filter.sectionId,
              attendanceDate: filter.attendanceDate,
            )
            .timeout(const Duration(seconds: 15));
      } on TimeoutException {
        debugPrint('ClassAttendanceProvider timeout');
        // Return empty list on timeout for attendance records (non-critical)
        return const <AttendanceRecord>[];
      } catch (e) {
        debugPrint('ClassAttendanceProvider error: $e');
        // Return empty list for attendance records (non-critical, UI handles gracefully)
        return const <AttendanceRecord>[];
      }
    });

/// Provider for student attendance history
final studentAttendanceProvider =
    FutureProvider.family<List<AttendanceRecord>, StudentAttendanceFilter>((
      ref,
      filter,
    ) async {
      return safeProviderOperation<List<AttendanceRecord>>(
        ref: ref,
        operation: (schoolId) async {
          final repo = ref.read(attendanceRepositoryProvider);
          return await repo
              .fetchStudentAttendance(
                schoolId: schoolId,
                studentId: filter.studentId,
                startDate: filter.startDate,
                endDate: filter.endDate,
                limit: filter.limit,
              )
              .timeout(const Duration(seconds: 10));
        },
        onError: () => const <AttendanceRecord>[],
        context: 'StudentAttendanceProvider',
      );
    });

/// Provider for student attendance statistics
final studentAttendanceStatsProvider =
    FutureProvider.family<AttendanceStats, StudentAttendanceStatsFilter>((
      ref,
      filter,
    ) async {
      final repo = ref.read(attendanceRepositoryProvider);
      try {
        return await repo
            .getStudentAttendanceStats(
              studentId: filter.studentId,
              startDate: filter.startDate,
              endDate: filter.endDate,
            )
            .timeout(
              const Duration(seconds: 15),
              onTimeout: () {
                throw TimeoutException(
                  'Request timed out. Please check your internet connection and try again.',
                  const Duration(seconds: 15),
                );
              },
            );
      } on TimeoutException {
        rethrow;
      } catch (e, stackTrace) {
        debugPrint('StudentAttendanceStatsProvider error: $e');
        debugPrint('Stack: $stackTrace');

        // Convert network errors to user-friendly messages
        final errorString = e.toString().toLowerCase();
        if (errorString.contains('networkerror') ||
            errorString.contains('clientexception') ||
            errorString.contains('network error')) {
          throw Exception(
            'Network error: Unable to connect to the server. Please check your internet connection and try again.',
          );
        }

        // Re-throw as Exception if not already
        if (e is Exception) {
          rethrow;
        }
        throw Exception(
          'Failed to load attendance statistics: ${e.toString()}',
        );
      }
    });

/// Provider for class attendance summary
final classAttendanceSummaryProvider =
    FutureProvider.family<AttendanceSummary, ClassAttendanceSummaryFilter>((
      ref,
      filter,
    ) async {
      // Get school ID immediately - no waiting
      final tenantSchool = ref.read(tenantContextProvider);
      final authUser = ref.read(authStateProvider);
      final schoolId = tenantSchool?.id ?? authUser?.schoolId;

      if (schoolId == null) {
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
      try {
        return await repo
            .getClassAttendanceSummary(
              schoolId: schoolId,
              classId: filter.classId,
              sectionId: filter.sectionId,
              attendanceDate: filter.attendanceDate,
            )
            .timeout(
              const Duration(seconds: 10),
              onTimeout: () {
                // Return empty summary on timeout (non-critical)
                return const AttendanceSummary(
                  totalStudents: 0,
                  presentCount: 0,
                  absentCount: 0,
                  lateCount: 0,
                  excusedCount: 0,
                  halfDayCount: 0,
                  markedCount: 0,
                );
              },
            );
      } catch (e) {
        debugPrint('ClassAttendanceSummaryProvider error: $e');
        // Return empty summary on error (non-critical, UI will show warning)
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

/// Composite provider for the Mark Attendance screen.
///
/// Why this exists:
/// - The marking UI previously depended on multiple providers + a listener inside `build()`.
/// - Any retry/rebuild/race could leave the UI seemingly "stuck loading".
/// - This provider guarantees a single source of truth: **loading / data / error**.
final attendanceMarkingDataProvider =
    FutureProvider.family<AttendanceMarkingData, AttendanceMarkingDataFilter>((
      ref,
      filter,
    ) async {
      // Resolve school id from tenant/auth immediately.
      final tenantSchool = ref.read(tenantContextProvider);
      final authUser = ref.read(authStateProvider);
      final schoolId = tenantSchool?.id ?? authUser?.schoolId;

      if (schoolId == null) {
        throw Exception('School context is required. Please sign in again.');
      }

      final repo = ref.read(attendanceRepositoryProvider);

      // 1) Students are required to render the screen.
      final students = await repo.fetchStudentsForAttendance(
        schoolId: schoolId,
        classId: filter.classId,
        sectionId: filter.sectionId,
      );

      // 2) Existing attendance + summary are best-effort (do not block marking UI).
      List<AttendanceRecord> records = const <AttendanceRecord>[];
      AttendanceSummary? summary;
      String? warning;

      try {
        records = await repo.fetchClassAttendance(
          schoolId: schoolId,
          classId: filter.classId,
          sectionId: filter.sectionId,
          attendanceDate: filter.attendanceDate,
        );
      } catch (e) {
        debugPrint('attendanceMarkingDataProvider: records fetch failed: $e');
        warning = 'Unable to load existing attendance';
      }

      try {
        summary = await repo.getClassAttendanceSummary(
          schoolId: schoolId,
          classId: filter.classId,
          sectionId: filter.sectionId,
          attendanceDate: filter.attendanceDate,
        );
      } catch (e) {
        debugPrint('attendanceMarkingDataProvider: summary fetch failed: $e');
        warning = warning == null
            ? 'Unable to load attendance summary'
            : '$warning • summary unavailable';
      }

      final existingByStudentId = <String, AttendanceRecord>{};
      for (final r in records) {
        existingByStudentId[r.studentId] = r;
      }

      return AttendanceMarkingData(
        students: students,
        existingByStudentId: existingByStudentId,
        summary: summary,
        warning: warning,
      );
    });

// Filter classes - Must implement Equatable for Riverpod to properly cache providers
class AttendanceFilter extends Equatable {
  const AttendanceFilter({required this.classId, this.sectionId});

  final int classId;
  final int? sectionId;

  @override
  List<Object?> get props => [classId, sectionId];
}

class ClassAttendanceFilter extends Equatable {
  const ClassAttendanceFilter({
    required this.classId,
    this.sectionId,
    required this.attendanceDate,
  });

  final int classId;
  final int? sectionId;
  final DateTime attendanceDate;

  @override
  List<Object?> get props => [classId, sectionId, attendanceDate];
}

class StudentAttendanceFilter extends Equatable {
  const StudentAttendanceFilter({
    required this.studentId,
    this.startDate,
    this.endDate,
    this.limit,
  });

  final String studentId;
  final DateTime? startDate;
  final DateTime? endDate;
  final int? limit;

  @override
  List<Object?> get props => [studentId, startDate, endDate, limit];
}

class StudentAttendanceStatsFilter extends Equatable {
  const StudentAttendanceStatsFilter({
    required this.studentId,
    required this.startDate,
    required this.endDate,
  });

  final String studentId;
  final DateTime startDate;
  final DateTime endDate;

  @override
  List<Object?> get props => [studentId, startDate, endDate];
}

class ClassAttendanceSummaryFilter extends Equatable {
  const ClassAttendanceSummaryFilter({
    required this.classId,
    this.sectionId,
    required this.attendanceDate,
  });

  final int classId;
  final int? sectionId;
  final DateTime attendanceDate;

  @override
  List<Object?> get props => [classId, sectionId, attendanceDate];
}

class AttendanceMarkingDataFilter extends Equatable {
  const AttendanceMarkingDataFilter({
    required this.classId,
    this.sectionId,
    required this.attendanceDate,
  });

  final int classId;
  final int? sectionId;
  final DateTime attendanceDate;

  @override
  List<Object?> get props => [classId, sectionId, attendanceDate];
}

class AttendanceMarkingData extends Equatable {
  const AttendanceMarkingData({
    required this.students,
    required this.existingByStudentId,
    required this.summary,
    required this.warning,
  });

  final List<Student> students;
  final Map<String, AttendanceRecord> existingByStudentId;
  final AttendanceSummary? summary;
  final String? warning;

  @override
  List<Object?> get props => [students, existingByStudentId, summary, warning];
}
