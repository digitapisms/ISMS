import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_error.dart';
import '../../../core/errors/error_handler.dart';
import '../../../core/errors/validation.dart';
import '../../../core/tenant/tenant_context.dart';
import '../../authentication/application/auth_providers.dart';
import '../../authentication/domain/user_role.dart';
import '../data/staff_repository.dart';
import '../domain/staff_invite.dart';
import '../domain/staff_member.dart';

typedef StaffListFilters = ({String? query, String? role, String? status});

typedef StaffInviteFilters = ({String? status});

final staffRepositoryProvider = Provider<StaffRepository>((ref) {
  final repo = StaffRepository();
  final tenantSchool = ref.read(tenantContextProvider);
  final authUser = ref.watch(authStateProvider);
  final schoolId = tenantSchool?.id ?? authUser?.schoolId;
  if (schoolId != null) {
    repo.setSchoolId(schoolId);
  }
  return repo;
});

// Helper to get school ID with validation
Future<String?> _getSchoolId(Ref ref) async {
  try {
    final tenantSchool = ref.read(tenantContextProvider);
    final authUser = ref.read(authStateProvider);
    final schoolId = tenantSchool?.id ?? authUser?.schoolId;

    if (schoolId != null) {
      final validationError = Validation.validateUuid(schoolId, 'school_id');
      if (validationError == null) {
        return schoolId;
      }
    }

    await Future.delayed(const Duration(milliseconds: 200));
    final tenantSchool2 = ref.read(tenantContextProvider);
    final authUser2 = ref.read(authStateProvider);
    final schoolId2 = tenantSchool2?.id ?? authUser2?.schoolId;

    if (schoolId2 != null) {
      final validationError = Validation.validateUuid(schoolId2, 'school_id');
      if (validationError == null) {
        return schoolId2;
      }
    }

    return null;
  } catch (e) {
    debugPrint('Error getting school ID for staff: $e');
    return null;
  }
}

final staffListProvider =
    FutureProvider.family<List<StaffMember>, StaffListFilters>((
      ref,
      filters,
    ) async {
      final correlationId = ErrorHandler.generateCorrelationId();
      
      try {
        final schoolId = await _getSchoolId(ref);

        if (schoolId == null) {
          return <StaffMember>[];
        }

        final repo = ref.read(staffRepositoryProvider);
        return await repo.getStaff(
          query: filters.query,
          role: filters.role,
          status: filters.status,
        );
      } catch (e) {
        final error = ErrorHandler.handleException(
          e,
          correlationId: correlationId,
          context: 'StaffListProvider',
        );
        ErrorHandler.logError(error, context: 'StaffListProvider');
        return <StaffMember>[];
      }
    });

final staffInvitesProvider =
    FutureProvider.family<List<StaffInvite>, StaffInviteFilters>((
      ref,
      filters,
    ) async {
      final correlationId = ErrorHandler.generateCorrelationId();
      
      try {
        final schoolId = await _getSchoolId(ref);

        if (schoolId == null) {
          return <StaffInvite>[];
        }

        final repo = ref.read(staffRepositoryProvider);
        return await repo.getInvites(status: filters.status);
      } catch (e) {
        final error = ErrorHandler.handleException(
          e,
          correlationId: correlationId,
          context: 'StaffInvitesProvider',
        );
        ErrorHandler.logError(error, context: 'StaffInvitesProvider');
        return <StaffInvite>[];
      }
    });

final staffInviteCreationProvider =
    FutureProvider.family<
      StaffInvite,
      ({
        String email,
        UserRole role,
        String? fullName,
        String? notes,
        int? expiresInDays,
      })
    >((ref, args) async {
      final correlationId = ErrorHandler.generateCorrelationId();
      
      try {
        final schoolId = await _getSchoolId(ref);

        if (schoolId == null) {
          throw ValidationError.missingField('school_id');
        }

        final repo = ref.read(staffRepositoryProvider);
        final invitedBy = await repo.getCurrentUserRowId();
        
        return await repo.createInvite(
          email: args.email,
          role: args.role,
          fullName: args.fullName,
          notes: args.notes,
          expiresInDays: args.expiresInDays,
          invitedByUserId: invitedBy,
        );
      } catch (e) {
        final error = ErrorHandler.handleException(
          e,
          correlationId: correlationId,
          context: 'StaffInviteCreationProvider',
        );
        ErrorHandler.logError(error, context: 'StaffInviteCreationProvider');
        rethrow;
      }
    });
