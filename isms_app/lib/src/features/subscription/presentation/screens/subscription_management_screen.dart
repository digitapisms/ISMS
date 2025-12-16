import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../school_registration/application/school_providers.dart';
import '../../../school_registration/domain/school.dart';
import '../../../payments/application/payment_providers.dart';
import '../../application/subscription_providers.dart';
import '../../domain/subscription_plan.dart';
// import '../../../payments/presentation/widgets/payment_method_selector.dart'; // TODO: File not found
import 'plan_comparison_screen.dart';

class SubscriptionManagementScreen extends ConsumerStatefulWidget {
  const SubscriptionManagementScreen({super.key});

  @override
  ConsumerState<SubscriptionManagementScreen> createState() =>
      _SubscriptionManagementScreenState();
}

class _SubscriptionManagementScreenState
    extends ConsumerState<SubscriptionManagementScreen> {
  String? _selectedPlan;
  String? _selectedPaymentMethod;
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    final school = ref.watch(currentSchoolProvider);
    final plansAsync = ref.watch(allPlansProvider);
    final paymentAccountsAsync = ref.watch(schoolPaymentAccountsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Subscription Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.compare),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PlanComparisonScreen(),
                ),
              );
            },
            tooltip: 'Compare Plans',
          ),
        ],
      ),
      body: school == null
          ? const Center(child: Text('No school selected'))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Current Subscription
                  _buildCurrentSubscriptionCard(school),
                  const SizedBox(height: 24),

                  // Available Plans
                  Text(
                    'Available Plans',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  plansAsync.when(
                    data: (plans) => Column(
                      children: plans.map((plan) {
                        final isCurrentPlan =
                            plan.name == school.subscriptionPlan;
                        final isSelected = _selectedPlan == plan.name;

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          color: isCurrentPlan
                              ? Colors.green[50]
                              : isSelected
                              ? Theme.of(context).colorScheme.primaryContainer
                              : null,
                          child: InkWell(
                            onTap: isCurrentPlan
                                ? null
                                : () =>
                                      setState(() => _selectedPlan = plan.name),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              plan.displayName,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleLarge
                                                  ?.copyWith(
                                                    fontWeight: FontWeight.bold,
                                                    color: isCurrentPlan
                                                        ? Colors.green[800]
                                                        : isSelected
                                                        ? Theme.of(context)
                                                              .colorScheme
                                                              .onPrimaryContainer
                                                        : null,
                                                  ),
                                            ),
                                            if (isCurrentPlan) ...[
                                              const SizedBox(height: 4),
                                              Text(
                                                'Current Plan',
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodySmall
                                                    ?.copyWith(
                                                      color: Colors.green[600],
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                      if (isSelected && !isCurrentPlan)
                                        Icon(
                                          Icons.check_circle,
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.primary,
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  // Show enabled features from the features map
                                  ...plan.features.entries
                                      .where((entry) => entry.value == true)
                                      .take(3)
                                      .map((entry) {
                                        final featureKey = entry.key;
                                        final featureName = featureKey
                                            .split('_')
                                            .map((word) => word.isEmpty 
                                                ? word 
                                                : word[0].toUpperCase() + word.substring(1))
                                            .join(' ');

                                        return Padding(
                                          padding: const EdgeInsets.only(
                                            bottom: 4,
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.check_circle,
                                                size: 16,
                                                color: Theme.of(
                                                  context,
                                                ).colorScheme.primary,
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  featureName,
                                                  style: Theme.of(
                                                    context,
                                                  ).textTheme.bodyMedium,
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      }),
                                  if (plan.features.values
                                          .where((v) => v == true)
                                          .length >
                                      3) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      '+ ${plan.features.values.where((v) => v == true).length - 3} more features',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(color: Colors.grey[600]),
                                    ),
                                  ],
                                  if (!isCurrentPlan) ...[
                                    const SizedBox(height: 16),
                                    ElevatedButton(
                                      onPressed: isSelected
                                          ? () => _showPaymentOptions(
                                              context,
                                              plan,
                                            )
                                          : null,
                                      child: const Text('Select Plan'),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Text('Error loading plans: $e'),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildCurrentSubscriptionCard(School school) {
    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
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
                        school.subscriptionPlan?.toUpperCase() ?? 'FREE',
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
                                color: Theme.of(context)
                                    .colorScheme
                                    .onPrimaryContainer
                                    .withOpacity(0.8),
                              ),
                        ),
                      ] else ...[
                        const SizedBox(height: 4),
                        Text(
                          'No expiration date',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onPrimaryContainer
                                    .withOpacity(0.8),
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
    );
  }

  void _showPaymentOptions(BuildContext context, SubscriptionPlan plan) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Upgrade to ${plan.displayName}',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Select payment method to complete your subscription upgrade',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              // TODO: PaymentMethodSelector widget not found
              ElevatedButton(
                onPressed: () {
                  _processSubscriptionUpgrade(plan);
                  Navigator.of(context).pop();
                },
                child: const Text('Proceed with Payment'),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _processSubscriptionUpgrade(SubscriptionPlan plan) async {
    setState(() => _isProcessing = true);

    try {
      final school = ref.read(currentSchoolProvider);
      if (school == null) throw Exception('No school selected');

      // TODO: Implement payment processing
      // Process payment through payment gateway
      // final paymentResult = await ref.read(
      //   processPaymentProvider(
      //     PaymentProcessingRequest(
      //       amount: _getPlanPrice(plan.name),
      //       currency: 'PKR',
      //       providerKey: _selectedPaymentMethod ?? 'stripe',
      //       paymentData: {
      //         'plan_name': plan.name,
      //         'school_id': school.id,
      //         'subscription_type': 'plan_upgrade',
      //       },
      //     ),
      //   ).future,
      // );

      // Simulate payment result for now
      final paymentResult = {'success': true, 'transaction_id': 'temp_${DateTime.now().millisecondsSinceEpoch}'};

      if ((paymentResult['success'] as bool?) == true) {
        // TODO: Implement updateSchoolSubscription in SubscriptionRepository
        // Update school subscription
        // await ref
        //     .read(subscriptionRepositoryProvider)
        //     .updateSchoolSubscription(
        //       schoolId: school.id,
        //       planName: plan.name,
        //       transactionId: paymentResult['transaction_id'],
        //     );

        // Refresh school data
        ref.invalidate(currentSchoolProvider);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Successfully upgraded to ${plan.displayName} plan!',
              ),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upgrade subscription: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  double _getPlanPrice(String planName) {
    final prices = {
      'free': 0.0,
      'basic': 4999.0,
      'premium': 9999.0,
      'enterprise': 19999.0,
    };
    return prices[planName] ?? 0.0;
  }
}
