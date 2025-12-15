import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/assignment_providers.dart';
import '../../domain/assignment.dart';
import '../../domain/assignment_submission.dart';
import '../../domain/assignment_type.dart';
import '../../../school_registration/application/school_providers.dart';

class SubmissionDialog extends ConsumerStatefulWidget {
  const SubmissionDialog({
    super.key,
    required this.assignment,
    this.submission,
    required this.studentId,
  });

  final Assignment assignment;
  final AssignmentSubmission? submission;
  final String studentId;

  @override
  ConsumerState<SubmissionDialog> createState() => _SubmissionDialogState();
}

class _SubmissionDialogState extends ConsumerState<SubmissionDialog> {
  final _formKey = GlobalKey<FormState>();
  final _submissionTextController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.submission?.submissionText != null) {
      _submissionTextController.text = widget.submission!.submissionText!;
    }
  }

  @override
  void dispose() {
    _submissionTextController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final school = ref.read(currentSchoolProvider);
      if (school == null) throw Exception('School not found');

      final repo = ref.read(assignmentRepositoryProvider);

      if (widget.submission == null || widget.submission!.id.isEmpty) {
        // Create new submission
        final submission = await repo.createSubmission(
          schoolId: school.id,
          assignmentId: widget.assignment.id,
          studentId: widget.studentId,
          submissionText: _submissionTextController.text.trim(),
        );

        // Submit it
        await repo.submitAssignment(
          submissionId: submission.id,
          submissionText: _submissionTextController.text.trim(),
        );
      } else {
        // Update existing submission
        await repo.submitAssignment(
          submissionId: widget.submission!.id,
          submissionText: _submissionTextController.text.trim(),
        );
      }

      if (mounted) {
        ref.invalidate(assignmentsProvider);
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Assignment submitted successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isOverdue = widget.assignment.isOverdue;
    final canSubmit = widget.assignment.allowLateSubmission || !isOverdue;
    final isGraded =
        widget.submission?.submissionStatus == SubmissionStatus.graded;

    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppBar(
                title: Text(widget.assignment.title),
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
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (widget.assignment.description != null) ...[
                        Text(
                          'Description',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.assignment.description!,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 16),
                      ],
                      if (widget.assignment.instructions != null) ...[
                        Text(
                          'Instructions',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.assignment.instructions!,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 16),
                      ],
                      Row(
                        children: [
                          Expanded(
                            child: _buildInfoChip(
                              context,
                              'Due Date',
                              _formatDate(widget.assignment.dueDate),
                              isOverdue ? Colors.red : Colors.blue,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildInfoChip(
                              context,
                              'Max Points',
                              widget.assignment.maxPoints.toString(),
                              Colors.green,
                            ),
                          ),
                        ],
                      ),
                      if (isOverdue) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.warning, color: Colors.red),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'This assignment is overdue. Late submissions ${widget.assignment.allowLateSubmission ? 'are' : 'are not'} allowed.',
                                  style: const TextStyle(color: Colors.red),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      Text(
                        'Your Submission',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _submissionTextController,
                        decoration: const InputDecoration(
                          labelText: 'Submission Text *',
                          border: OutlineInputBorder(),
                          hintText: 'Enter your submission here...',
                        ),
                        maxLines: 10,
                        enabled: !isGraded && canSubmit,
                        validator: (value) {
                          if ((value == null || value.trim().isEmpty) &&
                              !isGraded) {
                            return 'Submission text is required';
                          }
                          return null;
                        },
                      ),
                      if (isGraded) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.green),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.check_circle, color: Colors.green),
                              SizedBox(width: 8),
                              Text(
                                'This assignment has been graded',
                                style: TextStyle(color: Colors.green),
                              ),
                            ],
                          ),
                        ),
                      ],
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
                      onPressed: _isSubmitting
                          ? null
                          : () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    if (!isGraded && canSubmit) ...[
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: _isSubmitting ? null : _submit,
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Submit'),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(
    BuildContext context,
    String label,
    String value,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: color),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
