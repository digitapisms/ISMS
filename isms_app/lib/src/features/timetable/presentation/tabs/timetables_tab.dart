import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/timetable_providers.dart';
import '../../../examination/domain/exam_type.dart';
import '../dialogs/timetable_form_dialog.dart';
import '../widgets/timetable_grid_view.dart';

/// Tab for managing timetables
class TimetablesTab extends ConsumerWidget {
  const TimetablesTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timetablesAsync = ref.watch(timetablesProvider);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Class Timetables',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              ElevatedButton.icon(
                onPressed: () async {
                  final result = await showDialog(
                    context: context,
                    builder: (_) => const TimetableFormDialog(),
                  );
                  if (result == true) {
                    ref.invalidate(timetablesProvider);
                  }
                },
                icon: const Icon(Icons.add),
                label: const Text('Create Timetable'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: timetablesAsync.when(
              data: (timetables) {
                if (timetables.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.calendar_today_outlined,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No timetables yet',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Create a timetable for a class to get started',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: Colors.grey[600]),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: timetables.length,
                  itemBuilder: (context, index) {
                    final timetable = timetables[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Theme.of(context).primaryColor,
                          child: const Icon(
                            Icons.calendar_today,
                            color: Colors.white,
                          ),
                        ),
                        title: Text(timetable.name),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Academic Year: ${timetable.academicYear}'),
                            if (timetable.term != null)
                              Text('Term: ${timetable.term!.displayName}'),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.visibility),
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        TimetableGridView(timetable: timetable),
                                  ),
                                );
                              },
                              tooltip: 'View Timetable',
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () async {
                                final result = await showDialog(
                                  context: context,
                                  builder: (_) =>
                                      TimetableFormDialog(timetable: timetable),
                                );
                                if (result == true) {
                                  ref.invalidate(timetablesProvider);
                                }
                              },
                              tooltip: 'Edit Timetable',
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
                      'Error loading timetables',
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
}
