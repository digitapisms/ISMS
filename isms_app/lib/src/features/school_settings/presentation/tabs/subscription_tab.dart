import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../school_registration/domain/school.dart';
import '../../../subscription/application/subscription_providers.dart';
import '../../../support/presentation/screens/support_contact_form.dart';

class SubscriptionTab extends ConsumerWidget {
  const SubscriptionTab({super.key, required this.school});

  final School school;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plansAsync = ref.watch(allPlansProvider);
    final currentPlan = school.subscriptionPlan ?? 'free';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Subscription & Plan',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'View your current subscription plan and available features.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 32),
          // Current Plan Card
          Card(
            color: Theme.of(context).colorScheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.workspace_premium,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                        size: 32,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              currentPlan.toUpperCase(),
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onPrimaryContainer,
                                  ),
                            ),
                            if (school.subscriptionExpiresAt != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Expires: ${DateFormat('MMM dd, yyyy').format(school.subscriptionExpiresAt!)}',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onPrimaryContainer,
                                    ),
                              ),
                            ] else ...[
                              const SizedBox(height: 4),
                              Text(
                                'No expiration date',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onPrimaryContainer,
                                    ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Plan Features
          plansAsync.when(
            data: (plans) {
              final plan = plans.firstWhere(
                (p) => p.name == currentPlan,
                orElse: () => plans.first,
              );

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Plan Features',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...plan.features.entries
                      .where((entry) => entry.value == true)
                      .map((entry) {
                        final featureKey = entry.key;
                        final featureName = featureKey
                            .split('_')
                            .map((word) => word.isEmpty 
                                ? word 
                                : word[0].toUpperCase() + word.substring(1))
                            .join(' ');

                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: Icon(
                          Icons.check_circle,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        title: Text(featureName),
                        subtitle: null, // TODO: Add description if available
                        trailing: plan.getFeatureLimit(featureKey) != null
                            ? Chip(
                                label: Text('Limit: ${plan.getFeatureLimit(featureKey)}'),
                                visualDensity: VisualDensity.compact,
                              )
                            : const Chip(
                                label: Text('Unlimited'),
                                visualDensity: VisualDensity.compact,
                              ),
                      ),
                    );
                  }),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Theme.of(
                          context,
                        ).colorScheme.outline.withOpacity(0.3),
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Need to upgrade?',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Contact your administrator or support to upgrade your subscription plan.',
                          style: Theme.of(context).textTheme.bodySmall,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        FilledButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const SupportContactForm(
                                  initialSubject:
                                      'Subscription Upgrade Request',
                                  initialDescription:
                                      'I would like to upgrade my subscription plan. Please provide more information about the available options and pricing.',
                                ),
                              ),
                            );
                          },
                          child: const Text('Contact Support'),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Error loading plans: $e'),
          ),
        ],
      ),
    );
  }
}
