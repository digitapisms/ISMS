import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/network/supabase_client.dart';
import '../domain/staff_profile.dart';
import '../domain/staff_attendance.dart';
import '../domain/leave_request.dart';

class StaffRepository {
  SupabaseClient get _client => SupabaseManager.client;
  String? _schoolId;

  void setSchoolId(String? schoolId) {
    _schoolId = schoolId;
  }

  String? get schoolId => _schoolId;

  String _requireSchoolId() {
    final id = _schoolId;
    if (id == null) {
      throw Exception('School context is required');
    }
    return id;
  }

  Map<String, dynamic> _withSchoolId(Map<String, dynamic> data) {
    final id = _schoolId;
    if (id == null) return data;
    return {...data, 'school_id': id};
  }

  // ============================================================
  // STAFF PROFILES
  // ============================================================

  Future<StaffProfile> createStaffProfile(StaffProfile profile) async {
    _requireSchoolId();
    final response = await _client
        .from('staff_profiles')
        .insert(_withSchoolId(profile.toMap()))
        .select()
        .single();
    return StaffProfile.fromMap(response);
  }

  Future<List<StaffProfile>> fetchStaffProfiles({
    bool? activeOnly = true,
    String? department,
    String? employmentType,
  }) async {
    final schoolId = _requireSchoolId();
    
    var query = _client
        .from('staff_profiles')
        .select()
        .eq('school_id', schoolId);
    
    if (activeOnly == true) {
      query = query.eq('is_active', true);
    }
    
    if (department != null) {
      query = query.eq('department', department);
    }
    
    if (employmentType != null) {
      query = query.eq('employment_type', employmentType);
    }
    
    final response = await query.order('full_name');
    return response.map((data) => StaffProfile.fromMap(data)).toList();
  }

  Future<StaffProfile> fetchStaffProfile(String staffId) async {
    _requireSchoolId();
    final response = await _client
        .from('staff_profiles')
        .select()
        .eq('id', staffId)
        .single();
    return StaffProfile.fromMap(response);
  }

  Future<StaffProfile> updateStaffProfile(StaffProfile profile) async {
    _requireSchoolId();
    final response = await _client
        .from('staff_profiles')
        .update(profile.toMap())
        .eq('id', profile.id)
        .select()
        .single();
    return StaffProfile.fromMap(response);
  }

  Future<void> deleteStaffProfile(String staffId) async {
    _requireSchoolId();
    await _client
        .from('staff_profiles')
        .delete()
        .eq('id', staffId);
  }

  // ============================================================
  // STAFF ATTENDANCE
  // ============================================================

  Future<StaffAttendance> recordAttendance(StaffAttendance attendance) async {
    _requireSchoolId();
    final response = await _client
        .from('staff_attendance')
        .insert(_withSchoolId(attendance.toMap()))
        .select()
        .single();
    return StaffAttendance.fromMap(response);
  }

  Future<List<StaffAttendance>> fetchStaffAttendance({
    required String staffId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    _requireSchoolId();
    
    var query = _client
        .from('staff_attendance')
        .select()
        .eq('staff_id', staffId);
    
    if (startDate != null && endDate != null) {
      query = query
          .gte('attendance_date', startDate.toIso8601String())
          .lte('attendance_date', endDate.toIso8601String());
    }
    
    final response = await query.order('attendance_date', ascending: false);
    return response.map((data) => StaffAttendance.fromMap(data)).toList();
  }

  Future<StaffAttendance> updateAttendance(StaffAttendance attendance) async {
    _requireSchoolId();
    final response = await _client
        .from('staff_attendance')
        .update(attendance.toMap())
        .eq('id', attendance.id)
        .select()
        .single();
    return StaffAttendance.fromMap(response);
  }

  Future<Map<String, dynamic>> getAttendanceSummary({
    required String staffId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    _requireSchoolId();
    
    final response = await _client.rpc('get_staff_attendance_summary', params: {
      'p_staff_id': staffId,
      'p_start_date': startDate?.toIso8601String(),
      'p_end_date': endDate?.toIso8601String(),
    });
    
    return response as Map<String, dynamic>? ?? {};
  }

  // ============================================================
  // LEAVE MANAGEMENT
  // ============================================================

  Future<LeaveRequest> createLeaveRequest(LeaveRequest leaveRequest) async {
    _requireSchoolId();
    final response = await _client
        .from('leave_requests')
        .insert(_withSchoolId(leaveRequest.toMap()))
        .select()
        .single();
    return LeaveRequest.fromMap(response);
  }

  Future<List<LeaveRequest>> fetchLeaveRequests({
    String? staffId,
    String? status,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final schoolId = _requireSchoolId();
    
    var query = _client
        .from('leave_requests')
        .select()
        .eq('school_id', schoolId);
    
    if (staffId != null) {
      query = query.eq('staff_id', staffId);
    }
    
    if (status != null) {
      query = query.eq('status', status);
    }
    
    if (startDate != null && endDate != null) {
      query = query
          .gte('start_date', startDate.toIso8601String())
          .lte('end_date', endDate.toIso8601String());
    }
    
    final response = await query.order('created_at', ascending: false);
    return response.map((data) => LeaveRequest.fromMap(data)).toList();
  }

  Future<LeaveRequest> updateLeaveRequest(LeaveRequest leaveRequest) async {
    _requireSchoolId();
    final response = await _client
        .from('leave_requests')
        .update(leaveRequest.toMap())
        .eq('id', leaveRequest.id)
        .select()
        .single();
    return LeaveRequest.fromMap(response);
  }

  Future<void> approveLeaveRequest(String leaveRequestId, String approvedBy) async {
    _requireSchoolId();
    await _client
        .from('leave_requests')
        .update({
          'status': 'approved',
          'approved_by': approvedBy,
          'approved_at': DateTime.now().toIso8601String(),
        })
        .eq('id', leaveRequestId);
  }

  Future<void> rejectLeaveRequest(String leaveRequestId, String rejectedBy, String reason) async {
    _requireSchoolId();
    await _client
        .from('leave_requests')
        .update({
          'status': 'rejected',
          'approved_by': rejectedBy,
          'approved_at': DateTime.now().toIso8601String(),
          'rejection_reason': reason,
        })
        .eq('id', leaveRequestId);
  }

  // ============================================================
  // UTILITY METHODS
  // ============================================================

  Future<int> getActiveStaffCount() async {
    final schoolId = _requireSchoolId();
    final response = await _client
        .from('staff_profiles')
        .select('id', count: CountOption.exact)
        .eq('school_id', schoolId)
        .eq('is_active', true);
    return response.count ?? 0;
  }

  Future<Map<String, dynamic>> getStaffStatistics() async {
    final schoolId = _requireSchoolId();
    
    final response = await _client.rpc('get_staff_statistics', params: {
      'p_school_id': schoolId,
    });
    
    return response as Map<String, dynamic>? ?? {};
  }
}