import 'package:flutter/material.dart';

import '../../domain/book_issue.dart';
import '../../domain/book_type.dart';

class IssueListItem extends StatelessWidget {
  const IssueListItem({
    super.key,
    required this.issue,
    this.onReturn,
  });

  final BookIssue issue;
  final VoidCallback? onReturn;

  @override
  Widget build(BuildContext context) {
    final isOverdue = issue.isOverdue;
    final daysOverdue = issue.daysOverdue;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: isOverdue ? Colors.red.withOpacity(0.05) : null,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Issue ID: ${issue.id.substring(0, 8)}...',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Issued: ${_formatDate(issue.issueDate)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      Text(
                        'Due: ${_formatDate(issue.dueDate)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: isOverdue ? Colors.red : Colors.grey[600],
                              fontWeight: isOverdue ? FontWeight.bold : null,
                            ),
                      ),
                    ],
                  ),
                ),
                Chip(
                  label: Text(issue.status.displayName),
                  backgroundColor: _getStatusColor(issue.status).withOpacity(0.2),
                  labelStyle: TextStyle(
                    color: _getStatusColor(issue.status),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            if (isOverdue) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.warning, size: 16, color: Colors.red),
                  const SizedBox(width: 4),
                  Text(
                    'Overdue by $daysOverdue day${daysOverdue != 1 ? 's' : ''}',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
            if (onReturn != null) ...[
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton.icon(
                  onPressed: onReturn,
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Return Book'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(IssueStatus status) {
    switch (status) {
      case IssueStatus.issued:
        return Colors.blue;
      case IssueStatus.returned:
        return Colors.green;
      case IssueStatus.overdue:
        return Colors.red;
      case IssueStatus.lost:
        return Colors.orange;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

