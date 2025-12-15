import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../school_registration/application/school_providers.dart';
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
              data: (plans) => _buildComparisonTable(plans, school.subscriptionPlan),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error loading plans: $e')),
            ),
    );
  }

  Widget _buildComparisonTable(List<SubscriptionPlan> plans, String? currentPlan) {
    // Get all unique features across all plans
    final allFeatures = _getAllUniqueFeatures(plans);
    
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: DataTable(
          columns: _buildTableColumns(plans),
          rows: _buildTableRows(plans, allFeatures, currentPlan),
          headingRowHeight: 80,
          dataRowHeight: 60,
          horizontalMargin: 16,
          columnSpacing: 24,
        ),
      ),
    );
  }

  List<DataColumn> _buildTableColumns(List<SubscriptionPlan> plans) {
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
              if (plan.price != null && plan.price! > 0)
                Text(
                  'Rs. ${plan.price!.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              if (plan.price == null || plan.price == 0)
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
            final hasFeature = plan.features.any((mapping) => 
              mapping.feature?.featureName == feature && mapping.isEnabled);
            
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
                  plan.price == null || plan.price == 0
                      ? 'Free'
                      : 'Rs. ${plan.price!.toStringAsFixed(0)}',
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
      for (final mapping in plan.features) {
        if (mapping.feature != null) {
          allFeatures.add(mapping.feature!.featureName);
        }
      }
    }
    
    return allFeatures.toList()..sort();
  }
}