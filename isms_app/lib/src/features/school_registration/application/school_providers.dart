import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/tenant/tenant_context.dart';
import '../data/school_repository.dart';
import '../domain/global_analytics.dart';
import '../domain/school.dart';
import '../domain/school_analytics.dart';
import '../domain/tenant_onboarding_status.dart';

typedef SchoolListFilters = ({
  String? status,
  String? subscriptionPlan,
  String? query,
});

final schoolRepositoryProvider = Provider<SchoolRepository>((ref) {
  return SchoolRepository();
});

final currentSchoolProvider = Provider<School?>((ref) {
  // Get school from tenant context (reactive).
  // NOTE: This MUST be reactive so screens/providers update when the school
  // context is loaded after login.
  return ref.watch(tenantContextProvider);
});

final schoolProvider = FutureProvider.family<School?, String>((
  ref,
  schoolId,
) async {
  final repo = ref.read(schoolRepositoryProvider);
  return repo.getSchoolById(schoolId);
});

final allSchoolsProvider =
    FutureProvider.family<List<School>, SchoolListFilters>((
      ref,
      filters,
    ) async {
      final repo = ref.read(schoolRepositoryProvider);
      return repo.getAllSchools(
        status: filters.status,
        subscriptionPlan: filters.subscriptionPlan,
        queryText: filters.query,
      );
    });

final schoolAnalyticsProvider = FutureProvider.family<SchoolAnalytics, String>((
  ref,
  schoolId,
) async {
  final repo = ref.read(schoolRepositoryProvider);
  return repo.getSchoolAnalytics(schoolId);
});

final tenantOnboardingProvider =
    FutureProvider.family<TenantOnboardingStatus, String>((
      ref,
      schoolId,
    ) async {
      final repo = ref.read(schoolRepositoryProvider);
      return repo.getTenantOnboardingStatus(schoolId);
    });

final globalAnalyticsProvider = FutureProvider<GlobalAnalytics>((ref) async {
  final repo = ref.read(schoolRepositoryProvider);
  return repo.getGlobalAnalytics();
});
