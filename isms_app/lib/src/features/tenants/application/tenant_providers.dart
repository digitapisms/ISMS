import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/tenant_repository.dart';
import '../domain/tenant.dart';
import '../domain/tenant_settings.dart';

typedef TenantFilter = ({String? status, String? query});

final tenantRepositoryProvider = Provider<TenantRepository>((ref) {
  return TenantRepository();
});

final tenantsProvider = FutureProvider.family
    .autoDispose<List<Tenant>, TenantFilter>((ref, filter) {
      final repo = ref.read(tenantRepositoryProvider);
      return repo.fetchTenants(queryText: filter.query, status: filter.status);
    });

final tenantSettingsProvider = FutureProvider.family
    .autoDispose<TenantSettings?, String>((ref, schoolId) {
      final repo = ref.read(tenantRepositoryProvider);
      return repo.fetchSettings(schoolId);
    });

class TenantSettingsUpdateRequest {
  TenantSettingsUpdateRequest({required this.schoolId, required this.payload});

  final String schoolId;
  final Map<String, dynamic> payload;
}

final tenantSettingsUpdateProvider = FutureProvider.family
    .autoDispose<void, TenantSettingsUpdateRequest>((ref, request) async {
      final repo = ref.read(tenantRepositoryProvider);
      await repo.updateSettings(
        schoolId: request.schoolId,
        payload: request.payload,
      );
      ref.invalidate(tenantSettingsProvider(request.schoolId));
    });
