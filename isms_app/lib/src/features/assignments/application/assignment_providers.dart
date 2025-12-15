import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../school_registration/application/school_providers.dart';
import '../data/assignment_repository.dart';
import '../domain/assignment.dart';
import '../domain/assignment_grade.dart';
import '../domain/assignment_submission.dart';

final assignmentRepositoryProvider = Provider<AssignmentRepository>((ref) {
  final repo = AssignmentRepository();
  final school = ref.watch(currentSchoolProvider);
  if (school != null) {
    repo.setSchoolId(school.id);
  }
  return repo;
});

// ============================================================
// ASSIGNMENTS
// ============================================================

final assignmentsProvider = FutureProvider<List<Assignment>>((ref) async {
  final school = ref.watch(currentSchoolProvider);
  if (school == null) return [];
  final repo = ref.read(assignmentRepositoryProvider);
  return repo.fetchAssignments(schoolId: school.id, isPublished: true);
});

final assignmentsByTeacherProvider =
    FutureProvider.family<List<Assignment>, String>((ref, teacherId) async {
      final school = ref.watch(currentSchoolProvider);
      if (school == null) return [];
      final repo = ref.read(assignmentRepositoryProvider);
      return repo.fetchAssignments(schoolId: school.id, teacherId: teacherId);
    });

final assignmentsByClassProvider = FutureProvider.family<List<Assignment>, int>(
  (ref, classId) async {
    final school = ref.watch(currentSchoolProvider);
    if (school == null) return [];
    final repo = ref.read(assignmentRepositoryProvider);
    return repo.fetchAssignments(schoolId: school.id, classId: classId);
  },
);

final assignmentProvider = FutureProvider.family<Assignment, String>((
  ref,
  assignmentId,
) async {
  final assignments = await ref.read(assignmentsProvider.future);
  return assignments.firstWhere((a) => a.id == assignmentId);
});

// ============================================================
// ASSIGNMENT SUBMISSIONS
// ============================================================

final submissionsByAssignmentProvider =
    FutureProvider.family<List<AssignmentSubmission>, String>((
      ref,
      assignmentId,
    ) async {
      final school = ref.watch(currentSchoolProvider);
      if (school == null) return [];
      final repo = ref.read(assignmentRepositoryProvider);
      return repo.fetchSubmissions(
        schoolId: school.id,
        assignmentId: assignmentId,
      );
    });

final submissionsByStudentProvider =
    FutureProvider.family<List<AssignmentSubmission>, String>((
      ref,
      studentId,
    ) async {
      final school = ref.watch(currentSchoolProvider);
      if (school == null) return [];
      final repo = ref.read(assignmentRepositoryProvider);
      return repo.fetchSubmissions(schoolId: school.id, studentId: studentId);
    });

final submissionProvider = FutureProvider.family<AssignmentSubmission?, String>(
  (ref, submissionId) async {
    final school = ref.watch(currentSchoolProvider);
    if (school == null) return null;
    final repo = ref.read(assignmentRepositoryProvider);
    final submissions = await repo.fetchSubmissions(schoolId: school.id);
    try {
      return submissions.firstWhere((s) => s.id == submissionId);
    } catch (e) {
      return null;
    }
  },
);

// ============================================================
// ASSIGNMENT GRADES
// ============================================================

final gradesByAssignmentProvider =
    FutureProvider.family<List<AssignmentGrade>, String>((
      ref,
      assignmentId,
    ) async {
      final school = ref.watch(currentSchoolProvider);
      if (school == null) return [];
      final repo = ref.read(assignmentRepositoryProvider);
      return repo.fetchGrades(schoolId: school.id, assignmentId: assignmentId);
    });

final gradesByStudentProvider =
    FutureProvider.family<List<AssignmentGrade>, String>((
      ref,
      studentId,
    ) async {
      final school = ref.watch(currentSchoolProvider);
      if (school == null) return [];
      final repo = ref.read(assignmentRepositoryProvider);
      return repo.fetchGrades(schoolId: school.id, studentId: studentId);
    });

final gradeForSubmissionProvider =
    FutureProvider.family<AssignmentGrade?, String>((ref, submissionId) async {
      final repo = ref.read(assignmentRepositoryProvider);
      return repo.getGradeForSubmission(submissionId);
    });
