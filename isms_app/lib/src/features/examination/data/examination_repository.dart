import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/network/supabase_client.dart';
import '../domain/exam.dart';
import '../domain/exam_grade.dart';
import '../domain/exam_schedule.dart';
import '../domain/exam_type.dart';
import '../domain/report_card.dart';
import '../domain/subject.dart';

class ExaminationRepository {
  SupabaseClient get _client => SupabaseManager.client;
  String? _schoolId;

  void setSchoolId(String? schoolId) {
    _schoolId = schoolId;
  }

  String? get schoolId => _schoolId;

  // ============================================================
  // SUBJECTS
  // ============================================================

  Future<Subject> createSubject({
    required String schoolId,
    required String name,
    String? code,
    String? description,
    int? displayOrder,
  }) async {
    final response = await _client
        .from('subjects')
        .insert({
          'school_id': schoolId,
          'name': name,
          'code': code,
          'description': description,
          'display_order': displayOrder ?? 0,
        })
        .select()
        .single();

    return Subject.fromMap(response);
  }

  Future<List<Subject>> fetchSubjects({
    required String schoolId,
    bool? isActive,
  }) async {
    var query = _client.from('subjects').select().eq('school_id', schoolId);

    if (isActive != null) {
      query = query.eq('is_active', isActive);
    }

    final response = await query.order('display_order');
    return (response as List)
        .map((row) => Subject.fromMap(row as Map<String, dynamic>))
        .toList();
  }

  Future<Subject> updateSubject({
    required int id,
    String? name,
    String? code,
    String? description,
    bool? isActive,
    int? displayOrder,
  }) async {
    final updates = <String, dynamic>{};
    if (name != null) updates['name'] = name;
    if (code != null) updates['code'] = code;
    if (description != null) updates['description'] = description;
    if (isActive != null) updates['is_active'] = isActive;
    if (displayOrder != null) updates['display_order'] = displayOrder;

    final response = await _client
        .from('subjects')
        .update(updates)
        .eq('id', id)
        .select()
        .single();

    return Subject.fromMap(response);
  }

  // ============================================================
  // EXAMS
  // ============================================================

  Future<Exam> createExam({
    required String schoolId,
    required String name,
    required ExamType examType,
    String? academicYear,
    Term? term,
    DateTime? startDate,
    DateTime? endDate,
    double? totalMarks,
    double? passingMarks,
    String? description,
    String? createdBy,
  }) async {
    final response = await _client
        .from('exams')
        .insert({
          'school_id': schoolId,
          'name': name,
          'exam_type': examType.dbValue,
          'type': examType.dbValue, // For backward compatibility
          'academic_year': academicYear,
          'term': term?.dbValue,
          'start_date': startDate?.toIso8601String().split('T')[0],
          'end_date': endDate?.toIso8601String().split('T')[0],
          'total_marks': totalMarks ?? 100.0,
          'passing_marks': passingMarks,
          'description': description,
          'created_by': createdBy,
        })
        .select()
        .single();

    return Exam.fromMap(response);
  }

  Future<List<Exam>> fetchExams({
    required String schoolId,
    String? academicYear,
    Term? term,
    ExamType? examType,
    ExamStatus? status,
    bool? isActive,
  }) async {
    var query = _client.from('exams').select().eq('school_id', schoolId);

    if (academicYear != null) {
      query = query.eq('academic_year', academicYear);
    }
    if (term != null) {
      query = query.eq('term', term.dbValue);
    }
    if (examType != null) {
      query = query.eq('exam_type', examType.dbValue);
    }
    if (status != null) {
      query = query.eq('status', status.dbValue);
    }
    if (isActive != null) {
      query = query.eq('is_active', isActive);
    }

    final response = await query.order('start_date', ascending: false);
    return (response as List)
        .map((row) => Exam.fromMap(row as Map<String, dynamic>))
        .toList();
  }

  Future<Exam> updateExam({
    required int id,
    String? name,
    ExamType? examType,
    String? academicYear,
    Term? term,
    DateTime? startDate,
    DateTime? endDate,
    double? totalMarks,
    double? passingMarks,
    String? description,
    ExamStatus? status,
    bool? isActive,
  }) async {
    final updates = <String, dynamic>{};
    if (name != null) updates['name'] = name;
    if (examType != null) {
      updates['exam_type'] = examType.dbValue;
      updates['type'] = examType.dbValue;
    }
    if (academicYear != null) updates['academic_year'] = academicYear;
    if (term != null) updates['term'] = term.dbValue;
    if (startDate != null) {
      updates['start_date'] = startDate.toIso8601String().split('T')[0];
    }
    if (endDate != null) {
      updates['end_date'] = endDate.toIso8601String().split('T')[0];
    }
    if (totalMarks != null) updates['total_marks'] = totalMarks;
    if (passingMarks != null) updates['passing_marks'] = passingMarks;
    if (description != null) updates['description'] = description;
    if (status != null) updates['status'] = status.dbValue;
    if (isActive != null) updates['is_active'] = isActive;

    final response = await _client
        .from('exams')
        .update(updates)
        .eq('id', id)
        .select()
        .single();

    return Exam.fromMap(response);
  }

  // ============================================================
  // EXAM SCHEDULES
  // ============================================================

  Future<ExamSchedule> createExamSchedule({
    required String schoolId,
    required int examId,
    required DateTime examDate,
    int? subjectId,
    int? classId,
    int? sectionId,
    DateTime? startTime,
    DateTime? endTime,
    int? durationMinutes,
    String? venue,
    String? instructions,
  }) async {
    final response = await _client
        .from('exam_schedules')
        .insert({
          'school_id': schoolId,
          'exam_id': examId,
          'subject_id': subjectId,
          'class_id': classId,
          'section_id': sectionId,
          'exam_date': examDate.toIso8601String().split('T')[0],
          'start_time': startTime
              ?.toIso8601String()
              .split('T')[1]
              .substring(0, 8),
          'end_time': endTime?.toIso8601String().split('T')[1].substring(0, 8),
          'duration_minutes': durationMinutes,
          'venue': venue,
          'instructions': instructions,
        })
        .select()
        .single();

    return ExamSchedule.fromMap(response);
  }

  Future<List<ExamSchedule>> fetchExamSchedules({
    required String schoolId,
    int? examId,
    int? classId,
    int? sectionId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    var query = _client
        .from('exam_schedules')
        .select()
        .eq('school_id', schoolId);

    if (examId != null) {
      query = query.eq('exam_id', examId);
    }
    if (classId != null) {
      query = query.eq('class_id', classId);
    }
    if (sectionId != null) {
      query = query.eq('section_id', sectionId);
    }
    if (startDate != null) {
      query = query.gte('exam_date', startDate.toIso8601String().split('T')[0]);
    }
    if (endDate != null) {
      query = query.lte('exam_date', endDate.toIso8601String().split('T')[0]);
    }

    final response = await query.order('exam_date', ascending: true);
    return (response as List)
        .map((row) => ExamSchedule.fromMap(row as Map<String, dynamic>))
        .toList();
  }

  // ============================================================
  // EXAM GRADES
  // ============================================================

  Future<ExamGrade> createExamGrade({
    required String schoolId,
    required int examId,
    required String studentId,
    required double marksObtained,
    required double totalMarks,
    String? examScheduleId,
    int? subjectId,
    String? remarks,
    bool isAbsent = false,
    bool isExempted = false,
    String? enteredBy,
  }) async {
    final response = await _client
        .from('exam_grades')
        .insert({
          'school_id': schoolId,
          'exam_id': examId,
          'exam_schedule_id': examScheduleId,
          'student_id': studentId,
          'subject_id': subjectId,
          'marks_obtained': marksObtained,
          'total_marks': totalMarks,
          'remarks': remarks,
          'is_absent': isAbsent,
          'is_exempted': isExempted,
          'entered_by': enteredBy,
        })
        .select()
        .single();

    return ExamGrade.fromMap(response);
  }

  Future<List<ExamGrade>> fetchExamGrades({
    required String schoolId,
    int? examId,
    String? studentId,
    int? subjectId,
    int? classId,
  }) async {
    var query = _client.from('exam_grades').select().eq('school_id', schoolId);

    if (examId != null) {
      query = query.eq('exam_id', examId);
    }
    if (studentId != null) {
      query = query.eq('student_id', studentId);
    }
    if (subjectId != null) {
      query = query.eq('subject_id', subjectId);
    }

    final response = await query.order('created_at', ascending: false);
    return (response as List)
        .map((row) => ExamGrade.fromMap(row as Map<String, dynamic>))
        .toList();
  }

  Future<ExamGrade> updateExamGrade({
    required String id,
    double? marksObtained,
    double? totalMarks,
    String? remarks,
    bool? isAbsent,
    bool? isExempted,
    String? approvedBy,
  }) async {
    final updates = <String, dynamic>{};
    if (marksObtained != null) updates['marks_obtained'] = marksObtained;
    if (totalMarks != null) updates['total_marks'] = totalMarks;
    if (remarks != null) updates['remarks'] = remarks;
    if (isAbsent != null) updates['is_absent'] = isAbsent;
    if (isExempted != null) updates['is_exempted'] = isExempted;
    if (approvedBy != null) {
      updates['approved_by'] = approvedBy;
      updates['approved_at'] = DateTime.now().toIso8601String();
    }

    final response = await _client
        .from('exam_grades')
        .update(updates)
        .eq('id', id)
        .select()
        .single();

    return ExamGrade.fromMap(response);
  }

  Future<void> bulkCreateExamGrades({
    required String schoolId,
    required List<Map<String, dynamic>> grades,
  }) async {
    await _client
        .from('exam_grades')
        .insert(
          grades.map((grade) => {...grade, 'school_id': schoolId}).toList(),
        );
  }

  // ============================================================
  // REPORT CARDS
  // ============================================================

  Future<ReportCard> generateReportCard({
    required String schoolId,
    required String studentId,
    required int classId,
    required String academicYear,
    required String term,
    int? sectionId,
    double? attendancePercentage,
    String? teacherRemarks,
    String? principalRemarks,
    String? generatedBy,
  }) async {
    // Calculate overall grades from exam_grades
    final grades = await fetchExamGrades(
      schoolId: schoolId,
      studentId: studentId,
    );

    // Filter grades for the term
    final termGrades = grades.where((g) {
      // This would need exam lookup - simplified for now
      return true;
    }).toList();

    final totalMarks = termGrades.fold<double>(
      0,
      (sum, grade) => sum + grade.totalMarks,
    );
    final marksObtained = termGrades.fold<double>(
      0,
      (sum, grade) => sum + grade.marksObtained,
    );
    final overallPercentage = totalMarks > 0
        ? (marksObtained / totalMarks * 100)
        : 0.0;

    final response = await _client
        .from('report_cards')
        .insert({
          'school_id': schoolId,
          'student_id': studentId,
          'class_id': classId,
          'section_id': sectionId,
          'academic_year': academicYear,
          'term': term,
          'total_subjects': termGrades.length,
          'total_marks': totalMarks,
          'marks_obtained': marksObtained,
          'overall_percentage': overallPercentage,
          'attendance_percentage': attendancePercentage,
          'teacher_remarks': teacherRemarks,
          'principal_remarks': principalRemarks,
          'generated_by': generatedBy,
        })
        .select()
        .single();

    return ReportCard.fromMap(response);
  }

  Future<List<ReportCard>> fetchReportCards({
    required String schoolId,
    String? studentId,
    int? classId,
    String? academicYear,
    String? term,
  }) async {
    var query = _client.from('report_cards').select().eq('school_id', schoolId);

    if (studentId != null) {
      query = query.eq('student_id', studentId);
    }
    if (classId != null) {
      query = query.eq('class_id', classId);
    }
    if (academicYear != null) {
      query = query.eq('academic_year', academicYear);
    }
    if (term != null) {
      query = query.eq('term', term);
    }

    final response = await query.order('academic_year', ascending: false);
    return (response as List)
        .map((row) => ReportCard.fromMap(row as Map<String, dynamic>))
        .toList();
  }

  Future<ReportCard> getReportCard(int id) async {
    final response = await _client
        .from('report_cards')
        .select()
        .eq('id', id)
        .single();

    return ReportCard.fromMap(response);
  }
}
