import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/school_registration/application/school_providers.dart';
import 'feature_checker.dart';
import 'upgrade_prompt_dialog.dart';

/// Widget that guards a feature based on subscription plan
class FeatureGuard extends ConsumerWidget {
  const FeatureGuard({
    super.key,
    required this.featureKey,
    required this.child,
    this.fallback,
    this.showUpgradePrompt = true,
    this.currentUsage,
  });

  final String featureKey;
  final Widget child;
  final Widget? fallback;
  final bool showUpgradePrompt;
  final int? currentUsage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final school = ref.watch(currentSchoolProvider);
    final planName = school?.subscriptionPlan ?? 'free';

    // IMPORTANT: do NOT create new providers inside build().
    // Use a stable family provider so this doesn't reset to loading forever.
    final featureCheckAsync = ref.watch(
      featureCheckWithUsageProvider((
        featureKey: featureKey,
        currentUsage: currentUsage,
      )),
    );

    return featureCheckAsync.when(
      data: (result) {
        if (result.canUse) {
          return child;
        }

        // Feature is disabled or limit reached
        if (fallback != null) {
          return fallback!;
        }

        return _FeatureRestrictedWidget(
          featureKey: featureKey,
          result: result,
          planName: planName,
          showUpgradePrompt: showUpgradePrompt,
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => child, // Fail open on error
    );
  }
}

/// Widget that shows when a feature is restricted
class _FeatureRestrictedWidget extends ConsumerWidget {
  const _FeatureRestrictedWidget({
    required this.featureKey,
    required this.result,
    required this.planName,
    required this.showUpgradePrompt,
  });

  final String featureKey;
  final FeatureCheckResult result;
  final String planName;
  final bool showUpgradePrompt;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.lock_outline,
            size: 48,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(
            'Feature Not Available',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            result.statusMessage,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          if (showUpgradePrompt) ...[
            const SizedBox(height: 24),
            FilledButton.icon(
              icon: const Icon(Icons.upgrade),
              label: const Text('View Upgrade Options'),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => UpgradePromptDialog(
                    featureKey: featureKey,
                    currentPlan: planName,
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}

/// Button that checks feature before executing action
class FeatureProtectedButton extends ConsumerWidget {
  const FeatureProtectedButton({
    super.key,
    required this.featureKey,
    required this.child,
    this.currentUsage,
    this.tooltip,
  });

  final String featureKey;
  final Widget child;
  final int? currentUsage;
  final String? tooltip;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final school = ref.watch(currentSchoolProvider);

    final featureCheckAsync = ref.watch(
      featureCheckWithUsageProvider((
        featureKey: featureKey,
        currentUsage: currentUsage,
      )),
    );

    return featureCheckAsync.when(
      data: (result) {
        if (result.canUse) {
          return Tooltip(message: tooltip ?? '', child: child);
        }

        // Disabled button with upgrade prompt
        return Tooltip(
          message: result.statusMessage,
          child: Builder(
            builder: (context) {
              if (child is ElevatedButton || child is FilledButton) {
                return _DisabledButtonWithUpgrade(
                  originalButton: child,
                  result: result,
                  featureKey: featureKey,
                  currentPlan: school?.subscriptionPlan ?? 'free',
                );
              }
              return Opacity(opacity: 0.5, child: child);
            },
          ),
        );
      },
      loading: () => Opacity(opacity: 0.5, child: child),
      error: (_, __) => child, // Fail open
    );
  }
}

class _DisabledButtonWithUpgrade extends StatelessWidget {
  const _DisabledButtonWithUpgrade({
    required this.originalButton,
    required this.result,
    required this.featureKey,
    required this.currentPlan,
  });

  final Widget originalButton;
  final FeatureCheckResult result;
  final String featureKey;
  final String currentPlan;

  @override
  Widget build(BuildContext context) {
    if (originalButton is ElevatedButton) {
      final btn = originalButton as ElevatedButton;
      return ElevatedButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => UpgradePromptDialog(
              featureKey: featureKey,
              currentPlan: currentPlan,
            ),
          );
        },
        style: btn.style,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock, size: 16),
            const SizedBox(width: 8),
            if (btn.child is Text)
              (btn.child as Text)
            else
              btn.child ?? const Text('Upgrade Required'),
          ],
        ),
      );
    }

    if (originalButton is FilledButton) {
      final btn = originalButton as FilledButton;
      return FilledButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => UpgradePromptDialog(
              featureKey: featureKey,
              currentPlan: currentPlan,
            ),
          );
        },
        style: btn.style,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock, size: 16),
            const SizedBox(width: 8),
            if (btn.child is Text)
              (btn.child as Text)
            else
              btn.child ?? const Text('Upgrade Required'),
          ],
        ),
      );
    }

    return originalButton;
  }
}
