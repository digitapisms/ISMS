import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/examination_providers.dart';
import '../../domain/exam_type.dart';
import '../dialogs/grade_entry_dialog.dart';

/// Tab for entering grades
class GradeEntryTab extends ConsumerStatefulWidget {
  const GradeEntryTab({super.key});

  @override
  ConsumerState<GradeEntryTab> createState() => _GradeEntryTabState();
}

class _GradeEntryTabState extends ConsumerState<GradeEntryTab> {
  int? _selectedExamId;

  @override
  Widget build(BuildContext context) {
    final examsAsync = ref.watch(examsProvider);
    final gradesAsync = _selectedExamId != null
        ? ref.watch(examGradesByExamProvider(_selectedExamId!))
        : null;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Grade Entry',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              if (_selectedExamId != null)
                ElevatedButton.icon(
                  onPressed: () async {
                    final exam = await ref.read(
                      examProvider(_selectedExamId!).future,
                    );
                    final result = await showDialog(
                      context: context,
                      builder: (_) => GradeEntryDialog(exam: exam),
                    );
                    if (result == true) {
                      ref.invalidate(
                        examGradesByExamProvider(_selectedExamId!),
                      );
                    }
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Enter Grades'),
                ),
            ],
          ),
          const SizedBox(height: 16),
          // Exam Selection
          examsAsync.when(
            data: (exams) {
              if (exams.isEmpty) {
                return const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(
                      child: Text('No exams available. Create an exam first.'),
                    ),
                  ),
                );
              }

              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: DropdownButtonFormField<int>(
                    decoration: const InputDecoration(
                      labelText: 'Select Exam',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.quiz),
                    ),
                    value: _selectedExamId,
                    items: exams.map((exam) {
                      return DropdownMenuItem(
                        value: exam.id,
                        child: Text(
                          '${exam.name} (${exam.examType.displayName})',
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedExamId = value;
                      });
                    },
                  ),
                ),
              );
            },
            loading: () => const LinearProgressIndicator(),
            error: (_, __) => const Text('Error loading exams'),
          ),
          const SizedBox(height: 24),
          // Grades List
          if (_selectedExamId != null)
            Expanded(
              child: gradesAsync!.when(
                data: (grades) {
                  if (grades.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.grade_outlined,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No grades entered yet',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Click "Enter Grades" to start entering marks',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: Colors.grey[600]),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: grades.length,
                    itemBuilder: (context, index) {
                      final grade = grades[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: grade.isAbsent
                                ? Colors.red
                                : grade.isExempted
                                ? Colors.orange
                                : Colors.green,
                            child: Text(
                              grade.grade ?? 'N/A',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(
                            'Student ID: ${grade.studentId.substring(0, 8)}...',
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Marks: ${grade.marksObtained.toStringAsFixed(2)} / ${grade.totalMarks.toStringAsFixed(2)}',
                              ),
                              if (grade.percentage != null)
                                Text(
                                  'Percentage: ${grade.percentage!.toStringAsFixed(2)}%',
                                ),
                              if (grade.remarks != null)
                                Text('Remarks: ${grade.remarks}'),
                            ],
                          ),
                          trailing: grade.isAbsent
                              ? const Chip(
                                  label: Text('Absent'),
                                  backgroundColor: Colors.red,
                                  labelStyle: TextStyle(color: Colors.white),
                                )
                              : grade.isExempted
                              ? const Chip(
                                  label: Text('Exempted'),
                                  backgroundColor: Colors.orange,
                                  labelStyle: TextStyle(color: Colors.white),
                                )
                              : null,
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
                        'Error loading grades',
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
            )
          else
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.select_all, size: 64, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      'Select an exam to view grades',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
