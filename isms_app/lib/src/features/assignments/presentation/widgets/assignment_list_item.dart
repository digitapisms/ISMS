import 'package:flutter/material.dart';

import '../../domain/assignment.dart';
import '../../domain/assignment_submission.dart';
import '../../domain/assignment_type.dart';

class AssignmentListItem extends StatelessWidget {
  const AssignmentListItem({
    super.key,
    required this.assignment,
    this.submission,
    this.onTap,
  });

  final Assignment assignment;
  final AssignmentSubmission? submission;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isOverdue =
        assignment.isOverdue &&
        submission?.submissionStatus != SubmissionStatus.submitted;
    final statusColor = _getStatusColor(submission?.submissionStatus);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: isOverdue ? Colors.red.withOpacity(0.05) : null,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      assignment.title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Chip(
                    label: Text(assignment.assignmentType.displayName),
                    backgroundColor: _getTypeColor(
                      assignment.assignmentType,
                    ).withOpacity(0.2),
                  ),
                ],
              ),
              if (assignment.description != null) ...[
                const SizedBox(height: 8),
                Text(
                  assignment.description!,
                  style: Theme.of(context).textTheme.bodyMedium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: isOverdue ? Colors.red : Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Due: ${_formatDate(assignment.dueDate)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: isOverdue ? Colors.red : Colors.grey[600],
                      fontWeight: isOverdue ? FontWeight.bold : null,
                    ),
                  ),
                  const Spacer(),
                  if (submission != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        submission!.submissionStatus.displayName,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Not Started',
                        style: TextStyle(color: Colors.grey[700], fontSize: 12),
                      ),
                    ),
                  ],
                ],
              ),
              if (isOverdue) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.warning, size: 16, color: Colors.red),
                    const SizedBox(width: 4),
                    Text(
                      'Overdue',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(SubmissionStatus? status) {
    if (status == null) return Colors.grey;
    switch (status) {
      case SubmissionStatus.notStarted:
        return Colors.grey;
      case SubmissionStatus.inProgress:
        return Colors.orange;
      case SubmissionStatus.submitted:
        return Colors.blue;
      case SubmissionStatus.late:
        return Colors.red;
      case SubmissionStatus.graded:
        return Colors.green;
    }
  }

  Color _getTypeColor(AssignmentType type) {
    switch (type) {
      case AssignmentType.homework:
        return Colors.blue;
      case AssignmentType.project:
        return Colors.purple;
      case AssignmentType.worksheet:
        return Colors.green;
      case AssignmentType.quiz:
        return Colors.orange;
      case AssignmentType.essay:
        return Colors.teal;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
