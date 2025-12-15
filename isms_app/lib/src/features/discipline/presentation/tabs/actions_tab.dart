import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/discipline_providers.dart';
import '../../domain/discipline_action.dart';

class ActionsTab extends ConsumerWidget {
  const ActionsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Fetch all actions (can be filtered by incident or student)
    final actionsAsync = ref.watch(disciplineActionsProvider(null));

    return actionsAsync.when(
      data: (actions) {
        if (actions.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.assignment_outlined,
                  size: 80,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 24),
                Text(
                  'No disciplinary actions',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: actions.length,
          itemBuilder: (context, index) {
            final action = actions[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: action.status == ActionStatus.active
                      ? Colors.orange[100]
                      : Colors.green[100],
                  child: Icon(
                    Icons.gavel,
                    color: action.status == ActionStatus.active
                        ? Colors.orange[800]
                        : Colors.green[800],
                  ),
                ),
                title: Text(
                  action.actionType.displayName,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(action.description),
                    const SizedBox(height: 4),
                    Text(
                      'Status: ${action.status.displayName}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                trailing: action.status == ActionStatus.active
                    ? Chip(
                        label: const Text('Active'),
                        backgroundColor: Colors.orange[100],
                      )
                    : null,
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Text('Error: $error'),
      ),
    );
  }
}

