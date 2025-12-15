import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/timetable_providers.dart';
import '../../domain/timetable.dart';
import '../../../authentication/application/auth_providers.dart';
import '../../../class_management/application/class_providers.dart';
import '../../../examination/domain/exam_type.dart';
import '../../../school_registration/application/school_providers.dart';

class TimetableFormDialog extends ConsumerStatefulWidget {
  const TimetableFormDialog({super.key, this.timetable});

  final Timetable? timetable;

  @override
  ConsumerState<TimetableFormDialog> createState() =>
      _TimetableFormDialogState();
}

class _TimetableFormDialogState extends ConsumerState<TimetableFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _academicYearController = TextEditingController();
  int? _selectedClassId;
  int? _selectedSectionId;
  Term? _term;
  DateTime? _effectiveFrom;
  DateTime? _effectiveTo;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.timetable != null) {
      final timetable = widget.timetable!;
      _nameController.text = timetable.name;
      _academicYearController.text = timetable.academicYear;
      _selectedClassId = timetable.classId;
      _selectedSectionId = timetable.sectionId;
      _term = timetable.term;
      _effectiveFrom = timetable.effectiveFrom;
      _effectiveTo = timetable.effectiveTo;
    } else {
      final now = DateTime.now();
      _academicYearController.text = '${now.year}-${now.year + 1}';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
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

    setState(() {
      _isSaving = true;
    });

    try {
      final school = ref.read(currentSchoolProvider);
      if (school == null) throw Exception('School not found');

      final repo = ref.read(timetableRepositoryProvider);
      final authUser = ref.read(authStateProvider);
      final userId = authUser?.id;

      if (widget.timetable == null) {
        await repo.createTimetable(
          schoolId: school.id,
          name: _nameController.text.trim(),
          classId: _selectedClassId!,
          academicYear: _academicYearController.text.trim(),
          sectionId: _selectedSectionId,
          term: _term,
          effectiveFrom: _effectiveFrom,
          effectiveTo: _effectiveTo,
          createdBy: userId,
        );
      } else {
        await repo.updateTimetable(
          id: widget.timetable!.id,
          name: _nameController.text.trim(),
          effectiveFrom: _effectiveFrom,
          effectiveTo: _effectiveTo,
        );
      }

      if (mounted) {
        ref.invalidate(timetablesProvider);
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.timetable == null
                  ? 'Timetable created successfully'
                  : 'Timetable updated successfully',
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

    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppBar(
                title: Text(
                  widget.timetable == null
                      ? 'Create Timetable'
                      : 'Edit Timetable',
                ),
                automaticallyImplyLeading: false,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Timetable Name *',
                        hintText: 'e.g., Class 10-A Timetable 2024-2025',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.calendar_today),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Timetable name is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _academicYearController,
                      decoration: const InputDecoration(
                        labelText: 'Academic Year *',
                        hintText: 'e.g., 2024-2025',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.calendar_today),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Academic year is required';
                        }
                        return null;
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
                        value: _selectedClassId,
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
                    DropdownButtonFormField<Term?>(
                      decoration: const InputDecoration(
                        labelText: 'Term',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.event),
                      ),
                      value: _term,
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
                  ],
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
                              widget.timetable == null ? 'Create' : 'Update',
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
