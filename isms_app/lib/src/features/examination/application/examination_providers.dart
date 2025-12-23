import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/error_handler.dart';
import '../../../core/errors/provider_helpers.dart';
import '../../school_registration/application/school_providers.dart';
import '../data/examination_repository.dart';
import '../domain/exam.dart';
import '../domain/exam_grade.dart';
import '../domain/exam_schedule.dart';
import '../domain/report_card.dart';
import '../domain/subject.dart';

final examinationRepositoryProvider = Provider<ExaminationRepository>((ref) {
  final repo = ExaminationRepository();
  final school = ref.watch(currentSchoolProvider);
  if (school != null) {
    repo.setSchoolId(school.id);
  }
  return repo;
});

// ============================================================
// SUBJECTS
// ============================================================

final subjectsProvider = FutureProvider<List<Subject>>((ref) async {
  return safeProviderOperation<List<Subject>>(
    ref: ref,
    operation: (schoolId) async {
      final repo = ref.read(examinationRepositoryProvider);
      return await repo
          .fetchSubjects(schoolId: schoolId, isActive: true)
          .timeout(const Duration(seconds: 10));
    },
    onError: () => <Subject>[],
    context: 'SubjectsProvider',
  );
});

// ============================================================
// EXAMS
// ============================================================

final examsProvider = FutureProvider<List<Exam>>((ref) async {
  return safeProviderOperation<List<Exam>>(
    ref: ref,
    operation: (schoolId) async {
      final repo = ref.read(examinationRepositoryProvider);
      return await repo
          .fetchExams(schoolId: schoolId)
          .timeout(const Duration(seconds: 10));
    },
    onError: () => <Exam>[],
    context: 'ExamsProvider',
  );
});

final examsByAcademicYearProvider = FutureProvider.family<List<Exam>, String>((
  ref,
  academicYear,
) async {
  return safeProviderOperation<List<Exam>>(
    ref: ref,
    operation: (schoolId) async {
      final repo = ref.read(examinationRepositoryProvider);
      return await repo
          .fetchExams(schoolId: schoolId, academicYear: academicYear)
          .timeout(const Duration(seconds: 10));
    },
    onError: () => <Exam>[],
    context: 'ExamsByAcademicYearProvider',
  );
});

final examProvider = FutureProvider.family<Exam, int>((ref, examId) async {
  final exams = await ref.read(examsProvider.future);
  return exams.firstWhere((exam) => exam.id == examId);
});

// ============================================================
// EXAM SCHEDULES
// ============================================================

final examSchedulesProvider = FutureProvider<List<ExamSchedule>>((ref) async {
  return safeProviderOperation<List<ExamSchedule>>(
    ref: ref,
    operation: (schoolId) async {
      final repo = ref.read(examinationRepositoryProvider);
      return await repo
          .fetchExamSchedules(schoolId: schoolId)
          .timeout(const Duration(seconds: 10));
    },
    onError: () => <ExamSchedule>[],
    context: 'ExamSchedulesProvider',
  );
});

final examSchedulesByExamProvider =
    FutureProvider.family<List<ExamSchedule>, int>((ref, examId) async {
      return safeProviderOperation<List<ExamSchedule>>(
        ref: ref,
        operation: (schoolId) async {
          final repo = ref.read(examinationRepositoryProvider);
          return await repo
              .fetchExamSchedules(schoolId: schoolId, examId: examId)
              .timeout(const Duration(seconds: 10));
        },
        onError: () => <ExamSchedule>[],
        context: 'ExamSchedulesByExamProvider',
      );
    });

// ============================================================
// EXAM GRADES
// ============================================================

final examGradesProvider = FutureProvider<List<ExamGrade>>((ref) async {
  return safeProviderOperation<List<ExamGrade>>(
    ref: ref,
    operation: (schoolId) async {
      final repo = ref.read(examinationRepositoryProvider);
      return await repo
          .fetchExamGrades(schoolId: schoolId)
          .timeout(const Duration(seconds: 10));
    },
    onError: () => <ExamGrade>[],
    context: 'ExamGradesProvider',
  );
});

final examGradesByExamProvider = FutureProvider.family<List<ExamGrade>, int>((
  ref,
  examId,
) async {
  return safeProviderOperation<List<ExamGrade>>(
    ref: ref,
    operation: (schoolId) async {
      final repo = ref.read(examinationRepositoryProvider);
      return await repo
          .fetchExamGrades(schoolId: schoolId, examId: examId)
          .timeout(const Duration(seconds: 10));
    },
    onError: () => <ExamGrade>[],
    context: 'ExamGradesByExamProvider',
  );
});

final examGradesByStudentProvider =
    FutureProvider.family<List<ExamGrade>, String>((ref, studentId) async {
      return safeProviderOperation<List<ExamGrade>>(
        ref: ref,
        operation: (schoolId) async {
          final repo = ref.read(examinationRepositoryProvider);
          return await repo
              .fetchExamGrades(schoolId: schoolId, studentId: studentId)
              .timeout(const Duration(seconds: 10));
        },
        onError: () => <ExamGrade>[],
        context: 'ExamGradesByStudentProvider',
      );
    });

// ============================================================
// REPORT CARDS
// ============================================================

final reportCardsProvider = FutureProvider<List<ReportCard>>((ref) async {
  return safeProviderOperation<List<ReportCard>>(
    ref: ref,
    operation: (schoolId) async {
      final repo = ref.read(examinationRepositoryProvider);
      return await repo
          .fetchReportCards(schoolId: schoolId)
          .timeout(const Duration(seconds: 10));
    },
    onError: () => <ReportCard>[],
    context: 'ReportCardsProvider',
  );
});

final reportCardsByStudentProvider =
    FutureProvider.family<List<ReportCard>, String>((ref, studentId) async {
      return safeProviderOperation<List<ReportCard>>(
        ref: ref,
        operation: (schoolId) async {
          final repo = ref.read(examinationRepositoryProvider);
          return await repo
              .fetchReportCards(schoolId: schoolId, studentId: studentId)
              .timeout(const Duration(seconds: 10));
        },
        onError: () => <ReportCard>[],
        context: 'ReportCardsByStudentProvider',
      );
    });

final reportCardProvider = FutureProvider.family<ReportCard, int>((
  ref,
  reportCardId,
) async {
  final correlationId = ErrorHandler.generateCorrelationId();

  try {
    final repo = ref.read(examinationRepositoryProvider);
    return await repo
        .getReportCard(reportCardId)
        .timeout(const Duration(seconds: 10));
  } catch (e) {
    final error = ErrorHandler.handleException(
      e,
      correlationId: correlationId,
      context: 'ReportCardProvider',
    );
    ErrorHandler.logError(error);
    rethrow;
  }
});
