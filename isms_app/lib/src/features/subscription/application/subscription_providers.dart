import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/subscription_repository.dart';
import '../domain/plan_feature.dart';
import '../domain/subscription_plan.dart';

final subscriptionRepositoryProvider = Provider<SubscriptionRepository>(
  (ref) => SubscriptionRepository(),
);

final allFeaturesProvider = FutureProvider<List<PlanFeature>>((ref) async {
  final repo = ref.read(subscriptionRepositoryProvider);
  return repo.getAllFeatures();
});

final planFeaturesProvider =
    FutureProvider.family<List<PlanFeatureMapping>, String>((
      ref,
      planName,
    ) async {
      final repo = ref.read(subscriptionRepositoryProvider);
      return repo.getPlanFeatures(planName);
    });

final allPlansProvider = FutureProvider<List<SubscriptionPlan>>((ref) async {
  final repo = ref.read(subscriptionRepositoryProvider);
  return repo.getAllPlans();
});

final isFeatureEnabledProvider =
    FutureProvider.family<bool, ({String planName, String featureKey})>((
      ref,
      params,
    ) async {
      final repo = ref.read(subscriptionRepositoryProvider);
      return repo.isFeatureEnabled(params.planName, params.featureKey);
    });

final featureLimitProvider =
    FutureProvider.family<int?, ({String planName, String featureKey})>((
      ref,
      params,
    ) async {
      final repo = ref.read(subscriptionRepositoryProvider);
      return repo.getFeatureLimit(params.planName, params.featureKey);
    });
