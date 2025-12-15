import 'package:flutter_riverpod/flutter_riverpod.dart';

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
  final school = ref.watch(currentSchoolProvider);
  if (school == null) return [];
  final repo = ref.read(timetableRepositoryProvider);
  return repo.fetchPeriods(schoolId: school.id, isActive: true);
});

// ============================================================
// ROOMS
// ============================================================

final roomsProvider = FutureProvider<List<Room>>((ref) async {
  final school = ref.watch(currentSchoolProvider);
  if (school == null) return [];
  final repo = ref.read(timetableRepositoryProvider);
  return repo.fetchRooms(schoolId: school.id, isActive: true);
});

// ============================================================
// TIMETABLES
// ============================================================

final timetablesProvider = FutureProvider<List<Timetable>>((ref) async {
  final school = ref.watch(currentSchoolProvider);
  if (school == null) return [];
  final repo = ref.read(timetableRepositoryProvider);
  return repo.fetchTimetables(schoolId: school.id);
});

final timetablesByClassProvider = FutureProvider.family<List<Timetable>, int>((
  ref,
  classId,
) async {
  final school = ref.watch(currentSchoolProvider);
  if (school == null) return [];
  final repo = ref.read(timetableRepositoryProvider);
  return repo.fetchTimetables(schoolId: school.id, classId: classId);
});

final timetableProvider = FutureProvider.family<Timetable, String>((
  ref,
  timetableId,
) async {
  final timetables = await ref.read(timetablesProvider.future);
  return timetables.firstWhere((t) => t.id == timetableId);
});

// ============================================================
// TIMETABLE ENTRIES
// ============================================================

final timetableEntriesProvider =
    FutureProvider.family<List<TimetableEntry>, String>((
      ref,
      timetableId,
    ) async {
      final school = ref.watch(currentSchoolProvider);
      if (school == null) return [];
      final repo = ref.read(timetableRepositoryProvider);
      return repo.fetchTimetableEntries(
        schoolId: school.id,
        timetableId: timetableId,
      );
    });

final teacherTimetableProvider =
    FutureProvider.family<List<TimetableEntry>, String>((ref, teacherId) async {
      final school = ref.watch(currentSchoolProvider);
      if (school == null) return [];
      final repo = ref.read(timetableRepositoryProvider);
      return repo.fetchTimetableEntries(
        schoolId: school.id,
        teacherId: teacherId,
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
      final school = ref.watch(currentSchoolProvider);
      if (school == null) return [];
      final repo = ref.read(timetableRepositoryProvider);
      return repo.fetchTeacherAssignments(
        schoolId: school.id,
        teacherId: teacherId,
      );
    });
