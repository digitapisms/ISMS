import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../application/examination_providers.dart';
import '../../domain/exam.dart';
import '../../domain/exam_type.dart';
import '../../../school_registration/application/school_providers.dart';

class ExamFormDialog extends ConsumerStatefulWidget {
  const ExamFormDialog({super.key, this.exam});

  final Exam? exam;

  @override
  ConsumerState<ExamFormDialog> createState() => _ExamFormDialogState();
}

class _ExamFormDialogState extends ConsumerState<ExamFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _academicYearController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _totalMarksController = TextEditingController(text: '100');
  final _passingMarksController = TextEditingController();

  ExamType _examType = ExamType.test;
  Term? _term;
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.exam != null) {
      final exam = widget.exam!;
      _nameController.text = exam.name;
      _academicYearController.text = exam.academicYear ?? '';
      _descriptionController.text = exam.description ?? '';
      _totalMarksController.text = exam.totalMarks.toString();
      _passingMarksController.text = exam.passingMarks?.toString() ?? '';
      _examType = exam.examType;
      _term = exam.term;
      _startDate = exam.startDate;
      _endDate = exam.endDate;
    } else {
      // Set default academic year (current year - next year)
      final now = DateTime.now();
      _academicYearController.text = '${now.year}-${now.year + 1}';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _academicYearController.dispose();
    _descriptionController.dispose();
    _totalMarksController.dispose();
    _passingMarksController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final school = ref.read(currentSchoolProvider);
      if (school == null) throw Exception('School not found');

      final repo = ref.read(examinationRepositoryProvider);
      final totalMarks = double.tryParse(_totalMarksController.text.trim());
      final passingMarks = _passingMarksController.text.trim().isEmpty
          ? null
          : double.tryParse(_passingMarksController.text.trim());

      if (widget.exam == null) {
        await repo.createExam(
          schoolId: school.id,
          name: _nameController.text.trim(),
          examType: _examType,
          academicYear: _academicYearController.text.trim().isEmpty
              ? null
              : _academicYearController.text.trim(),
          term: _term,
          startDate: _startDate,
          endDate: _endDate,
          totalMarks: totalMarks,
          passingMarks: passingMarks,
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
        );
      } else {
        await repo.updateExam(
          id: widget.exam!.id,
          name: _nameController.text.trim(),
          examType: _examType,
          academicYear: _academicYearController.text.trim().isEmpty
              ? null
              : _academicYearController.text.trim(),
          term: _term,
          startDate: _startDate,
          endDate: _endDate,
          totalMarks: totalMarks,
          passingMarks: passingMarks,
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
        );
      }

      if (mounted) {
        ref.invalidate(examsProvider);
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.exam == null
                  ? 'Exam created successfully'
                  : 'Exam updated successfully',
            ),
          ),
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
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 800),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppBar(
                title: Text(widget.exam == null ? 'Create Exam' : 'Edit Exam'),
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
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Exam Name *',
                          hintText: 'e.g., Mid-Term Exam 2024',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.quiz),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Exam name is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<ExamType>(
                        decoration: const InputDecoration(
                          labelText: 'Exam Type *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.category),
                        ),
                        initialValue: _examType,
                        items: ExamType.values.map((type) {
                          return DropdownMenuItem(
                            value: type,
                            child: Text(type.displayName),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _examType = value;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _academicYearController,
                        decoration: const InputDecoration(
                          labelText: 'Academic Year',
                          hintText: 'e.g., 2024-2025',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.calendar_today),
                        ),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<Term?>(
                        decoration: const InputDecoration(
                          labelText: 'Term',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.event),
                        ),
                        initialValue: _term,
                        items: [
                          const DropdownMenuItem<Term?>(
                            value: null,
                            child: Text('None'),
                          ),
                          ...Term.values.map((term) {
                            return DropdownMenuItem(
                              value: term,
                              child: Text(term.displayName),
                            );
                          }),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _term = value;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () async {
                                final date = await showDatePicker(
                                  context: context,
                                  initialDate: _startDate ?? DateTime.now(),
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime(2100),
                                );
                                if (date != null) {
                                  setState(() {
                                    _startDate = date;
                                  });
                                }
                              },
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  labelText: 'Start Date',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.calendar_today),
                                ),
                                child: Text(
                                  _startDate != null
                                      ? DateFormat(
                                          'yyyy-MM-dd',
                                        ).format(_startDate!)
                                      : 'Select start date',
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: InkWell(
                              onTap: () async {
                                final date = await showDatePicker(
                                  context: context,
                                  initialDate:
                                      _endDate ?? _startDate ?? DateTime.now(),
                                  firstDate: _startDate ?? DateTime(2020),
                                  lastDate: DateTime(2100),
                                );
                                if (date != null) {
                                  setState(() {
                                    _endDate = date;
                                  });
                                }
                              },
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  labelText: 'End Date',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.event),
                                ),
                                child: Text(
                                  _endDate != null
                                      ? DateFormat(
                                          'yyyy-MM-dd',
                                        ).format(_endDate!)
                                      : 'Select end date',
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _totalMarksController,
                              decoration: const InputDecoration(
                                labelText: 'Total Marks *',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.numbers),
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Total marks is required';
                                }
                                final marks = double.tryParse(value.trim());
                                if (marks == null || marks <= 0) {
                                  return 'Please enter a valid number';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _passingMarksController,
                              decoration: const InputDecoration(
                                labelText: 'Passing Marks',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.check_circle),
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.description),
                        ),
                        maxLines: 3,
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
                      onPressed: _isSaving
                          ? null
                          : () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: _isSaving ? null : _save,
                      child: _isSaving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(widget.exam == null ? 'Create' : 'Update'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
