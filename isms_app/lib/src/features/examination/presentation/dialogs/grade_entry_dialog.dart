import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/examination_providers.dart';
import '../../domain/exam.dart';
import '../../../class_management/application/class_providers.dart';
import '../../../school_registration/application/school_providers.dart';
import '../../../student_management/application/student_providers.dart';

class GradeEntryDialog extends ConsumerStatefulWidget {
  const GradeEntryDialog({super.key, required this.exam});

  final Exam exam;

  @override
  ConsumerState<GradeEntryDialog> createState() => _GradeEntryDialogState();
}

class _GradeEntryDialogState extends ConsumerState<GradeEntryDialog> {
  int? _selectedClassId;
  int? _selectedSectionId;
  int? _selectedSubjectId;
  final Map<String, TextEditingController> _gradeControllers = {};
  final Map<String, bool> _absentFlags = {};
  final Map<String, bool> _exemptedFlags = {};
  bool _isSaving = false;

  @override
  void dispose() {
    for (final controller in _gradeControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadStudents() async {
    final studentsAsync = ref.read(studentsProvider);
    await studentsAsync.when(
      data: (students) {
        // Filter by class/section
        var filteredStudents = students;
        if (_selectedClassId != null) {
          filteredStudents = filteredStudents
              .where((s) => s.classId == _selectedClassId)
              .toList();
          if (_selectedSectionId != null) {
            filteredStudents = filteredStudents
                .where((s) => s.sectionId == _selectedSectionId)
                .toList();
          }
        }

        // Initialize controllers
        for (final student in filteredStudents) {
          if (!_gradeControllers.containsKey(student.id)) {
            _gradeControllers[student.id] = TextEditingController();
            _absentFlags[student.id] = false;
            _exemptedFlags[student.id] = false;
          }
        }
      },
      loading: () {},
      error: (_, __) {},
    );
  }

  Future<void> _save() async {
    setState(() {
      _isSaving = true;
    });

    try {
      final school = ref.read(currentSchoolProvider);
      if (school == null) throw Exception('School not found');

      final repo = ref.read(examinationRepositoryProvider);
      final studentsAsync = ref.read(studentsProvider);

      await studentsAsync.when(
        data: (allStudents) async {
          var students = allStudents;
          if (_selectedClassId != null) {
            students = students
                .where((s) => s.classId == _selectedClassId)
                .toList();
            if (_selectedSectionId != null) {
              students = students
                  .where((s) => s.sectionId == _selectedSectionId)
                  .toList();
            }
          }

          final grades = <Map<String, dynamic>>[];

          for (final student in students) {
            final controller = _gradeControllers[student.id];
            final isAbsent = _absentFlags[student.id] ?? false;
            final isExempted = _exemptedFlags[student.id] ?? false;

            if (controller != null && controller.text.trim().isNotEmpty) {
              final marks = double.tryParse(controller.text.trim());
              if (marks != null) {
                grades.add({
                  'exam_id': widget.exam.id,
                  'student_id': student.id,
                  'subject_id': _selectedSubjectId,
                  'marks_obtained': marks,
                  'total_marks': widget.exam.totalMarks,
                  'is_absent': isAbsent,
                  'is_exempted': isExempted,
                });
              }
            } else if (isAbsent || isExempted) {
              grades.add({
                'exam_id': widget.exam.id,
                'student_id': student.id,
                'subject_id': _selectedSubjectId,
                'marks_obtained': 0,
                'total_marks': widget.exam.totalMarks,
                'is_absent': isAbsent,
                'is_exempted': isExempted,
              });
            }
          }

          if (grades.isNotEmpty) {
            await repo.bulkCreateExamGrades(
              schoolId: school.id,
              grades: grades,
            );
          }
        },
        loading: () async {},
        error: (_, __) async {
          throw Exception('Error loading students');
        },
      );

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Grades saved successfully')),
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
    final studentsAsync = ref.watch(studentsProvider);

    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800, maxHeight: 900),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              title: Text('Enter Grades - ${widget.exam.name}'),
              automaticallyImplyLeading: false,
              actions: [
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: classesAsync.when(
                      data: (classes) => DropdownButtonFormField<int>(
                        decoration: const InputDecoration(
                          labelText: 'Class',
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
                            _gradeControllers.clear();
                            _absentFlags.clear();
                            _exemptedFlags.clear();
                          });
                          _loadStudents();
                        },
                      ),
                      loading: () => const LinearProgressIndicator(),
                      error: (_, __) => const Text('Error'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: subjectsAsync.when(
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
                      error: (_, __) => const Text('Error'),
                    ),
                  ),
                ],
              ),
            ),
            Flexible(
              child: studentsAsync.when(
                data: (allStudents) {
                  var students = allStudents;
                  if (_selectedClassId != null) {
                    students = students
                        .where((s) => s.classId == _selectedClassId)
                        .toList();
                    if (_selectedSectionId != null) {
                      students = students
                          .where((s) => s.sectionId == _selectedSectionId)
                          .toList();
                    }
                  }

                  if (students.isEmpty) {
                    return const Center(
                      child: Text('No students found. Select a class.'),
                    );
                  }

                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: students.map((student) {
                        if (!_gradeControllers.containsKey(student.id)) {
                          _gradeControllers[student.id] =
                              TextEditingController();
                          _absentFlags[student.id] = false;
                          _exemptedFlags[student.id] = false;
                        }

                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: Text(student.fullName),
                                ),
                                Expanded(
                                  child: TextField(
                                    controller: _gradeControllers[student.id],
                                    decoration: InputDecoration(
                                      labelText: 'Marks',
                                      hintText:
                                          '0-${widget.exam.totalMarks.toInt()}',
                                      border: const OutlineInputBorder(),
                                      enabled:
                                          !(_absentFlags[student.id] ??
                                              false) &&
                                          !(_exemptedFlags[student.id] ??
                                              false),
                                    ),
                                    keyboardType: TextInputType.number,
                                  ),
                                ),
                                Checkbox(
                                  value: _absentFlags[student.id] ?? false,
                                  onChanged: (value) {
                                    setState(() {
                                      _absentFlags[student.id] = value ?? false;
                                      if (value == true) {
                                        _exemptedFlags[student.id] = false;
                                        _gradeControllers[student.id]?.clear();
                                      }
                                    });
                                  },
                                ),
                                const Text('Absent'),
                                Checkbox(
                                  value: _exemptedFlags[student.id] ?? false,
                                  onChanged: (value) {
                                    setState(() {
                                      _exemptedFlags[student.id] =
                                          value ?? false;
                                      if (value == true) {
                                        _absentFlags[student.id] = false;
                                        _gradeControllers[student.id]?.clear();
                                      }
                                    });
                                  },
                                ),
                                const Text('Exempt'),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) =>
                    const Center(child: Text('Error loading students')),
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
                        : const Text('Save Grades'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
