import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/school_registration/application/school_providers.dart';
import '../../features/subscription/application/subscription_providers.dart';
import 'feature_checker.dart';

/// Helper function to create a NavigationRailDestination with an optional feature badge
/// Shows a badge if the feature requires a premium plan
NavigationRailDestination createFeatureBadgedNavigationDestination({
  required Widget icon,
  required Widget selectedIcon,
  required Widget label,
  String? featureKey,
  bool showBadgeIfPremium = true,
  required WidgetRef ref,
}) {
  if (featureKey == null || !showBadgeIfPremium) {
    // No feature key or badges disabled - return normal destination
    return NavigationRailDestination(
      icon: icon,
      selectedIcon: selectedIcon,
      label: label,
    );
  }

  final school = ref.watch(currentSchoolProvider);
  final subscriptionRepo = ref.read(subscriptionRepositoryProvider);
  final checker = FeatureChecker(subscriptionRepo, school);
  
  // Store in local variable for use in closure
  final featureKeyValue = featureKey; // featureKey is guaranteed non-null here
  
  final featureCheckAsync = ref.watch(
    FutureProvider((ref) async {
      return checker.checkFeature(featureKeyValue);
    }),
  );

  return featureCheckAsync.when(
    data: (result) {
      // Show badge only if feature is not available in current plan
      final showBadge = !result.isEnabled;

      return NavigationRailDestination(
        icon: showBadge ? _BadgedIcon(icon: icon) : icon,
        selectedIcon: showBadge ? _BadgedIcon(icon: selectedIcon) : selectedIcon,
        label: label,
      );
    },
    loading: () => NavigationRailDestination(
      icon: icon,
      selectedIcon: selectedIcon,
      label: label,
    ),
    error: (_, __) => NavigationRailDestination(
      icon: icon,
      selectedIcon: selectedIcon,
      label: label,
    ),
  );
}

/// Widget that adds a premium badge to an icon
class _BadgedIcon extends StatelessWidget {
  const _BadgedIcon({required this.icon});

  final Widget icon;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        icon,
        Positioned(
          top: -6,
          right: -6,
          child: Container(
            padding: const EdgeInsets.all(2.5),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              shape: BoxShape.circle,
              border: Border.all(
                color: Theme.of(context).colorScheme.surface,
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            constraints: const BoxConstraints(
              minWidth: 14,
              minHeight: 14,
            ),
            child: Icon(
              Icons.star,
              size: 9,
              color: Theme.of(context).colorScheme.onPrimary,
            ),
          ),
        ),
      ],
    );
  }
}

