import 'package:flutter_riverpod/flutter_riverpod.dart';

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
  final tenantSchool = ref.watch(tenantContextProvider);
  final authUser = ref.watch(authStateProvider);
  repo.setSchoolId(tenantSchool?.id ?? authUser?.schoolId);
  return repo;
});

final staffListProvider =
    FutureProvider.family<List<StaffMember>, StaffListFilters>((ref, filters) {
      final repo = ref.read(staffRepositoryProvider);
      return repo.getStaff(
        query: filters.query,
        role: filters.role,
        status: filters.status,
      );
    });

final staffInvitesProvider =
    FutureProvider.family<List<StaffInvite>, StaffInviteFilters>((
      ref,
      filters,
    ) {
      final repo = ref.read(staffRepositoryProvider);
      return repo.getInvites(status: filters.status);
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
      final repo = ref.read(staffRepositoryProvider);
      final invitedBy = await repo.getCurrentUserRowId();
      return repo.createInvite(
        email: args.email,
        role: args.role,
        fullName: args.fullName,
        notes: args.notes,
        expiresInDays: args.expiresInDays,
        invitedByUserId: invitedBy,
      );
    });
