import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/library_providers.dart';
import '../../domain/book_issue.dart';
import '../../domain/book_type.dart';

class ReturnBookDialog extends ConsumerStatefulWidget {
  const ReturnBookDialog({super.key, required this.issue});

  final BookIssue issue;

  @override
  ConsumerState<ReturnBookDialog> createState() => _ReturnBookDialogState();
}

class _ReturnBookDialogState extends ConsumerState<ReturnBookDialog> {
  BookCondition _conditionOnReturn = BookCondition.good;
  final _damageNotesController = TextEditingController();
  final _notesController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _damageNotesController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final daysOverdue = widget.issue.isOverdue ? widget.issue.daysOverdue : 0;
    final estimatedFine = daysOverdue * 5.0; // Default 5 per day

    return Dialog(
      child: Container(
        width: 500,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              title: const Text('Return Book'),
              automaticallyImplyLeading: false,
              actions: [
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Card(
                      color: widget.issue.isOverdue
                          ? Colors.red.withOpacity(0.1)
                          : Colors.green.withOpacity(0.1),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Issue Details',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Text('Issued: ${_formatDate(widget.issue.issueDate)}'),
                            Text('Due: ${_formatDate(widget.issue.dueDate)}'),
                            if (widget.issue.isOverdue) ...[
                              const SizedBox(height: 8),
                              Text(
                                'Overdue by $daysOverdue day${daysOverdue != 1 ? 's' : ''}',
                                style: const TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Estimated Fine: ${estimatedFine.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<BookCondition>(
                      value: _conditionOnReturn,
                      decoration: const InputDecoration(
                        labelText: 'Condition on Return',
                        border: OutlineInputBorder(),
                      ),
                      items: BookCondition.values.map((condition) {
                        return DropdownMenuItem<BookCondition>(
                          value: condition,
                          child: Text(condition.displayName),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _conditionOnReturn = value);
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _damageNotesController,
                      decoration: const InputDecoration(
                        labelText: 'Damage Notes (if any)',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _notesController,
                      decoration: const InputDecoration(
                        labelText: 'Additional Notes',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isLoading
                        ? null
                        : () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _returnBook,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Return Book'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _returnBook() async {
    setState(() => _isLoading = true);

    try {
      final repo = ref.read(libraryRepositoryProvider);
      await repo.returnBook(
        issueId: widget.issue.id,
        conditionOnReturn: _conditionOnReturn,
        damageNotes: _damageNotesController.text.trim().isEmpty
            ? null
            : _damageNotesController.text.trim(),
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Book returned successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

