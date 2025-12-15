import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/network/supabase_client.dart';
import '../domain/tenant.dart';
import '../domain/tenant_settings.dart';

class TenantRepository {
  SupabaseClient get _client => SupabaseManager.client;

  Future<List<Tenant>> fetchTenants({String? queryText, String? status}) async {
    var request = _client.from('tenants').select();

    if (status != null && status.isNotEmpty && status != 'all') {
      request = request.eq('status', status);
    }

    if (queryText != null && queryText.trim().isNotEmpty) {
      final value = queryText.trim();
      request = request.or('name.ilike.%$value%,email.ilike.%$value%');
    }

    final response = await request.order('created_at', ascending: false);
    return (response as List)
        .map((row) => Tenant.fromMap(row as Map<String, dynamic>))
        .toList();
  }

  Future<TenantSettings?> fetchSettings(String schoolId) async {
    final response = await _client
        .from('tenant_settings')
        .select()
        .eq('school_id', schoolId)
        .maybeSingle();

    if (response == null) return null;
    return TenantSettings.fromMap(Map<String, dynamic>.from(response));
  }

  Future<void> updateSettings({
    required String schoolId,
    required Map<String, dynamic> payload,
  }) async {
    await _client.rpc(
      'upsert_tenant_settings',
      params: {'p_school_id': schoolId, 'p_payload': payload},
    );
  }
}
