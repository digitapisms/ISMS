import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/timetable_providers.dart';
import '../../domain/period.dart';
import '../dialogs/period_form_dialog.dart';

/// Tab for managing periods
class PeriodsTab extends ConsumerWidget {
  const PeriodsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final periodsAsync = ref.watch(periodsProvider);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Periods', style: Theme.of(context).textTheme.headlineSmall),
              ElevatedButton.icon(
                onPressed: () async {
                  final result = await showDialog(
                    context: context,
                    builder: (_) => const PeriodFormDialog(),
                  );
                  if (result == true) {
                    ref.invalidate(periodsProvider);
                  }
                },
                icon: const Icon(Icons.add),
                label: const Text('Add Period'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: periodsAsync.when(
              data: (periods) {
                if (periods.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.access_time_outlined,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No periods defined',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Add periods to define time slots for your timetable',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: Colors.grey[600]),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: periods.length,
                  itemBuilder: (context, index) {
                    final period = periods[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: _getPeriodColor(period.periodType),
                          child: Text(
                            '${index + 1}',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        title: Text(period.name),
                        subtitle: Text(period.timeRange),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (period.durationMinutes != null)
                              Chip(
                                label: Text('${period.durationMinutes} min'),
                                backgroundColor: Colors.blue.withOpacity(0.1),
                              ),
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () async {
                                final result = await showDialog(
                                  context: context,
                                  builder: (_) =>
                                      PeriodFormDialog(period: period),
                                );
                                if (result == true) {
                                  ref.invalidate(periodsProvider);
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Error loading periods',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      error.toString(),
                      style: Theme.of(context).textTheme.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getPeriodColor(PeriodType type) {
    switch (type) {
      case PeriodType.regular:
        return Colors.blue;
      case PeriodType.breakPeriod:
        return Colors.orange;
      case PeriodType.lunch:
        return Colors.green;
      case PeriodType.assembly:
        return Colors.purple;
    }
  }
}
