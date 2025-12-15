import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/assignment_providers.dart';
import '../../domain/assignment.dart';
import '../../domain/assignment_type.dart';
import '../../../authentication/application/auth_providers.dart';
import '../../../class_management/application/class_providers.dart';
import '../../../examination/application/examination_providers.dart';
import '../../../school_registration/application/school_providers.dart';

class AssignmentFormDialog extends ConsumerStatefulWidget {
  const AssignmentFormDialog({super.key, this.assignment});

  final Assignment? assignment;

  @override
  ConsumerState<AssignmentFormDialog> createState() =>
      _AssignmentFormDialogState();
}

class _AssignmentFormDialogState extends ConsumerState<AssignmentFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _instructionsController = TextEditingController();
  final _maxPointsController = TextEditingController();
  final _weightageController = TextEditingController();
  final _latePenaltyController = TextEditingController();
  final _academicYearController = TextEditingController();

  AssignmentType _assignmentType = AssignmentType.homework;
  int? _selectedClassId;
  int? _selectedSectionId;
  int? _selectedSubjectId;
  String? _selectedTerm;
  DateTime? _dueDate;
  bool _allowLateSubmission = true;
  bool _allowResubmission = false;
  bool _isPublished = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.assignment != null) {
      final assignment = widget.assignment!;
      _titleController.text = assignment.title;
      _descriptionController.text = assignment.description ?? '';
      _instructionsController.text = assignment.instructions ?? '';
      _maxPointsController.text = assignment.maxPoints.toString();
      _weightageController.text = assignment.weightage?.toString() ?? '';
      _latePenaltyController.text = assignment.latePenaltyPerDay.toString();
      _academicYearController.text = assignment.academicYear;
      _assignmentType = assignment.assignmentType;
      _selectedClassId = assignment.classId;
      _selectedSectionId = assignment.sectionId;
      _selectedSubjectId = assignment.subjectId;
      _selectedTerm = assignment.term;
      _dueDate = assignment.dueDate;
      _allowLateSubmission = assignment.allowLateSubmission;
      _allowResubmission = assignment.allowResubmission;
      _isPublished = assignment.isPublished;
    } else {
      final now = DateTime.now();
      _academicYearController.text = '${now.year}-${now.year + 1}';
      _maxPointsController.text = '100';
      _dueDate = now.add(const Duration(days: 7));
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _instructionsController.dispose();
    _maxPointsController.dispose();
    _weightageController.dispose();
    _latePenaltyController.dispose();
    _academicYearController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedClassId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a class')));
      return;
    }
    if (_dueDate == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a due date')));
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final school = ref.read(currentSchoolProvider);
      if (school == null) throw Exception('School not found');

      final authUser = ref.read(authStateProvider);
      if (authUser == null) throw Exception('User not found');

      final repo = ref.read(assignmentRepositoryProvider);

      if (widget.assignment == null) {
        await repo.createAssignment(
          schoolId: school.id,
          title: _titleController.text.trim(),
          classId: _selectedClassId!,
          teacherId: authUser.id,
          academicYear: _academicYearController.text.trim(),
          dueDate: _dueDate!,
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          assignmentType: _assignmentType,
          subjectId: _selectedSubjectId,
          sectionId: _selectedSectionId,
          term: _selectedTerm,
          maxPoints: double.tryParse(_maxPointsController.text.trim()),
          weightage: _weightageController.text.trim().isEmpty
              ? null
              : double.tryParse(_weightageController.text.trim()),
          instructions: _instructionsController.text.trim().isEmpty
              ? null
              : _instructionsController.text.trim(),
          allowLateSubmission: _allowLateSubmission,
          latePenaltyPerDay:
              double.tryParse(_latePenaltyController.text.trim()) ?? 0.0,
          allowResubmission: _allowResubmission,
          createdBy: authUser.id,
        );
      } else {
        await repo.updateAssignment(
          id: widget.assignment!.id,
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          dueDate: _dueDate,
          maxPoints: double.tryParse(_maxPointsController.text.trim()),
          weightage: _weightageController.text.trim().isEmpty
              ? null
              : double.tryParse(_weightageController.text.trim()),
          instructions: _instructionsController.text.trim().isEmpty
              ? null
              : _instructionsController.text.trim(),
          allowLateSubmission: _allowLateSubmission,
          latePenaltyPerDay:
              double.tryParse(_latePenaltyController.text.trim()) ?? 0.0,
          allowResubmission: _allowResubmission,
          isPublished: _isPublished,
        );
      }

      if (mounted) {
        ref.invalidate(assignmentsProvider);
        if (authUser.id.isNotEmpty) {
          ref.invalidate(assignmentsByTeacherProvider(authUser.id));
        }
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.assignment == null
                  ? 'Assignment created successfully'
                  : 'Assignment updated successfully',
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
    final classesAsync = ref.watch(classesProvider);
    final subjectsAsync = ref.watch(subjectsProvider);

    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 800),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppBar(
                title: Text(
                  widget.assignment == null
                      ? 'Create Assignment'
                      : 'Edit Assignment',
                ),
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
                    children: [
                      TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          labelText: 'Title *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.title),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Title is required';
                          }
                          return null;
                        },
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
                      const SizedBox(height: 16),
                      DropdownButtonFormField<AssignmentType>(
                        decoration: const InputDecoration(
                          labelText: 'Assignment Type *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.category),
                        ),
                        initialValue: _assignmentType,
                        items: AssignmentType.values.map((type) {
                          return DropdownMenuItem(
                            value: type,
                            child: Text(type.displayName),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _assignmentType = value;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      classesAsync.when(
                        data: (classes) => DropdownButtonFormField<int>(
                          decoration: const InputDecoration(
                            labelText: 'Class *',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.class_),
                          ),
                          initialValue: _selectedClassId,
                          items: classes.map((cls) {
                            return DropdownMenuItem(
                              value: cls.id,
                              child: Text(cls.name),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedClassId = value;
                              _selectedSectionId = null;
                            });
                          },
                        ),
                        loading: () => const LinearProgressIndicator(),
                        error: (_, __) => const Text('Error loading classes'),
                      ),
                      const SizedBox(height: 16),
                      subjectsAsync.when(
                        data: (subjects) => DropdownButtonFormField<int>(
                          decoration: const InputDecoration(
                            labelText: 'Subject',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.subject),
                          ),
                          initialValue: _selectedSubjectId,
                          items: subjects.map((subject) {
                            return DropdownMenuItem(
                              value: subject.id,
                              child: Text(subject.name),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedSubjectId = value;
                            });
                          },
                        ),
                        loading: () => const LinearProgressIndicator(),
                        error: (_, __) => const Text('Error loading subjects'),
                      ),
                      const SizedBox(height: 16),
                      InkWell(
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: _dueDate ?? DateTime.now(),
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(
                              const Duration(days: 365),
                            ),
                          );
                          if (date != null) {
                            final time = await showTimePicker(
                              context: context,
                              initialTime: TimeOfDay.fromDateTime(
                                _dueDate ?? DateTime.now(),
                              ),
                            );
                            if (time != null) {
                              setState(() {
                                _dueDate = DateTime(
                                  date.year,
                                  date.month,
                                  date.day,
                                  time.hour,
                                  time.minute,
                                );
                              });
                            }
                          }
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Due Date *',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.calendar_today),
                          ),
                          child: Text(
                            _dueDate != null
                                ? '${_dueDate!.day}/${_dueDate!.month}/${_dueDate!.year} ${_dueDate!.hour}:${_dueDate!.minute.toString().padLeft(2, '0')}'
                                : 'Select due date',
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _maxPointsController,
                              decoration: const InputDecoration(
                                labelText: 'Max Points',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.star),
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _weightageController,
                              decoration: const InputDecoration(
                                labelText: 'Weightage (%)',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.percent),
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _instructionsController,
                        decoration: const InputDecoration(
                          labelText: 'Instructions',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.notes),
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _latePenaltyController,
                        decoration: const InputDecoration(
                          labelText: 'Late Penalty Per Day (%)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.warning),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 16),
                      SwitchListTile(
                        title: const Text('Allow Late Submission'),
                        value: _allowLateSubmission,
                        onChanged: (value) {
                          setState(() {
                            _allowLateSubmission = value;
                          });
                        },
                      ),
                      SwitchListTile(
                        title: const Text('Allow Resubmission'),
                        value: _allowResubmission,
                        onChanged: (value) {
                          setState(() {
                            _allowResubmission = value;
                          });
                        },
                      ),
                      if (widget.assignment != null)
                        SwitchListTile(
                          title: const Text('Published'),
                          value: _isPublished,
                          onChanged: (value) {
                            setState(() {
                              _isPublished = value;
                            });
                          },
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
                          : Text(
                              widget.assignment == null ? 'Create' : 'Update',
                            ),
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
