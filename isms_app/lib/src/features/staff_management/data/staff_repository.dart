import 'dart:math';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/app_error.dart';
import '../../../core/errors/error_handler.dart';
import '../../../core/errors/error_repository_mixin.dart';
import '../../../core/errors/validation.dart';
import '../../../core/network/supabase_client.dart';
import '../../authentication/domain/user_role.dart';
import '../domain/staff_invite.dart';
import '../domain/staff_member.dart';

/// Repository for staff management
/// 
/// Handles all database operations for staff members and invites with
/// proper error handling, validation, and timeouts.
class StaffRepository with ErrorRepositoryMixin {
  SupabaseClient get _client => SupabaseManager.client;
  String? _schoolId;

  void setSchoolId(String? schoolId) {
    _schoolId = schoolId;
  }

  String? get schoolId => _schoolId;

  Future<List<StaffMember>> getStaff({
    String? query,
    String? role,
    String? status,
  }) async {
    final correlationId = ErrorHandler.generateCorrelationId();
    
    return safeDbOperation(
      operation: () async {
        final schoolId = _schoolId;
        if (schoolId == null) {
          return <StaffMember>[];
        }

        // Validate school ID
        final validationError = Validation.validateUuid(schoolId, 'school_id');
        if (validationError != null) {
          throw validationError;
        }

        // Sanitize query
        final sanitizedQuery = query?.trim();
        if (sanitizedQuery != null && sanitizedQuery.isEmpty) {
          // Empty query is valid, just ignore it
        }

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
        if (sanitizedQuery != null && sanitizedQuery.isNotEmpty) {
          // Limit query length to prevent abuse
          final limitedQuery = sanitizedQuery.length > 100
              ? sanitizedQuery.substring(0, 100)
              : sanitizedQuery;
          searchExpression =
              'email.ilike.%$limitedQuery%,user_profiles.full_name.ilike.%$limitedQuery%';
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
        
        // Parse with error handling
        final staff = <StaffMember>[];
        for (final row in data as List) {
          try {
            final member = StaffMember.fromMap(
              Map<String, dynamic>.from(row as Map<String, dynamic>),
            );
            staff.add(member);
          } catch (e, stackTrace) {
            final error = ErrorHandler.handleException(
              e,
              stackTrace: stackTrace,
              correlationId: correlationId,
              context: 'Parsing staff member data',
            );
            ErrorHandler.logError(error, context: 'getStaff');
            // Continue with other members
          }
        }

        return staff;
      },
      context: 'StaffRepository.getStaff',
      correlationId: correlationId,
    );
  }

  Future<List<StaffInvite>> getInvites({String? status}) async {
    final correlationId = ErrorHandler.generateCorrelationId();
    
    return safeDbOperation(
      operation: () async {
        final schoolId = _schoolId;
        if (schoolId == null) {
          return <StaffInvite>[];
        }

        // Validate school ID
        final validationError = Validation.validateUuid(schoolId, 'school_id');
        if (validationError != null) {
          throw validationError;
        }

        var request = _client
            .from('staff_invites')
            .select()
            .eq('school_id', schoolId);

        if (status != null && status.isNotEmpty) {
          request = request.eq('status', status);
        }

        final data = await request.order('created_at', ascending: false);
        
        // Parse with error handling
        final invites = <StaffInvite>[];
        for (final row in data as List) {
          try {
            final invite = StaffInvite.fromMap(
              Map<String, dynamic>.from(row as Map<String, dynamic>),
            );
            invites.add(invite);
          } catch (e, stackTrace) {
            final error = ErrorHandler.handleException(
              e,
              stackTrace: stackTrace,
              correlationId: correlationId,
              context: 'Parsing staff invite data',
            );
            ErrorHandler.logError(error, context: 'getInvites');
            // Continue with other invites
          }
        }

        return invites;
      },
      context: 'StaffRepository.getInvites',
      correlationId: correlationId,
    );
  }

  Future<StaffInvite> createInvite({
    required String email,
    required UserRole role,
    String? fullName,
    String? notes,
    int? expiresInDays,
    String? invitedByUserId,
  }) async {
    final correlationId = ErrorHandler.generateCorrelationId();
    
    return safeDbOperation(
      operation: () async {
        // Input validation
        final emailError = Validation.validateEmail(email);
        if (emailError != null) throw emailError;

        if (expiresInDays != null) {
          final expiresError = Validation.validateRange(
            expiresInDays,
            'expiresInDays',
            min: 1,
            max: 365,
          );
          if (expiresError != null) throw expiresError;
        }

        if (fullName != null) {
          final nameError = Validation.validateLength(
            fullName,
            'fullName',
            max: 100,
          );
          if (nameError != null) throw nameError;
        }

        if (notes != null) {
          final notesError = Validation.validateLength(notes, 'notes', max: 500);
          if (notesError != null) throw notesError;
        }

        final schoolId = validateSchoolId(_schoolId, correlationId: correlationId);

        final code = _generateInviteCode();
        final expiresAt = expiresInDays != null
            ? DateTime.now().add(Duration(days: expiresInDays))
            : null;

        final result = await _client
            .from('staff_invites')
            .insert({
              'school_id': schoolId,
              'email': Validation.sanitizeEmail(email),
              'role': _roleToString(role),
              'full_name': Validation.sanitizeString(fullName),
              'notes': Validation.sanitizeString(notes),
              'invite_code': code,
              'invited_by': invitedByUserId,
              'expires_at': expiresAt?.toIso8601String(),
            })
            .select()
            .single();

        return StaffInvite.fromMap(
          Map<String, dynamic>.from(result),
        );
      },
      context: 'StaffRepository.createInvite',
      correlationId: correlationId,
    );
  }

  Future<void> cancelInvite(String inviteId) async {
    final correlationId = ErrorHandler.generateCorrelationId();
    
    return safeDbOperation(
      operation: () async {
        // Validate invite ID
        final validationError = Validation.validateUuid(inviteId, 'inviteId');
        if (validationError != null) {
          throw validationError;
        }

        await _client
            .from('staff_invites')
            .update({'status': 'cancelled'})
            .eq('id', inviteId);
      },
      context: 'StaffRepository.cancelInvite',
      correlationId: correlationId,
    );
  }

  Future<void> resendInvite(String inviteId) async {
    final correlationId = ErrorHandler.generateCorrelationId();
    
    return safeDbOperation(
      operation: () async {
        // Validate invite ID
        final validationError = Validation.validateUuid(inviteId, 'inviteId');
        if (validationError != null) {
          throw validationError;
        }

        await _client
            .from('staff_invites')
            .update({'status': 'pending', 'accepted_at': null})
            .eq('id', inviteId);
      },
      context: 'StaffRepository.resendInvite',
      correlationId: correlationId,
    );
  }

  Future<void> updateStaffRole({
    required String userId,
    required UserRole role,
  }) async {
    final correlationId = ErrorHandler.generateCorrelationId();
    
    return safeDbOperation(
      operation: () async {
        // Validate inputs
        final userIdError = Validation.validateUuid(userId, 'userId');
        if (userIdError != null) throw userIdError;

        final schoolId = validateSchoolId(_schoolId, correlationId: correlationId);

        await _client
            .from('users')
            .update({'role': _roleToString(role)})
            .eq('id', userId)
            .eq('school_id', schoolId);
      },
      context: 'StaffRepository.updateStaffRole',
      correlationId: correlationId,
    );
  }

  Future<void> updateStaffStatus({
    required String userId,
    required String status,
  }) async {
    final correlationId = ErrorHandler.generateCorrelationId();
    
    return safeDbOperation(
      operation: () async {
        // Validate inputs
        final userIdError = Validation.validateUuid(userId, 'userId');
        if (userIdError != null) throw userIdError;

        // Validate status value
        const validStatuses = ['active', 'inactive', 'suspended', 'pending'];
        if (!validStatuses.contains(status.toLowerCase())) {
          throw ValidationError(
            message: 'Invalid status: $status',
            userMessage: 'Invalid staff status.',
            field: 'status',
          );
        }

        final schoolId = validateSchoolId(_schoolId, correlationId: correlationId);

        await _client
            .from('users')
            .update({'status': status.toLowerCase()})
            .eq('id', userId)
            .eq('school_id', schoolId);
      },
      context: 'StaffRepository.updateStaffStatus',
      correlationId: correlationId,
    );
  }

  Future<Map<String, dynamic>?> validateInvite({
    required String code,
    required String email,
  }) async {
    final correlationId = ErrorHandler.generateCorrelationId();
    
    return safeDbOperation(
      operation: () async {
        // Validate inputs
        if (code.isEmpty) {
          throw ValidationError.missingField('code');
        }

        final emailError = Validation.validateEmail(email);
        if (emailError != null) throw emailError;

        final result = await _client.rpc(
          'validate_staff_invite',
          params: {
            'p_invite_code': code.trim(),
            'p_email': Validation.sanitizeEmail(email),
          },
        );

        if (result == null) return null;

        if (result is List && result.isEmpty) {
          return null;
        }

        if (result is List && result.isNotEmpty) {
          return Map<String, dynamic>.from(
            result.first as Map<String, dynamic>,
          );
        }

        return Map<String, dynamic>.from(result as Map<String, dynamic>);
      },
      context: 'StaffRepository.validateInvite',
      correlationId: correlationId,
    );
  }

  Future<void> consumeInvite(String code) async {
    final correlationId = ErrorHandler.generateCorrelationId();
    
    return safeDbOperation(
      operation: () async {
        if (code.isEmpty) {
          throw ValidationError.missingField('code');
        }

        await _client.rpc(
          'consume_staff_invite',
          params: {'p_invite_code': code.trim()},
        );
      },
      context: 'StaffRepository.consumeInvite',
      correlationId: correlationId,
    );
  }

  Future<String?> getCurrentUserRowId() async {
    final correlationId = ErrorHandler.generateCorrelationId();
    
    try {
      final authId = _client.auth.currentUser?.id;
      if (authId == null) return null;

      final response = await _client
          .from('users')
          .select('id')
          .eq('auth_id', authId)
          .maybeSingle()
          .timeout(const Duration(seconds: 5));

      if (response == null) return null;
      return response['id'] as String?;
    } catch (e, stackTrace) {
      final error = ErrorHandler.handleException(
        e,
        stackTrace: stackTrace,
        correlationId: correlationId,
        context: 'StaffRepository.getCurrentUserRowId',
      );
      ErrorHandler.logError(error);
      return null; // Return null instead of throwing for this helper method
    }
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
