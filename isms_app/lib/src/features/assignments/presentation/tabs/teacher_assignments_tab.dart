import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/assignment_providers.dart';
import '../../domain/assignment.dart';
import '../../domain/assignment_type.dart';
import '../../../authentication/application/auth_providers.dart';
import '../dialogs/assignment_form_dialog.dart';
import '../widgets/assignment_list_item.dart';

/// Tab for teachers to manage assignments
class TeacherAssignmentsTab extends ConsumerWidget {
  const TeacherAssignmentsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authUser = ref.watch(authStateProvider);
    final assignmentsAsync = authUser != null
        ? ref.watch(assignmentsByTeacherProvider(authUser.id))
        : ref.watch(assignmentsProvider);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'My Assignments',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              ElevatedButton.icon(
                onPressed: () async {
                  final result = await showDialog(
                    context: context,
                    builder: (_) => const AssignmentFormDialog(),
                  );
                  if (result == true) {
                    if (authUser != null) {
                      ref.invalidate(assignmentsByTeacherProvider(authUser.id));
                    } else {
                      ref.invalidate(assignmentsProvider);
                    }
                  }
                },
                icon: const Icon(Icons.add),
                label: const Text('Create Assignment'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: assignmentsAsync.when(
              data: (assignments) {
                if (assignments.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.assignment_outlined,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No assignments yet',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Create an assignment to get started',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: Colors.grey[600]),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: assignments.length,
                  itemBuilder: (context, index) {
                    final assignment = assignments[index];
                    return AssignmentListItem(
                      assignment: assignment,
                      onTap: () {
                        // Navigate to assignment details
                        _showAssignmentDetails(context, ref, assignment);
                      },
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
                      'Error loading assignments',
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

  void _showAssignmentDetails(
    BuildContext context,
    WidgetRef ref,
    Assignment assignment,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        assignment.title,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (assignment.description != null) ...[
                  Text(
                    assignment.description!,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 16),
                ],
                _buildInfoRow(
                  context,
                  'Type',
                  assignment.assignmentType.displayName,
                ),
                _buildInfoRow(
                  context,
                  'Due Date',
                  _formatDate(assignment.dueDate),
                ),
                _buildInfoRow(
                  context,
                  'Max Points',
                  assignment.maxPoints.toString(),
                ),
                if (assignment.instructions != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Instructions',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    assignment.instructions!,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    // Navigate to submissions view
                  },
                  child: const Text('View Submissions'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
