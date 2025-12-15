import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/network/supabase_client.dart';
import '../../student_management/domain/student.dart';
import '../domain/attendance_record.dart';
import '../domain/attendance_stats.dart';
import '../domain/attendance_status.dart';
import '../domain/attendance_summary.dart';

class AttendanceRepository {
  SupabaseClient get _client => SupabaseManager.client;

  /// Mark attendance for a single student
  Future<AttendanceRecord> markAttendance({
    required String schoolId,
    required String studentId,
    required DateTime attendanceDate,
    required AttendanceStatus status,
    int? classId,
    int? sectionId,
    String? notes,
    int? periodNumber,
  }) async {
    final userId = await _getCurrentUserId();
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    final response = await _client
        .from('attendance_records')
        .upsert({
          'school_id': schoolId,
          'student_id': studentId,
          'attendance_date': attendanceDate.toIso8601String().split('T')[0],
          'status': status.dbValue,
          if (classId != null) 'class_id': classId,
          if (sectionId != null) 'section_id': sectionId,
          'marked_by': userId,
          if (notes != null) 'notes': notes,
          if (periodNumber != null) 'period_number': periodNumber,
        })
        .select()
        .maybeSingle();

    if (response == null) {
      throw Exception('Failed to mark attendance');
    }

    return AttendanceRecord.fromMap(response);
  }

  /// Bulk mark attendance for multiple students
  Future<int> bulkMarkAttendance({
    required String schoolId,
    required int classId,
    int? sectionId,
    required DateTime attendanceDate,
    required List<Map<String, dynamic>> records,
  }) async {
    final userId = await _getCurrentUserId();
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    final response = await _client.rpc(
      'bulk_mark_attendance',
      params: {
        'p_school_id': schoolId,
        'p_class_id': classId,
        'p_section_id': sectionId,
        'p_attendance_date': attendanceDate.toIso8601String().split('T')[0],
        'p_records': records,
        'p_marked_by': userId,
      },
    );

    return response is int ? response : 0;
  }

  /// Fetch attendance records for a student
  Future<List<AttendanceRecord>> fetchStudentAttendance({
    required String schoolId,
    required String studentId,
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
  }) async {
    dynamic query = _client
        .from('attendance_records')
        .select()
        .eq('school_id', schoolId)
        .eq('student_id', studentId);

    if (startDate != null) {
      query = query.gte(
        'attendance_date',
        startDate.toIso8601String().split('T')[0],
      );
    }
    if (endDate != null) {
      query = query.lte(
        'attendance_date',
        endDate.toIso8601String().split('T')[0],
      );
    }
    query = query.order('attendance_date', ascending: false);
    if (limit != null) {
      query = query.limit(limit);
    }

    final response = await query;
    final responseList = response as List;
    return responseList
        .map((row) => AttendanceRecord.fromMap(row as Map<String, dynamic>))
        .toList();
  }

  /// Fetch attendance records for a class/section on a specific date
  Future<List<AttendanceRecord>> fetchClassAttendance({
    required String schoolId,
    required int classId,
    int? sectionId,
    required DateTime attendanceDate,
  }) async {
    dynamic query = _client
        .from('attendance_records')
        .select()
        .eq('school_id', schoolId)
        .eq('class_id', classId)
        .eq('attendance_date', attendanceDate.toIso8601String().split('T')[0]);

    if (sectionId != null) {
      query = query.eq('section_id', sectionId);
    }
    query = query.order('student_id');

    final response = await query;
    final responseList = response as List;
    return responseList
        .map((row) => AttendanceRecord.fromMap(row as Map<String, dynamic>))
        .toList();
  }

  /// Get attendance statistics for a student
  Future<AttendanceStats> getStudentAttendanceStats({
    required String studentId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final response = await _client.rpc(
      'get_student_attendance_stats',
      params: {
        'p_student_id': studentId,
        'p_start_date': startDate.toIso8601String().split('T')[0],
        'p_end_date': endDate.toIso8601String().split('T')[0],
      },
    );

    if (response == null || (response is List && response.isEmpty)) {
      return const AttendanceStats(
        totalDays: 0,
        presentDays: 0,
        absentDays: 0,
        lateDays: 0,
        excusedDays: 0,
        halfDayDays: 0,
        attendancePercentage: 0.0,
      );
    }

    final responseList = response as List;
    return AttendanceStats.fromMap(responseList.first as Map<String, dynamic>);
  }

  /// Get attendance summary for a class/section on a date
  Future<AttendanceSummary> getClassAttendanceSummary({
    required String schoolId,
    required int classId,
    int? sectionId,
    required DateTime attendanceDate,
  }) async {
    final response = await _client.rpc(
      'get_class_attendance_summary',
      params: {
        'p_school_id': schoolId,
        'p_class_id': classId,
        'p_section_id': sectionId,
        'p_attendance_date': attendanceDate.toIso8601String().split('T')[0],
      },
    );

    if (response == null || (response is List && response.isEmpty)) {
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

    final responseList = response as List;
    return AttendanceSummary.fromMap(
      responseList.first as Map<String, dynamic>,
    );
  }

  /// Fetch students for a class/section (for marking attendance)
  Future<List<Student>> fetchStudentsForAttendance({
    required String schoolId,
    required int classId,
    int? sectionId,
  }) async {
    dynamic query = _client
        .from('students')
        .select()
        .eq('school_id', schoolId)
        .eq('class_id', classId)
        .eq('status', 'active');

    if (sectionId != null) {
      query = query.eq('section_id', sectionId);
    }
    query = query.order('admission_no');

    final response = await query;
    final responseList = response as List;
    return responseList
        .map((row) => Student.fromMap(row as Map<String, dynamic>))
        .toList();
  }

  /// Update attendance record
  Future<AttendanceRecord> updateAttendance({
    required String recordId,
    required AttendanceStatus status,
    String? notes,
  }) async {
    final response = await _client
        .from('attendance_records')
        .update({'status': status.dbValue, if (notes != null) 'notes': notes})
        .eq('id', recordId)
        .select()
        .maybeSingle();

    if (response == null) {
      throw Exception('Failed to update attendance');
    }

    return AttendanceRecord.fromMap(response);
  }

  /// Delete attendance record
  Future<void> deleteAttendance(String recordId) async {
    await _client.from('attendance_records').delete().eq('id', recordId);
  }

  /// Get current user's database ID
  Future<String?> _getCurrentUserId() async {
    final authUser = _client.auth.currentUser;
    if (authUser == null) return null;

    final response = await _client
        .from('users')
        .select('id')
        .eq('auth_id', authUser.id)
        .maybeSingle();

    if (response == null) return null;
    return (response)['id'] as String?;
  }
}
