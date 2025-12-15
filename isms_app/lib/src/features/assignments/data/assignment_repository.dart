import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/network/supabase_client.dart';
import '../domain/assignment.dart';
import '../domain/assignment_attachment.dart';
import '../domain/assignment_grade.dart';
import '../domain/assignment_submission.dart';
import '../domain/assignment_type.dart';

class AssignmentRepository {
  SupabaseClient get _client => SupabaseManager.client;
  String? _schoolId;

  void setSchoolId(String? schoolId) {
    _schoolId = schoolId;
  }

  String? get schoolId => _schoolId;

  // ============================================================
  // ASSIGNMENTS
  // ============================================================

  Future<Assignment> createAssignment({
    required String schoolId,
    required String title,
    required int classId,
    required String teacherId,
    required String academicYear,
    required DateTime dueDate,
    String? description,
    AssignmentType? assignmentType,
    int? subjectId,
    int? sectionId,
    String? term,
    double? maxPoints,
    double? weightage,
    String? instructions,
    Map<String, dynamic>? rubric,
    bool? allowLateSubmission,
    double? latePenaltyPerDay,
    bool? allowResubmission,
    String? createdBy,
  }) async {
    final response = await _client
        .from('assignments')
        .insert({
          'school_id': schoolId,
          'title': title,
          'description': description,
          'assignment_type': assignmentType?.dbValue ?? 'homework',
          'subject_id': subjectId,
          'class_id': classId,
          'section_id': sectionId,
          'teacher_id': teacherId,
          'academic_year': academicYear,
          'term': term,
          'due_date': dueDate.toIso8601String(),
          'max_points': maxPoints ?? 100.0,
          'weightage': weightage,
          'instructions': instructions,
          'rubric': rubric,
          'allow_late_submission': allowLateSubmission ?? true,
          'late_penalty_per_day': latePenaltyPerDay ?? 0.0,
          'allow_resubmission': allowResubmission ?? false,
          'created_by': createdBy,
        })
        .select()
        .single();

    return Assignment.fromMap(response);
  }

  Future<List<Assignment>> fetchAssignments({
    required String schoolId,
    int? classId,
    int? sectionId,
    String? teacherId,
    String? studentId,
    String? academicYear,
    String? term,
    bool? isPublished,
  }) async {
    var query = _client.from('assignments').select().eq('school_id', schoolId);

    if (classId != null) {
      query = query.eq('class_id', classId);
    }
    if (sectionId != null) {
      query = query.eq('section_id', sectionId);
    }
    if (teacherId != null) {
      query = query.eq('teacher_id', teacherId);
    }
    if (academicYear != null) {
      query = query.eq('academic_year', academicYear);
    }
    if (term != null) {
      query = query.eq('term', term);
    }
    if (isPublished != null) {
      query = query.eq('is_published', isPublished);
    }

    // If studentId is provided, filter assignments for that student's class
    if (studentId != null) {
      // This would require a join with students table - simplified for now
      // In production, you'd join with students to get their class_id
    }

    final response = await query.order('due_date', ascending: false);
    return (response as List)
        .map((row) => Assignment.fromMap(row as Map<String, dynamic>))
        .toList();
  }

  Future<Assignment> updateAssignment({
    required String id,
    String? title,
    String? description,
    DateTime? dueDate,
    double? maxPoints,
    double? weightage,
    String? instructions,
    Map<String, dynamic>? rubric,
    bool? allowLateSubmission,
    double? latePenaltyPerDay,
    bool? allowResubmission,
    bool? isPublished,
  }) async {
    final updates = <String, dynamic>{};
    if (title != null) updates['title'] = title;
    if (description != null) updates['description'] = description;
    if (dueDate != null) updates['due_date'] = dueDate.toIso8601String();
    if (maxPoints != null) updates['max_points'] = maxPoints;
    if (weightage != null) updates['weightage'] = weightage;
    if (instructions != null) updates['instructions'] = instructions;
    if (rubric != null) updates['rubric'] = rubric;
    if (allowLateSubmission != null) {
      updates['allow_late_submission'] = allowLateSubmission;
    }
    if (latePenaltyPerDay != null) {
      updates['late_penalty_per_day'] = latePenaltyPerDay;
    }
    if (allowResubmission != null) {
      updates['allow_resubmission'] = allowResubmission;
    }
    if (isPublished != null) {
      updates['is_published'] = isPublished;
      if (isPublished) {
        updates['published_at'] = DateTime.now().toIso8601String();
      }
    }

    final response = await _client
        .from('assignments')
        .update(updates)
        .eq('id', id)
        .select()
        .single();

    return Assignment.fromMap(response);
  }

  // ============================================================
  // ASSIGNMENT SUBMISSIONS
  // ============================================================

  Future<AssignmentSubmission> createSubmission({
    required String schoolId,
    required String assignmentId,
    required String studentId,
    String? submissionText,
    SubmissionStatus? submissionStatus,
  }) async {
    final response = await _client
        .from('assignment_submissions')
        .insert({
          'school_id': schoolId,
          'assignment_id': assignmentId,
          'student_id': studentId,
          'submission_text': submissionText,
          'submission_status':
              submissionStatus?.dbValue ?? SubmissionStatus.inProgress.dbValue,
        })
        .select()
        .single();

    return AssignmentSubmission.fromMap(response);
  }

  Future<AssignmentSubmission> submitAssignment({
    required String submissionId,
    required String submissionText,
  }) async {
    // Get assignment to check due date
    final submission = await _client
        .from('assignment_submissions')
        .select(
          'assignment_id, assignments!inner(due_date, allow_late_submission)',
        )
        .eq('id', submissionId)
        .single();

    final assignment = submission['assignments'] as Map<String, dynamic>;
    final dueDate = DateTime.parse(assignment['due_date'] as String);
    final now = DateTime.now();
    final isLate = now.isAfter(dueDate);
    final daysLate = isLate ? now.difference(dueDate).inDays : 0;

    final updates = <String, dynamic>{
      'submission_text': submissionText,
      'submission_status': isLate
          ? SubmissionStatus.late.dbValue
          : SubmissionStatus.submitted.dbValue,
      'submitted_at': now.toIso8601String(),
      'is_late': isLate,
      'days_late': daysLate,
    };

    final response = await _client
        .from('assignment_submissions')
        .update(updates)
        .eq('id', submissionId)
        .select()
        .single();

    return AssignmentSubmission.fromMap(response);
  }

  Future<List<AssignmentSubmission>> fetchSubmissions({
    required String schoolId,
    String? assignmentId,
    String? studentId,
    SubmissionStatus? status,
  }) async {
    var query = _client
        .from('assignment_submissions')
        .select()
        .eq('school_id', schoolId);

    if (assignmentId != null) {
      query = query.eq('assignment_id', assignmentId);
    }
    if (studentId != null) {
      query = query.eq('student_id', studentId);
    }
    if (status != null) {
      query = query.eq('submission_status', status.dbValue);
    }

    final response = await query.order('submitted_at', ascending: false);
    return (response as List)
        .map((row) => AssignmentSubmission.fromMap(row as Map<String, dynamic>))
        .toList();
  }

  Future<AssignmentSubmission> updateSubmission({
    required String id,
    String? submissionText,
    SubmissionStatus? submissionStatus,
  }) async {
    final updates = <String, dynamic>{};
    if (submissionText != null) updates['submission_text'] = submissionText;
    if (submissionStatus != null) {
      updates['submission_status'] = submissionStatus.dbValue;
    }

    final response = await _client
        .from('assignment_submissions')
        .update(updates)
        .eq('id', id)
        .select()
        .single();

    return AssignmentSubmission.fromMap(response);
  }

  // ============================================================
  // ASSIGNMENT GRADES
  // ============================================================

  Future<AssignmentGrade> createGrade({
    required String schoolId,
    required String submissionId,
    required String assignmentId,
    required String studentId,
    double? pointsObtained,
    double? maxPoints,
    String? grade,
    double? gradePoint,
    String? teacherFeedback,
    Map<String, dynamic>? rubricScores,
    String? gradedBy,
    bool? isPublished,
  }) async {
    double? percentage;
    if (pointsObtained != null && maxPoints != null && maxPoints > 0) {
      percentage = (pointsObtained / maxPoints) * 100;
    }

    final response = await _client
        .from('assignment_grades')
        .insert({
          'school_id': schoolId,
          'submission_id': submissionId,
          'assignment_id': assignmentId,
          'student_id': studentId,
          'points_obtained': pointsObtained,
          'max_points': maxPoints,
          'percentage': percentage,
          'grade': grade,
          'grade_point': gradePoint,
          'teacher_feedback': teacherFeedback,
          'rubric_scores': rubricScores,
          'graded_by': gradedBy,
          'graded_at': DateTime.now().toIso8601String(),
          'is_published': isPublished ?? false,
          if (isPublished == true)
            'published_at': DateTime.now().toIso8601String(),
        })
        .select()
        .single();

    // Update submission status to graded
    await _client
        .from('assignment_submissions')
        .update({'submission_status': SubmissionStatus.graded.dbValue})
        .eq('id', submissionId);

    return AssignmentGrade.fromMap(response);
  }

  Future<AssignmentGrade> updateGrade({
    required String id,
    double? pointsObtained,
    double? maxPoints,
    String? grade,
    double? gradePoint,
    String? teacherFeedback,
    Map<String, dynamic>? rubricScores,
    bool? isPublished,
  }) async {
    final updates = <String, dynamic>{};
    if (pointsObtained != null) updates['points_obtained'] = pointsObtained;
    if (maxPoints != null) updates['max_points'] = maxPoints;
    if (grade != null) updates['grade'] = grade;
    if (gradePoint != null) updates['grade_point'] = gradePoint;
    if (teacherFeedback != null) updates['teacher_feedback'] = teacherFeedback;
    if (rubricScores != null) updates['rubric_scores'] = rubricScores;
    if (isPublished != null) {
      updates['is_published'] = isPublished;
      if (isPublished) {
        updates['published_at'] = DateTime.now().toIso8601String();
      }
    }

    // Recalculate percentage
    if (pointsObtained != null || maxPoints != null) {
      final current = await _client
          .from('assignment_grades')
          .select('points_obtained, max_points')
          .eq('id', id)
          .single();
      final pts =
          pointsObtained ?? (current['points_obtained'] as num?)?.toDouble();
      final max = maxPoints ?? (current['max_points'] as num?)?.toDouble();
      if (pts != null && max != null && max > 0) {
        updates['percentage'] = (pts / max) * 100;
      }
    }

    final response = await _client
        .from('assignment_grades')
        .update(updates)
        .eq('id', id)
        .select()
        .single();

    return AssignmentGrade.fromMap(response);
  }

  Future<List<AssignmentGrade>> fetchGrades({
    required String schoolId,
    String? assignmentId,
    String? studentId,
    bool? isPublished,
  }) async {
    var query = _client
        .from('assignment_grades')
        .select()
        .eq('school_id', schoolId);

    if (assignmentId != null) {
      query = query.eq('assignment_id', assignmentId);
    }
    if (studentId != null) {
      query = query.eq('student_id', studentId);
    }
    if (isPublished != null) {
      query = query.eq('is_published', isPublished);
    }

    final response = await query.order('graded_at', ascending: false);
    return (response as List)
        .map((row) => AssignmentGrade.fromMap(row as Map<String, dynamic>))
        .toList();
  }

  Future<AssignmentGrade?> getGradeForSubmission(String submissionId) async {
    try {
      final response = await _client
          .from('assignment_grades')
          .select()
          .eq('submission_id', submissionId)
          .maybeSingle();

      if (response == null) return null;
      return AssignmentGrade.fromMap(response);
    } catch (e) {
      return null;
    }
  }

  // ============================================================
  // ASSIGNMENT ATTACHMENTS
  // ============================================================

  Future<AssignmentAttachment> createAttachment({
    required String schoolId,
    required String assignmentId,
    required String fileName,
    required String filePath,
    int? fileSize,
    String? fileType,
    String? uploadedBy,
  }) async {
    final response = await _client
        .from('assignment_attachments')
        .insert({
          'school_id': schoolId,
          'assignment_id': assignmentId,
          'file_name': fileName,
          'file_path': filePath,
          'file_size': fileSize,
          'file_type': fileType,
          'uploaded_by': uploadedBy,
        })
        .select()
        .single();

    return AssignmentAttachment.fromMap(response);
  }

  Future<List<AssignmentAttachment>> fetchAttachments({
    required String schoolId,
    required String assignmentId,
  }) async {
    final response = await _client
        .from('assignment_attachments')
        .select()
        .eq('school_id', schoolId)
        .eq('assignment_id', assignmentId)
        .order('created_at');

    return (response as List)
        .map((row) => AssignmentAttachment.fromMap(row as Map<String, dynamic>))
        .toList();
  }

  Future<void> deleteAttachment(String id) async {
    await _client.from('assignment_attachments').delete().eq('id', id);
  }
}
