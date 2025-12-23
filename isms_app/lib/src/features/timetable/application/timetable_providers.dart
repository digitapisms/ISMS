import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/error_handler.dart';
import '../../../core/errors/provider_helpers.dart';
import '../../school_registration/application/school_providers.dart';
import '../data/timetable_repository.dart';
import '../domain/period.dart';
import '../domain/room.dart';
import '../domain/teacher_assignment.dart';
import '../domain/timetable.dart';
import '../domain/timetable_entry.dart';

final timetableRepositoryProvider = Provider<TimetableRepository>((ref) {
  final repo = TimetableRepository();
  final school = ref.watch(currentSchoolProvider);
  if (school != null) {
    repo.setSchoolId(school.id);
  }
  return repo;
});

// ============================================================
// PERIODS
// ============================================================

final periodsProvider = FutureProvider<List<Period>>((ref) async {
  return safeProviderOperation<List<Period>>(
    ref: ref,
    operation: (schoolId) async {
      final repo = ref.read(timetableRepositoryProvider);
      return await repo
          .fetchPeriods(schoolId: schoolId, isActive: true)
          .timeout(const Duration(seconds: 10));
    },
    onError: () => <Period>[],
    context: 'PeriodsProvider',
  );
});

// ============================================================
// ROOMS
// ============================================================

final roomsProvider = FutureProvider<List<Room>>((ref) async {
  return safeProviderOperation<List<Room>>(
    ref: ref,
    operation: (schoolId) async {
      final repo = ref.read(timetableRepositoryProvider);
      return await repo
          .fetchRooms(schoolId: schoolId, isActive: true)
          .timeout(const Duration(seconds: 10));
    },
    onError: () => <Room>[],
    context: 'RoomsProvider',
  );
});

// ============================================================
// TIMETABLES
// ============================================================

final timetablesProvider = FutureProvider<List<Timetable>>((ref) async {
  return safeProviderOperation<List<Timetable>>(
    ref: ref,
    operation: (schoolId) async {
      final repo = ref.read(timetableRepositoryProvider);
      return await repo
          .fetchTimetables(schoolId: schoolId)
          .timeout(const Duration(seconds: 10));
    },
    onError: () => <Timetable>[],
    context: 'TimetablesProvider',
  );
});

final timetablesByClassProvider = FutureProvider.family<List<Timetable>, int>((
  ref,
  classId,
) async {
  return safeProviderOperation<List<Timetable>>(
    ref: ref,
    operation: (schoolId) async {
      final repo = ref.read(timetableRepositoryProvider);
      return await repo
          .fetchTimetables(schoolId: schoolId, classId: classId)
          .timeout(const Duration(seconds: 10));
    },
    onError: () => <Timetable>[],
    context: 'TimetablesByClassProvider',
  );
});

final timetableProvider = FutureProvider.family<Timetable, String>((
  ref,
  timetableId,
) async {
  final correlationId = ErrorHandler.generateCorrelationId();

  try {
    final timetables = await ref.read(timetablesProvider.future);
    return timetables.firstWhere((t) => t.id == timetableId);
  } catch (e) {
    final error = ErrorHandler.handleException(
      e,
      correlationId: correlationId,
      context: 'TimetableProvider',
    );
    ErrorHandler.logError(error);
    rethrow;
  }
});

// ============================================================
// TIMETABLE ENTRIES
// ============================================================

final timetableEntriesProvider =
    FutureProvider.family<List<TimetableEntry>, String>((
      ref,
      timetableId,
    ) async {
      return safeProviderOperation<List<TimetableEntry>>(
        ref: ref,
        operation: (schoolId) async {
          final repo = ref.read(timetableRepositoryProvider);
          return await repo
              .fetchTimetableEntries(
                schoolId: schoolId,
                timetableId: timetableId,
              )
              .timeout(const Duration(seconds: 10));
        },
        onError: () => <TimetableEntry>[],
        context: 'TimetableEntriesProvider',
      );
    });

final teacherTimetableProvider =
    FutureProvider.family<List<TimetableEntry>, String>((ref, teacherId) async {
      return safeProviderOperation<List<TimetableEntry>>(
        ref: ref,
        operation: (schoolId) async {
          final repo = ref.read(timetableRepositoryProvider);
          return await repo
              .fetchTimetableEntries(schoolId: schoolId, teacherId: teacherId)
              .timeout(const Duration(seconds: 10));
        },
        onError: () => <TimetableEntry>[],
        context: 'TeacherTimetableProvider',
      );
    });

// ============================================================
// TEACHER ASSIGNMENTS
// ============================================================

final teacherAssignmentsProvider =
    FutureProvider.family<List<TeacherAssignment>, String>((
      ref,
      teacherId,
    ) async {
      return safeProviderOperation<List<TeacherAssignment>>(
        ref: ref,
        operation: (schoolId) async {
          final repo = ref.read(timetableRepositoryProvider);
          return await repo
              .fetchTeacherAssignments(schoolId: schoolId, teacherId: teacherId)
              .timeout(const Duration(seconds: 10));
        },
        onError: () => <TeacherAssignment>[],
        context: 'TeacherAssignmentsProvider',
      );
    });
