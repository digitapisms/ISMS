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

                return ListView.builder(
                  itemCount: studentAssignments.length,
                  itemBuilder: (context, index) {
                    final assignment = studentAssignments[index];
                    return FutureBuilder<AssignmentSubmission?>(
                      future: _getSubmission(ref, assignment.id, authUser?.id),
                      builder: (context, snapshot) {
                        final submission = snapshot.data;
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
                                }
                              });
                            }
                          },
                        );
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

  Future<AssignmentSubmission?> _getSubmission(
    WidgetRef ref,
    String assignmentId,
    String? studentId,
  ) async {
    if (studentId == null) return null;
    try {
      final submissions = await ref.read(
        submissionsByStudentProvider(studentId).future,
      );
      return submissions.firstWhere(
        (s) => s.assignmentId == assignmentId,
        orElse: () => AssignmentSubmission(
          id: '',
          schoolId: '',
          assignmentId: assignmentId,
          studentId: studentId,
        ),
      );
    } catch (e) {
      return null;
    }
  }
}
