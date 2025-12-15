import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/network/supabase_client.dart';
import '../domain/plan_feature.dart';
import '../domain/subscription_plan.dart';

class SubscriptionRepository {
  SupabaseClient get _client => SupabaseManager.client;

  /// Get all available features
  Future<List<PlanFeature>> getAllFeatures() async {
    final response = await _client
        .from('plan_features')
        .select()
        .order('category')
        .order('feature_name');

    final data = response as List<dynamic>;
    return data
        .map((row) => PlanFeature.fromMap(row as Map<String, dynamic>))
        .toList();
  }

  /// Get features for a specific plan
  Future<List<PlanFeatureMapping>> getPlanFeatures(String planName) async {
    final response = await _client
        .from('plan_feature_mapping')
        .select('''
          *,
          feature:plan_features(*)
        ''')
        .eq('plan_name', planName);

    final data = response as List<dynamic>;
    return data.map((row) {
      final map = row as Map<String, dynamic>;
      // Flatten the nested feature
      if (map['feature'] != null) {
        final featureMap = map['feature'] as Map<String, dynamic>;
        map['feature'] = featureMap;
      }
      return PlanFeatureMapping.fromMap(map);
    }).toList();
  }

  /// Get all plans with their features
  Future<List<SubscriptionPlan>> getAllPlans() async {
    final plans = ['free', 'basic', 'premium', 'enterprise'];
    final result = <SubscriptionPlan>[];

    for (final planName in plans) {
      final features = await getPlanFeatures(planName);
      result.add(
        SubscriptionPlan(
          name: planName,
          displayName: planName[0].toUpperCase() + planName.substring(1),
          features: features,
        ),
      );
    }

    return result;
  }

  /// Check if a feature is enabled for a plan
  Future<bool> isFeatureEnabled(String planName, String featureKey) async {
    try {
      final result = await _client.rpc(
        'is_feature_enabled',
        params: {'p_plan_name': planName, 'p_feature_key': featureKey},
      );
      return result as bool? ?? false;
    } catch (_) {
      // Fallback to direct query
      final response = await _client
          .from('plan_feature_mapping')
          .select('is_enabled')
          .eq('plan_name', planName)
          .eq('feature_id', await _getFeatureIdByKey(featureKey))
          .maybeSingle();

      if (response == null) return false;
      return (response['is_enabled'] as bool?) ?? false;
    }
  }

  /// Get feature limit for a plan
  Future<int?> getFeatureLimit(String planName, String featureKey) async {
    try {
      final result = await _client.rpc(
        'get_feature_limit',
        params: {'p_plan_name': planName, 'p_feature_key': featureKey},
      );
      return result is int ? result : null;
    } catch (_) {
      // Fallback to direct query
      final response = await _client
          .from('plan_feature_mapping')
          .select('limit_value')
          .eq('plan_name', planName)
          .eq('feature_id', await _getFeatureIdByKey(featureKey))
          .maybeSingle();

      if (response == null) return null;
      return response['limit_value'] as int?;
    }
  }

  /// Create a new feature
  Future<PlanFeature> createFeature({
    required String featureKey,
    required String featureName,
    String? description,
    String? category,
  }) async {
    final response = await _client
        .from('plan_features')
        .insert({
          'feature_key': featureKey,
          'feature_name': featureName,
          'description': description,
          'category': category,
        })
        .select()
        .single();

    return PlanFeature.fromMap(response);
  }

  /// Update a feature
  Future<void> updateFeature({
    required String featureId,
    String? featureName,
    String? description,
    String? category,
  }) async {
    final updates = <String, dynamic>{};
    if (featureName != null) updates['feature_name'] = featureName;
    if (description != null) updates['description'] = description;
    if (category != null) updates['category'] = category;

    await _client.from('plan_features').update(updates).eq('id', featureId);
  }

  /// Delete a feature (will cascade delete mappings)
  Future<void> deleteFeature(String featureId) async {
    await _client.from('plan_features').delete().eq('id', featureId);
  }

  /// Enable/disable a feature for a plan
  Future<void> togglePlanFeature({
    required String planName,
    required String featureId,
    required bool isEnabled,
    int? limitValue,
  }) async {
    // Check if mapping exists
    final existing = await _client
        .from('plan_feature_mapping')
        .select('id')
        .eq('plan_name', planName)
        .eq('feature_id', featureId)
        .maybeSingle();

    if (existing != null) {
      // Update existing
      await _client
          .from('plan_feature_mapping')
          .update({'is_enabled': isEnabled, 'limit_value': limitValue})
          .eq('id', existing['id']);
    } else {
      // Create new
      await _client.from('plan_feature_mapping').insert({
        'plan_name': planName,
        'feature_id': featureId,
        'is_enabled': isEnabled,
        'limit_value': limitValue,
      });
    }
  }

  /// Bulk update plan features
  Future<void> updatePlanFeatures({
    required String planName,
    required List<Map<String, dynamic>>
    features, // [{feature_id, is_enabled, limit_value}]
  }) async {
    // Delete existing mappings
    await _client
        .from('plan_feature_mapping')
        .delete()
        .eq('plan_name', planName);

    // Insert new mappings
    if (features.isNotEmpty) {
      await _client
          .from('plan_feature_mapping')
          .insert(
            features
                .map(
                  (f) => {
                    'plan_name': planName,
                    'feature_id': f['feature_id'],
                    'is_enabled': f['is_enabled'] ?? true,
                    'limit_value': f['limit_value'],
                  },
                )
                .toList(),
          );
    }
  }

  Future<String> _getFeatureIdByKey(String featureKey) async {
    final response = await _client
        .from('plan_features')
        .select('id')
        .eq('feature_key', featureKey)
        .single();
    return response['id'] as String;
  }
}
