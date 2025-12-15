import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/transport_providers.dart';

class AssignmentsTab extends ConsumerWidget {
  const AssignmentsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assignmentsAsync = ref.watch(transportAssignmentsProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Student Transport Assignments',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Assignment management coming soon')),
                  );
                },
                icon: const Icon(Icons.add),
                label: const Text('Assign Student'),
              ),
            ],
          ),
        ),
        Expanded(
          child: assignmentsAsync.when(
            data: (assignments) {
              if (assignments.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.assignment_outlined,
                          size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'No assignments found',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: assignments.length,
                itemBuilder: (context, index) {
                  final assignment = assignments[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: const Icon(Icons.school),
                      title: Text('Assignment ID: ${assignment.id.substring(0, 8)}...'),
                      subtitle: Text(
                        'Effective from: ${assignment.effectiveFrom.day}/${assignment.effectiveFrom.month}/${assignment.effectiveFrom.year}',
                      ),
                      trailing: assignment.isActive
                          ? const Chip(
                              label: Text('Active'),
                              backgroundColor: Colors.green,
                            )
                          : const Chip(
                              label: Text('Inactive'),
                              backgroundColor: Colors.grey,
                            ),
                    ),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(
              child: Text('Error: $error'),
            ),
          ),
        ),
      ],
    );
  }
}

