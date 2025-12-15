import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../application/examination_providers.dart';
import '../../domain/exam_type.dart';
import '../dialogs/exam_form_dialog.dart';

/// Tab for managing exams
class ExamsTab extends ConsumerWidget {
  const ExamsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final examsAsync = ref.watch(examsProvider);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Examinations',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              ElevatedButton.icon(
                onPressed: () async {
                  final result = await showDialog(
                    context: context,
                    builder: (_) => const ExamFormDialog(),
                  );
                  if (result == true) {
                    ref.invalidate(examsProvider);
                  }
                },
                icon: const Icon(Icons.add),
                label: const Text('Create Exam'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: examsAsync.when(
              data: (exams) {
                if (exams.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.quiz_outlined,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No exams yet',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Create your first exam to get started',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: Colors.grey[600]),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: exams.length,
                  itemBuilder: (context, index) {
                    final exam = exams[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Theme.of(context).primaryColor,
                          child: Icon(
                            _getExamIcon(exam.examType),
                            color: Colors.white,
                          ),
                        ),
                        title: Text(exam.name),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(exam.examType.displayName),
                            if (exam.academicYear != null)
                              Text('Academic Year: ${exam.academicYear}'),
                            if (exam.startDate != null && exam.endDate != null)
                              Text(
                                '${DateFormat('dd MMM').format(exam.startDate!)} - ${DateFormat('dd MMM yyyy').format(exam.endDate!)}',
                              ),
                          ],
                        ),
                        trailing: Chip(
                          label: Text(exam.status.displayName),
                          backgroundColor: _getStatusColor(
                            exam.status,
                          ).withOpacity(0.1),
                          labelStyle: TextStyle(
                            color: _getStatusColor(exam.status),
                          ),
                        ),
                        onTap: () {
                          // TODO: Show exam details
                        },
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
                      'Error loading exams',
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

  IconData _getExamIcon(ExamType type) {
    switch (type) {
      case ExamType.midTerm:
      case ExamType.finalExam:
        return Icons.assignment;
      case ExamType.quiz:
        return Icons.quiz;
      case ExamType.assignment:
        return Icons.article;
      case ExamType.project:
        return Icons.work;
      case ExamType.test:
        return Icons.edit_note;
    }
  }

  Color _getStatusColor(ExamStatus status) {
    switch (status) {
      case ExamStatus.scheduled:
        return Colors.blue;
      case ExamStatus.inProgress:
        return Colors.orange;
      case ExamStatus.completed:
        return Colors.green;
      case ExamStatus.cancelled:
        return Colors.red;
    }
  }
}
