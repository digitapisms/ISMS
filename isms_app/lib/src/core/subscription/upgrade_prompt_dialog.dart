import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/school_registration/application/school_providers.dart';
import '../../features/subscription/application/subscription_providers.dart';
import '../../features/subscription/presentation/screens/subscription_management_screen.dart';
import 'feature_checker.dart';

/// Dialog that shows upgrade options when a feature is restricted
class UpgradePromptDialog extends ConsumerWidget {
  const UpgradePromptDialog({
    super.key,
    required this.featureKey,
    required this.currentPlan,
  });

  final String featureKey;
  final String currentPlan;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final school = ref.watch(currentSchoolProvider);
    final plansAsync = ref.watch(allPlansProvider);

    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.workspace_premium,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Upgrade Required',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'This feature is not available in your current plan. Upgrade to access this feature and more.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              plansAsync.when(
                data: (plans) {
                  final checker = FeatureChecker(
                    ref.read(subscriptionRepositoryProvider),
                    school,
                  );
                  final upgradeOptions = checker.getUpgradeOptions();
                  final availablePlans = plans
                      .where((p) => upgradeOptions.contains(p.name))
                      .toList();

                  if (availablePlans.isEmpty) {
                    return const Text('No upgrade options available.');
                  }

                  return Column(
                    children: availablePlans.map((plan) {
                      final hasFeature = plan.features.any(
                        (f) =>
                            f.feature?.featureKey == featureKey && f.isEnabled,
                      );

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: InkWell(
                          onTap: () {
                            Navigator.of(context).pop();
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const SubscriptionManagementScreen(),
                              ),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            plan.displayName,
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleMedium
                                                ?.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                          ),
                                          if (hasFeature) ...[
                                            const SizedBox(width: 8),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 4,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: Colors.green.withOpacity(
                                                  0.2,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                'Includes this feature',
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodySmall
                                                    ?.copyWith(
                                                      color: Colors.green,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${plan.features.where((f) => f.isEnabled).length} features enabled',
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodySmall,
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.arrow_forward_ios, size: 16),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (e, _) => Text('Error loading plans: $e'),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const SubscriptionManagementScreen(),
                        ),
                      );
                    },
                    child: const Text('View Plans'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
