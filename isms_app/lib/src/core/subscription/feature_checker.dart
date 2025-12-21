import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/school_registration/application/school_providers.dart';
import '../../features/school_registration/domain/school.dart';
import '../../features/subscription/application/subscription_providers.dart';
import '../../features/subscription/data/subscription_repository.dart';

/// Result of a feature check
class FeatureCheckResult {
  const FeatureCheckResult({
    required this.isEnabled,
    this.limit,
    this.currentUsage,
    this.message,
  });

  final bool isEnabled;
  final int? limit;
  final int? currentUsage;
  final String? message;

  bool get isWithinLimit {
    if (!isEnabled) return false;
    if (limit == null) return true; // Unlimited
    if (currentUsage == null) return true; // Usage not tracked
    return currentUsage! < limit!;
  }

  bool get canUse => isEnabled && isWithinLimit;

  String get statusMessage {
    if (!isEnabled) {
      return message ?? 'This feature is not available in your current plan.';
    }
    if (!isWithinLimit && limit != null && currentUsage != null) {
      return message ??
          'You have reached the limit of $limit. Current usage: $currentUsage';
    }
    if (limit != null) {
      return 'Limit: $limit${currentUsage != null ? ' (Used: $currentUsage)' : ''}';
    }
    return 'Available';
  }
}

/// Service for checking feature availability and limits
class FeatureChecker {
  final SubscriptionRepository _subscriptionRepository;
  final School? _school;

  FeatureChecker(this._subscriptionRepository, this._school);

  /// Get the current school's subscription plan
  String get _planName {
    return _school?.subscriptionPlan ?? 'free';
  }

  /// Check if a feature is enabled for the current plan
  Future<FeatureCheckResult> checkFeature(
    String featureKey, {
    int? currentUsage,
  }) async {
    try {
      final isEnabled = await _subscriptionRepository.isFeatureEnabled(
        _planName,
        featureKey,
      );

      if (!isEnabled) {
        return FeatureCheckResult(
          isEnabled: false,
          message: _getUpgradeMessage(featureKey),
        );
      }

      final limit = await _subscriptionRepository.getFeatureLimit(
        _planName,
        featureKey,
      );

      return FeatureCheckResult(
        isEnabled: true,
        limit: limit,
        currentUsage: currentUsage,
        message: limit != null && currentUsage != null && currentUsage >= limit
            ? 'You have reached the limit of $limit for this feature.'
            : null,
      );
    } catch (e) {
      // On error, allow access (fail open) but log the error
      print('Feature check error for $featureKey: $e');
      return const FeatureCheckResult(
        isEnabled: true,
        message: 'Unable to verify feature availability.',
      );
    }
  }

  /// Check multiple features at once
  Future<Map<String, FeatureCheckResult>> checkFeatures(
    List<String> featureKeys,
  ) async {
    final results = <String, FeatureCheckResult>{};
    for (final key in featureKeys) {
      results[key] = await checkFeature(key);
    }
    return results;
  }

  String _getUpgradeMessage(String featureKey) {
    final planName = _planName;
    if (planName == 'free') {
      return 'This feature is available in Basic, Premium, or Enterprise plans.';
    } else if (planName == 'basic') {
      return 'This feature is available in Premium or Enterprise plans.';
    } else if (planName == 'premium') {
      return 'This feature is available in Enterprise plan.';
    }
    return 'This feature is not available in your current plan.';
  }

  /// Get upgrade plan suggestions based on current plan
  List<String> getUpgradeOptions() {
    final planName = _planName;
    switch (planName) {
      case 'free':
        return ['basic', 'premium', 'enterprise'];
      case 'basic':
        return ['premium', 'enterprise'];
      case 'premium':
        return ['enterprise'];
      default:
        return [];
    }
  }
}

/// Provider for FeatureChecker
final featureCheckerProvider = Provider<FeatureChecker>((ref) {
  final subscriptionRepo = ref.read(subscriptionRepositoryProvider);
  final school = ref.watch(currentSchoolProvider);
  return FeatureChecker(subscriptionRepo, school);
});

typedef FeatureCheckArgs = ({String featureKey, int? currentUsage});

/// Provider for checking a specific feature
final featureCheckProvider = FutureProvider.family<FeatureCheckResult, String>((
  ref,
  featureKey,
) async {
  final checker = ref.read(featureCheckerProvider);
  return checker.checkFeature(featureKey);
});

/// Provider for checking a feature with usage (stable key for FeatureGuard)
final featureCheckWithUsageProvider =
    FutureProvider.family<FeatureCheckResult, FeatureCheckArgs>((
      ref,
      args,
    ) async {
      final checker = ref.read(featureCheckerProvider);
      return checker.checkFeature(
        args.featureKey,
        currentUsage: args.currentUsage,
      );
    });
