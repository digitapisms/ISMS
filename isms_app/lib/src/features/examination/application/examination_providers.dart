import 'package:flutter_riverpod/flutter_riverpod.dart';

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
  final school = ref.watch(currentSchoolProvider);
  if (school == null) return [];
  final repo = ref.read(examinationRepositoryProvider);
  return repo.fetchSubjects(schoolId: school.id, isActive: true);
});

// ============================================================
// EXAMS
// ============================================================

final examsProvider = FutureProvider<List<Exam>>((ref) async {
  final school = ref.watch(currentSchoolProvider);
  if (school == null) return [];
  final repo = ref.read(examinationRepositoryProvider);
  return repo.fetchExams(schoolId: school.id);
});

final examsByAcademicYearProvider = FutureProvider.family<List<Exam>, String>((
  ref,
  academicYear,
) async {
  final school = ref.watch(currentSchoolProvider);
  if (school == null) return [];
  final repo = ref.read(examinationRepositoryProvider);
  return repo.fetchExams(schoolId: school.id, academicYear: academicYear);
});

final examProvider = FutureProvider.family<Exam, int>((ref, examId) async {
  final exams = await ref.read(examsProvider.future);
  return exams.firstWhere((exam) => exam.id == examId);
});

// ============================================================
// EXAM SCHEDULES
// ============================================================

final examSchedulesProvider = FutureProvider<List<ExamSchedule>>((ref) async {
  final school = ref.watch(currentSchoolProvider);
  if (school == null) return [];
  final repo = ref.read(examinationRepositoryProvider);
  return repo.fetchExamSchedules(schoolId: school.id);
});

final examSchedulesByExamProvider =
    FutureProvider.family<List<ExamSchedule>, int>((ref, examId) async {
      final school = ref.watch(currentSchoolProvider);
      if (school == null) return [];
      final repo = ref.read(examinationRepositoryProvider);
      return repo.fetchExamSchedules(schoolId: school.id, examId: examId);
    });

// ============================================================
// EXAM GRADES
// ============================================================

final examGradesProvider = FutureProvider<List<ExamGrade>>((ref) async {
  final school = ref.watch(currentSchoolProvider);
  if (school == null) return [];
  final repo = ref.read(examinationRepositoryProvider);
  return repo.fetchExamGrades(schoolId: school.id);
});

final examGradesByExamProvider = FutureProvider.family<List<ExamGrade>, int>((
  ref,
  examId,
) async {
  final school = ref.watch(currentSchoolProvider);
  if (school == null) return [];
  final repo = ref.read(examinationRepositoryProvider);
  return repo.fetchExamGrades(schoolId: school.id, examId: examId);
});

final examGradesByStudentProvider =
    FutureProvider.family<List<ExamGrade>, String>((ref, studentId) async {
      final school = ref.watch(currentSchoolProvider);
      if (school == null) return [];
      final repo = ref.read(examinationRepositoryProvider);
      return repo.fetchExamGrades(schoolId: school.id, studentId: studentId);
    });

// ============================================================
// REPORT CARDS
// ============================================================

final reportCardsProvider = FutureProvider<List<ReportCard>>((ref) async {
  final school = ref.watch(currentSchoolProvider);
  if (school == null) return [];
  final repo = ref.read(examinationRepositoryProvider);
  return repo.fetchReportCards(schoolId: school.id);
});

final reportCardsByStudentProvider =
    FutureProvider.family<List<ReportCard>, String>((ref, studentId) async {
      final school = ref.watch(currentSchoolProvider);
      if (school == null) return [];
      final repo = ref.read(examinationRepositoryProvider);
      return repo.fetchReportCards(schoolId: school.id, studentId: studentId);
    });

final reportCardProvider = FutureProvider.family<ReportCard, int>((
  ref,
  reportCardId,
) async {
  final repo = ref.read(examinationRepositoryProvider);
  return repo.getReportCard(reportCardId);
});
