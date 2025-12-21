import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/assignment_providers.dart';
import '../../domain/assignment_submission.dart';
import '../../../authentication/application/auth_providers.dart';
import '../dialogs/submission_dialog.dart';
import '../widgets/assignment_list_item.dart';

/// Tab for students to view and submit assignments
class StudentAssignmentsTab extends ConsumerWidget {
  const StudentAssignmentsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authUser = ref.watch(authStateProvider);
    final assignmentsAsync = ref.watch(assignmentsProvider);
    final submissionsAsync = authUser == null
        ? const AsyncValue.data(<AssignmentSubmission>[])
        : ref.watch(submissionsByStudentProvider(authUser.id));

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'My Assignments',
            style: Theme.of(context).textTheme.headlineSmall,
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
                          'No assignments available',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Your teacher will publish assignments here',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: Colors.grey[600]),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                // Filter assignments for current student's class
                // In production, this would filter by student's class_id
                final studentAssignments = assignments;

                final submissions =
                    submissionsAsync.valueOrNull ??
                    const <AssignmentSubmission>[];
                final submissionByAssignmentId = <String, AssignmentSubmission>{
                  for (final s in submissions) s.assignmentId: s,
                };

                return Column(
                  children: [
                    if (submissionsAsync.isLoading)
                      const LinearProgressIndicator(minHeight: 2),
                    if (submissionsAsync.hasError)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          'Submission status unavailable. You can still open assignments.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: studentAssignments.length,
                        itemBuilder: (context, index) {
                          final assignment = studentAssignments[index];
                          final submission =
                              submissionByAssignmentId[assignment.id];
                          return AssignmentListItem(
                            assignment: assignment,
                            submission: submission,
                            onTap: () {
                              if (authUser != null) {
                                showDialog(
                                  context: context,
                                  builder: (_) => SubmissionDialog(
                                    assignment: assignment,
                                    submission: submission,
                                    studentId: authUser.id,
                                  ),
                                ).then((result) {
                                  if (result == true) {
                                    ref.invalidate(assignmentsProvider);
                                    ref.invalidate(
                                      submissionsByStudentProvider(authUser.id),
                                    );
                                  }
                                });
                              }
                            },
                          );
                        },
                      ),
                    ),
                  ],
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
}
