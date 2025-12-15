import 'dart:math';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/network/supabase_client.dart';
import '../../authentication/domain/user_role.dart';
import '../domain/staff_invite.dart';
import '../domain/staff_member.dart';

class StaffRepository {
  SupabaseClient get _client => SupabaseManager.client;
  String? _schoolId;

  void setSchoolId(String? schoolId) {
    _schoolId = schoolId;
  }

  String _requireSchoolId() {
    final id = _schoolId;
    if (id == null) {
      throw Exception('School context required for staff actions.');
    }
    return id;
  }

  Future<List<StaffMember>> getStaff({
    String? query,
    String? role,
    String? status,
  }) async {
    final schoolId = _requireSchoolId();
    var request = _client
        .from('users')
        .select(
          'id, auth_id, email, role, status, school_id, created_at, last_login_at, user_profiles(full_name, phone_number, avatar_url)',
        )
        .eq('school_id', schoolId)
        .neq('role', 'student')
        .neq('role', 'parent')
        .neq('role', 'applicant');
    String? searchExpression;
    if (query != null && query.trim().isNotEmpty) {
      final value = query.trim();
      searchExpression =
          'email.ilike.%$value%,user_profiles.full_name.ilike.%$value%';
    }
    if (role != null && role.isNotEmpty) {
      request = request.eq('role', role);
    }
    if (status != null && status.isNotEmpty) {
      request = request.eq('status', status);
    }

    var finalRequest = request;
    if (searchExpression != null) {
      finalRequest = finalRequest.or(searchExpression);
    }

    final data = await finalRequest.order('created_at', ascending: false);
    return (data as List<dynamic>)
        .map(
          (row) => StaffMember.fromMap(
            Map<String, dynamic>.from(row as Map<String, dynamic>),
          ),
        )
        .toList();
  }

  Future<List<StaffInvite>> getInvites({String? status}) async {
    final schoolId = _requireSchoolId();
    var request = _client
        .from('staff_invites')
        .select()
        .eq('school_id', schoolId);
    if (status != null && status.isNotEmpty) {
      request = request.eq('status', status);
    }

    final data = await request.order('created_at', ascending: false);
    return (data as List<dynamic>)
        .map(
          (row) => StaffInvite.fromMap(
            Map<String, dynamic>.from(row as Map<String, dynamic>),
          ),
        )
        .toList();
  }

  Future<StaffInvite> createInvite({
    required String email,
    required UserRole role,
    String? fullName,
    String? notes,
    int? expiresInDays,
    String? invitedByUserId,
  }) async {
    final schoolId = _requireSchoolId();
    final code = _generateInviteCode();
    final expiresAt = expiresInDays != null
        ? DateTime.now().add(Duration(days: expiresInDays))
        : null;

    final result = await _client
        .from('staff_invites')
        .insert({
          'school_id': schoolId,
          'email': email,
          'role': _roleToString(role),
          'full_name': fullName,
          'notes': notes,
          'invite_code': code,
          'invited_by': invitedByUserId,
          'expires_at': expiresAt?.toIso8601String(),
        })
        .select()
        .single();

    final invite = StaffInvite.fromMap(Map<String, dynamic>.from(result));
    return invite;
  }

  Future<void> cancelInvite(String inviteId) async {
    await _client
        .from('staff_invites')
        .update({'status': 'cancelled'})
        .eq('id', inviteId);
  }

  Future<void> resendInvite(String inviteId) async {
    await _client
        .from('staff_invites')
        .update({'status': 'pending', 'accepted_at': null})
        .eq('id', inviteId);
  }

  Future<void> updateStaffRole({
    required String userId,
    required UserRole role,
  }) async {
    final schoolId = _requireSchoolId();
    await _client
        .from('users')
        .update({'role': _roleToString(role)})
        .eq('id', userId)
        .eq('school_id', schoolId);
  }

  Future<void> updateStaffStatus({
    required String userId,
    required String status,
  }) async {
    final schoolId = _requireSchoolId();
    await _client
        .from('users')
        .update({'status': status})
        .eq('id', userId)
        .eq('school_id', schoolId);
  }

  Future<Map<String, dynamic>?> validateInvite({
    required String code,
    required String email,
  }) async {
    final result = await _client.rpc(
      'validate_staff_invite',
      params: {'p_invite_code': code, 'p_email': email},
    );

    if (result == null) return null;

    if (result is List && result.isEmpty) {
      return null;
    }

    if (result is List && result.isNotEmpty) {
      return Map<String, dynamic>.from(result.first as Map<String, dynamic>);
    }

    return Map<String, dynamic>.from(result as Map<String, dynamic>);
  }

  Future<void> consumeInvite(String code) async {
    await _client.rpc('consume_staff_invite', params: {'p_invite_code': code});
  }

  Future<String?> getCurrentUserRowId() async {
    final authId = _client.auth.currentUser?.id;
    if (authId == null) return null;
    final response = await _client
        .from('users')
        .select('id')
        .eq('auth_id', authId)
        .maybeSingle();
    if (response == null) return null;
    return response['id'] as String;
  }

  String _generateInviteCode() {
    const alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rand = Random.secure();
    return List.generate(
      8,
      (_) => alphabet[rand.nextInt(alphabet.length)],
    ).join();
  }

  String _roleToString(UserRole role) {
    switch (role) {
      case UserRole.superAdmin:
        return 'super_admin';
      case UserRole.admin:
        return 'admin';
      case UserRole.principal:
        return 'principal';
      case UserRole.teacher:
        return 'teacher';
      case UserRole.staff:
        return 'staff';
      case UserRole.student:
        return 'student';
      case UserRole.parent:
        return 'parent';
      case UserRole.applicant:
        return 'applicant';
    }
  }
}
