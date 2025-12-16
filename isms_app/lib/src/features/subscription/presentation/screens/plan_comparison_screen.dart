import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../school_registration/application/school_providers.dart';
import '../../application/subscription_providers.dart';
import '../../domain/subscription_plan.dart';

class PlanComparisonScreen extends ConsumerWidget {
  const PlanComparisonScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final school = ref.watch(currentSchoolProvider);
    final plansAsync = ref.watch(allPlansProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Compare Subscription Plans'),
      ),
      body: school == null
          ? const Center(child: Text('No school selected'))
          : plansAsync.when(
              data: (plans) => _buildComparisonTable(context, plans, school.subscriptionPlan),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error loading plans: $e')),
            ),
    );
  }

  Widget _buildComparisonTable(BuildContext context, List<SubscriptionPlan> plans, String? currentPlan) {
    // Get all unique features across all plans
    final allFeatures = _getAllUniqueFeatures(plans);
    
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: DataTable(
          columns: _buildTableColumns(context, plans),
          rows: _buildTableRows(context, plans, allFeatures, currentPlan),
          headingRowHeight: 80,
          dataRowHeight: 60,
          horizontalMargin: 16,
          columnSpacing: 24,
        ),
      ),
    );
  }

  List<DataColumn> _buildTableColumns(BuildContext context, List<SubscriptionPlan> plans) {
    return [
      const DataColumn(
        label: Text(
          'Features',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
      ...plans.map((plan) {
        return DataColumn(
          label: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                plan.displayName,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              if (plan.pricePerMonth > 0)
                Text(
                  'Rs. ${plan.pricePerMonth.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              if (plan.pricePerMonth == 0)
                const Text(
                  'Free',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.green,
                  ),
                ),
            ],
          ),
        );
      }),
    ];
  }

  List<DataRow> _buildTableRows(
    BuildContext context,
    List<SubscriptionPlan> plans,
    List<String> allFeatures,
    String? currentPlan,
  ) {
    return allFeatures.map((feature) {
      return DataRow(
        cells: [
          DataCell(
            Text(
              feature,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          ...plans.map((plan) {
            // Check if feature is enabled in the plan's features map
            final hasFeature = plan.hasFeature(feature.toLowerCase().replaceAll(' ', '_'));
            
            return DataCell(
              Center(
                child: hasFeature
                    ? const Icon(Icons.check_circle, color: Colors.green, size: 24)
                    : const Icon(Icons.close, color: Colors.red, size: 24),
              ),
            );
          }),
        ],
      );
    }).toList()..addAll([
      // Add pricing row
      DataRow(
        cells: [
          const DataCell(
            Text(
              'Monthly Price',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          ...plans.map((plan) {
            return DataCell(
              Center(
                child: Text(
                  plan.pricePerMonth == 0
                      ? 'Free'
                      : 'Rs. ${plan.pricePerMonth.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            );
          }),
        ],
      ),
      // Add current plan indicator row
      DataRow(
        cells: [
          const DataCell(
            Text(
              'Your Plan',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          ...plans.map((plan) {
            final isCurrent = plan.name == currentPlan;
            return DataCell(
              Center(
                child: isCurrent
                    ? Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Current',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            );
          }),
        ],
      ),
    ]);
  }

  List<String> _getAllUniqueFeatures(List<SubscriptionPlan> plans) {
    final allFeatures = <String>{};
    
    for (final plan in plans) {
      // Extract feature keys from the features map
      for (final featureKey in plan.features.keys) {
        allFeatures.add(featureKey.replaceAll('_', ' ').split(' ').map((word) => 
          word.isEmpty ? word : word[0].toUpperCase() + word.substring(1)
        ).join(' '));
      }
    }
    
    return allFeatures.toList()..sort();
  }
}