import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../subscription/application/subscription_providers.dart';
import '../../subscription/domain/plan_feature.dart';
import '../../subscription/domain/subscription_plan.dart';

extension ListExtension<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

class PlanEditorView extends ConsumerStatefulWidget {
  const PlanEditorView({
    super.key,
    required this.plans,
    required this.allFeatures,
  });

  final List<SubscriptionPlan> plans;
  final List<PlanFeature> allFeatures;

  @override
  ConsumerState<PlanEditorView> createState() => _PlanEditorViewState();
}

class _PlanEditorViewState extends ConsumerState<PlanEditorView> {
  String? _selectedPlan;
  final Map<String, Map<String, bool>> _featureStates = {};
  final Map<String, Map<String, int?>> _featureLimits = {};
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _selectedPlan = widget.plans.firstOrNull?.name;
    _initializeFeatureStates();
  }

  void _initializeFeatureStates() {
    for (final plan in widget.plans) {
      _featureStates[plan.name] = {};
      _featureLimits[plan.name] = {};
      // Initialize from plan's features map
      for (final feature in widget.allFeatures) {
        _featureStates[plan.name]![feature.id] = plan.hasFeature(feature.featureKey);
        _featureLimits[plan.name]![feature.id] = plan.getFeatureLimit(feature.featureKey);
      }
    }
  }

  Future<void> _savePlanFeatures(String planName) async {
    setState(() {
      _isSaving = true;
    });

    try {
      final repo = ref.read(subscriptionRepositoryProvider);
      final features = widget.allFeatures.map((feature) {
        final isEnabled = _featureStates[planName]?[feature.id] ?? false;
        final limit = _featureLimits[planName]?[feature.id];
        return {
          'feature_id': feature.id,
          'is_enabled': isEnabled,
          'limit_value': limit,
        };
      }).toList();

      // TODO: Implement updatePlanFeatures in SubscriptionRepository
      // await repo.updatePlanFeatures(planName: planName, features: features);
      throw UnimplementedError('updatePlanFeatures not yet implemented');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$planName plan updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }

      // Refresh plans
      ref.invalidate(allPlansProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _toggleFeature(String planName, String featureId, bool value) {
    setState(() {
      _featureStates[planName] ??= {};
      _featureStates[planName]![featureId] = value;
    });
  }

  void _setFeatureLimit(String planName, String featureId, int? limit) {
    setState(() {
      _featureLimits[planName] ??= {};
      _featureLimits[planName]![featureId] = limit;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_selectedPlan == null) {
      return const Center(child: Text('No plans available'));
    }

    final selectedPlanData = widget.plans.firstWhere(
      (p) => p.name == _selectedPlan,
      orElse: () => widget.plans.first,
    );

    // Group features by category
    final featuresByCategory = <String, List<PlanFeature>>{};
    for (final feature in widget.allFeatures) {
      final category = feature.category ?? 'other';
      featuresByCategory.putIfAbsent(category, () => []).add(feature);
    }

    return Row(
      children: [
        // Plan selector sidebar
        Container(
          width: 200,
          decoration: BoxDecoration(
            border: Border(
              right: BorderSide(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
          ),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: widget.plans.map((plan) {
              final isSelected = plan.name == _selectedPlan;
              return Card(
                color: isSelected
                    ? Theme.of(context).colorScheme.primaryContainer
                    : null,
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _selectedPlan = plan.name;
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          plan.displayName.toUpperCase(),
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: isSelected
                                    ? Theme.of(
                                        context,
                                      ).colorScheme.onPrimaryContainer
                                    : null,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${plan.features.values.where((v) => v == true).length} features enabled',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: isSelected
                                    ? Theme.of(
                                        context,
                                      ).colorScheme.onPrimaryContainer
                                    : null,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        // Feature editor
        Expanded(
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: Theme.of(context).colorScheme.outlineVariant,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${selectedPlanData.displayName} Plan Features',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Enable or disable features and set limits for the ${selectedPlanData.displayName} plan',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    FilledButton.icon(
                      icon: _isSaving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.save),
                      label: const Text('Save Changes'),
                      onPressed: _isSaving
                          ? null
                          : () => _savePlanFeatures(_selectedPlan!),
                    ),
                  ],
                ),
              ),
              // Features list
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: featuresByCategory.entries.map((entry) {
                      final category = entry.key;
                      final features = entry.value;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            category.toUpperCase().replaceAll('_', ' '),
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),
                          ...features.map((feature) {
                            // Check if feature is enabled in the plan's features map
                            final isEnabled =
                                _featureStates[_selectedPlan]?[feature.id] ??
                                selectedPlanData.hasFeature(feature.featureKey);
                            final limit =
                                _featureLimits[_selectedPlan]?[feature.id] ??
                                selectedPlanData.getFeatureLimit(feature.featureKey);

                            return _FeatureRow(
                              feature: feature,
                              isEnabled: isEnabled,
                              limit: limit,
                              onToggle: (value) => _toggleFeature(
                                _selectedPlan!,
                                feature.id,
                                value,
                              ),
                              onLimitChanged: (value) => _setFeatureLimit(
                                _selectedPlan!,
                                feature.id,
                                value,
                              ),
                            );
                          }),
                          const SizedBox(height: 24),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FeatureRow extends StatefulWidget {
  const _FeatureRow({
    required this.feature,
    required this.isEnabled,
    this.limit,
    required this.onToggle,
    required this.onLimitChanged,
  });

  final PlanFeature feature;
  final bool isEnabled;
  final int? limit;
  final ValueChanged<bool> onToggle;
  final ValueChanged<int?> onLimitChanged;

  @override
  State<_FeatureRow> createState() => _FeatureRowState();
}

class _FeatureRowState extends State<_FeatureRow> {
  late TextEditingController _limitController;
  String? _limitError;

  @override
  void initState() {
    super.initState();
    _limitController = TextEditingController(
      text: widget.limit?.toString() ?? '',
    );
    _limitController.addListener(_validateLimit);
  }

  @override
  void didUpdateWidget(_FeatureRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update controller if limit changed externally
    if (oldWidget.limit != widget.limit) {
      _limitController.text = widget.limit?.toString() ?? '';
    }
  }

  void _validateLimit() {
    final value = _limitController.text.trim();
    if (value.isEmpty) {
      setState(() => _limitError = null);
      widget.onLimitChanged(null);
      return;
    }

    final intValue = int.tryParse(value);
    if (intValue == null) {
      setState(() => _limitError = 'Invalid number');
      widget.onLimitChanged(null);
    } else if (intValue < 1) {
      setState(() => _limitError = 'Must be at least 1');
      widget.onLimitChanged(null);
    } else {
      setState(() => _limitError = null);
      widget.onLimitChanged(intValue);
    }
  }

  @override
  void dispose() {
    _limitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Switch(value: widget.isEnabled, onChanged: widget.onToggle),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.feature.featureName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (widget.feature.description != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      widget.feature.description!,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ],
              ),
            ),
            if (widget.isEnabled) ...[
              const SizedBox(width: 16),
              SizedBox(
                width: 120,
                child: TextField(
                  controller: _limitController,
                  decoration: InputDecoration(
                    labelText: 'Limit',
                    hintText: 'Unlimited',
                    border: const OutlineInputBorder(),
                    isDense: true,
                    errorText: _limitError,
                    errorMaxLines: 2,
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
