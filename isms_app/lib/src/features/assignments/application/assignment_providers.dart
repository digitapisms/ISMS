import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/error_handler.dart';
import '../../../core/errors/provider_helpers.dart';
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
  return safeProviderOperation<List<Assignment>>(
    ref: ref,
    operation: (schoolId) async {
      final repo = ref.read(assignmentRepositoryProvider);
      return await repo
          .fetchAssignments(schoolId: schoolId, isPublished: true)
          .timeout(const Duration(seconds: 10));
    },
    onError: () => <Assignment>[],
    context: 'AssignmentsProvider',
  );
});

final assignmentsByTeacherProvider =
    FutureProvider.family<List<Assignment>, String>((ref, teacherId) async {
      return safeProviderOperation<List<Assignment>>(
        ref: ref,
        operation: (schoolId) async {
          final repo = ref.read(assignmentRepositoryProvider);
          return await repo
              .fetchAssignments(schoolId: schoolId, teacherId: teacherId)
              .timeout(const Duration(seconds: 10));
        },
        onError: () => <Assignment>[],
        context: 'AssignmentsByTeacherProvider',
      );
    });

final assignmentsByClassProvider = FutureProvider.family<List<Assignment>, int>(
  (ref, classId) async {
    return safeProviderOperation<List<Assignment>>(
      ref: ref,
      operation: (schoolId) async {
        final repo = ref.read(assignmentRepositoryProvider);
        return await repo
            .fetchAssignments(schoolId: schoolId, classId: classId)
            .timeout(const Duration(seconds: 10));
      },
      onError: () => <Assignment>[],
      context: 'AssignmentsByClassProvider',
    );
  },
);

final assignmentProvider = FutureProvider.family<Assignment, String>((
  ref,
  assignmentId,
) async {
  final correlationId = ErrorHandler.generateCorrelationId();

  try {
    final assignments = await ref.read(assignmentsProvider.future);
    return assignments.firstWhere((a) => a.id == assignmentId);
  } catch (e) {
    final error = ErrorHandler.handleException(
      e,
      correlationId: correlationId,
      context: 'AssignmentProvider',
    );
    ErrorHandler.logError(error);
    rethrow;
  }
});

// ============================================================
// ASSIGNMENT SUBMISSIONS
// ============================================================

final submissionsByAssignmentProvider =
    FutureProvider.family<List<AssignmentSubmission>, String>((
      ref,
      assignmentId,
    ) async {
      return safeProviderOperation<List<AssignmentSubmission>>(
        ref: ref,
        operation: (schoolId) async {
          final repo = ref.read(assignmentRepositoryProvider);
          return await repo
              .fetchSubmissions(schoolId: schoolId, assignmentId: assignmentId)
              .timeout(const Duration(seconds: 10));
        },
        onError: () => <AssignmentSubmission>[],
        context: 'SubmissionsByAssignmentProvider',
      );
    });

final submissionsByStudentProvider =
    FutureProvider.family<List<AssignmentSubmission>, String>((
      ref,
      studentId,
    ) async {
      return safeProviderOperation<List<AssignmentSubmission>>(
        ref: ref,
        operation: (schoolId) async {
          final repo = ref.read(assignmentRepositoryProvider);
          return await repo
              .fetchSubmissions(schoolId: schoolId, studentId: studentId)
              .timeout(const Duration(seconds: 10));
        },
        onError: () => <AssignmentSubmission>[],
        context: 'SubmissionsByStudentProvider',
      );
    });

final submissionProvider = FutureProvider.family<AssignmentSubmission?, String>(
  (ref, submissionId) async {
    return safeProviderOperation<AssignmentSubmission?>(
      ref: ref,
      operation: (schoolId) async {
        final repo = ref.read(assignmentRepositoryProvider);
        final submissions = await repo
            .fetchSubmissions(schoolId: schoolId)
            .timeout(const Duration(seconds: 10));
        try {
          return submissions.firstWhere((s) => s.id == submissionId);
        } catch (e) {
          return null;
        }
      },
      onError: () => null,
      context: 'SubmissionProvider',
    );
  },
);

// ============================================================
// ASSIGNMENT GRADES
// ============================================================

final assignmentGradesProvider =
    FutureProvider.family<List<AssignmentGrade>, String>((
      ref,
      assignmentId,
    ) async {
      return safeProviderOperation<List<AssignmentGrade>>(
        ref: ref,
        operation: (schoolId) async {
          final repo = ref.read(assignmentRepositoryProvider);
          return await repo
              .fetchGrades(schoolId: schoolId, assignmentId: assignmentId)
              .timeout(const Duration(seconds: 10));
        },
        onError: () => <AssignmentGrade>[],
        context: 'AssignmentGradesProvider',
      );
    });

final studentAssignmentGradesProvider =
    FutureProvider.family<List<AssignmentGrade>, String>((
      ref,
      studentId,
    ) async {
      return safeProviderOperation<List<AssignmentGrade>>(
        ref: ref,
        operation: (schoolId) async {
          final repo = ref.read(assignmentRepositoryProvider);
          return await repo
              .fetchGrades(schoolId: schoolId, studentId: studentId)
              .timeout(const Duration(seconds: 10));
        },
        onError: () => <AssignmentGrade>[],
        context: 'StudentAssignmentGradesProvider',
      );
    });
