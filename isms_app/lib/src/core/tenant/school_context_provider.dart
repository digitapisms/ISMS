/// School context provider that loads school immediately on auth
///
/// This provider ensures school context is loaded synchronously
/// when user logs in, preventing infinite loading issues.

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/authentication/application/auth_providers.dart';
import '../../features/authentication/domain/user_role.dart';
import '../../features/school_registration/domain/school.dart';
import '../../features/school_registration/data/school_repository.dart';
import '../../features/school_registration/application/school_providers.dart';
import '../network/supabase_client.dart';
import 'tenant_context.dart';

/// Provider that automatically loads school when user logs in
final schoolContextLoaderProvider = FutureProvider<School?>((ref) async {
  final authUser = ref.watch(authStateProvider);

  if (authUser == null) {
    // Clear school context when user logs out
    ref.read(tenantContextProvider.notifier).clear();
    return null;
  }

  // Check if school is already set
  final currentSchool = ref.read(tenantContextProvider);
  if (currentSchool != null) {
    return currentSchool;
  }

  try {
    // Try to load school from user's school_id
    if (authUser.schoolId != null) {
      final repo = SchoolRepository();
      final school = await repo
          .getSchoolById(authUser.schoolId!)
          .timeout(const Duration(seconds: 5));

      if (school != null) {
        ref.read(tenantContextProvider.notifier).setSchool(school);
        return school;
      }
    }

    // Fallback: Try to find school by user's email/role
    if (authUser.role == UserRole.admin ||
        authUser.role == UserRole.principal) {
      final client = SupabaseManager.client;
      final userRows = await client
          .from('users')
          .select('id, school_id')
          .eq('auth_id', authUser.id)
          .limit(1)
          .timeout(const Duration(seconds: 5));

      if (userRows.isNotEmpty) {
        final row = (userRows as List).first as Map<String, dynamic>;
        final schoolId = row['school_id'] as String?;

        if (schoolId != null) {
          final repo = SchoolRepository();
          final school = await repo
              .getSchoolById(schoolId)
              .timeout(const Duration(seconds: 5));

          if (school != null) {
            ref.read(tenantContextProvider.notifier).setSchool(school);
            return school;
          }
        }
      }

      // Last resort: Find by email domain
      final schools = await client
          .from('schools')
          .select('id, name')
          .ilike('email', '%${authUser.email.split('@').last}%')
          .limit(1)
          .timeout(const Duration(seconds: 5));

      if (schools.isNotEmpty) {
        final school = (schools as List).first as Map<String, dynamic>;
        final schoolId = school['id'] as String;
        final repo = SchoolRepository();
        final fullSchool = await repo
            .getSchoolById(schoolId)
            .timeout(const Duration(seconds: 5));

        if (fullSchool != null) {
          ref.read(tenantContextProvider.notifier).setSchool(fullSchool);
          return fullSchool;
        }
      }
    }

    return null;
  } catch (e) {
    // Log error but don't throw - return null instead
    debugPrint('Error loading school context: $e');
    return null;
  }
});

/// Provider that ensures school context is loaded
/// This provider will wait for school to be loaded before completing
final schoolContextReadyProvider = FutureProvider<bool>((ref) async {
  final schoolLoader = ref.watch(schoolContextLoaderProvider);

  return schoolLoader.when(
    data: (school) => school != null,
    loading: () => false,
    error: (_, __) => false,
  );
});
