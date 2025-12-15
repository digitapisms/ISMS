import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/examination_providers.dart';
import '../../../attendance/application/attendance_providers.dart';
import '../../../class_management/application/class_providers.dart';
import '../../../school_registration/application/school_providers.dart';
import '../../../student_management/application/student_providers.dart';

class ReportCardGenerationDialog extends ConsumerStatefulWidget {
  const ReportCardGenerationDialog({super.key});

  @override
  ConsumerState<ReportCardGenerationDialog> createState() =>
      _ReportCardGenerationDialogState();
}

class _ReportCardGenerationDialogState
    extends ConsumerState<ReportCardGenerationDialog> {
  int? _selectedClassId;
  int? _selectedSectionId;
  String? _selectedStudentId;
  String _academicYear = '';
  String _term = 'first_term';
  bool _isGenerating = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _academicYear = '${now.year}-${now.year + 1}';
  }

  Future<void> _generate() async {
    if (_selectedStudentId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a student')));
      return;
    }

    setState(() {
      _isGenerating = true;
    });

    try {
      final school = ref.read(currentSchoolProvider);
      if (school == null) throw Exception('School not found');

      final repo = ref.read(examinationRepositoryProvider);

      // Get attendance percentage from stats
      final attendanceStatsAsync = ref.read(
        studentAttendanceStatsProvider(
          StudentAttendanceStatsFilter(
            studentId: _selectedStudentId!,
            startDate: DateTime.now().subtract(const Duration(days: 365)),
            endDate: DateTime.now(),
          ),
        ),
      );
      double? attendancePercentage;
      await attendanceStatsAsync.when(
        data: (stats) {
          attendancePercentage = stats.attendancePercentage;
        },
        loading: () {},
        error: (_, __) {},
      );

      await repo.generateReportCard(
        schoolId: school.id,
        studentId: _selectedStudentId!,
        classId: _selectedClassId!,
        academicYear: _academicYear,
        term: _term,
        sectionId: _selectedSectionId,
        attendancePercentage: attendancePercentage,
      );

      if (mounted) {
        ref.invalidate(reportCardsProvider);
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Report card generated successfully')),
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
          _isGenerating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final classesAsync = ref.watch(classesProvider);
    final studentsAsync = ref.watch(studentsProvider);

    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Generate Report Card',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              TextFormField(
                initialValue: _academicYear,
                decoration: const InputDecoration(
                  labelText: 'Academic Year *',
                  hintText: 'e.g., 2024-2025',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.calendar_today),
                ),
                onChanged: (value) {
                  setState(() {
                    _academicYear = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Term *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.event),
                ),
                initialValue: _term,
                items: const [
                  DropdownMenuItem(
                    value: 'first_term',
                    child: Text('First Term'),
                  ),
                  DropdownMenuItem(
                    value: 'second_term',
                    child: Text('Second Term'),
                  ),
                  DropdownMenuItem(
                    value: 'third_term',
                    child: Text('Third Term'),
                  ),
                  DropdownMenuItem(value: 'annual', child: Text('Annual')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _term = value;
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
                      _selectedStudentId = null;
                    });
                  },
                ),
                loading: () => const LinearProgressIndicator(),
                error: (_, __) => const Text('Error loading classes'),
              ),
              const SizedBox(height: 16),
              studentsAsync.when(
                data: (allStudents) {
                  var students = allStudents;
                  if (_selectedClassId != null) {
                    students = students
                        .where((s) => s.classId == _selectedClassId)
                        .toList();
                  }

                  return DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Student *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                    ),
                    initialValue: _selectedStudentId,
                    items: students.map((student) {
                      return DropdownMenuItem(
                        value: student.id,
                        child: Text(
                          '${student.fullName} (${student.admissionNo})',
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedStudentId = value;
                      });
                    },
                  );
                },
                loading: () => const LinearProgressIndicator(),
                error: (_, __) => const Text('Error loading students'),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isGenerating
                        ? null
                        : () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _isGenerating ? null : _generate,
                    child: _isGenerating
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Generate'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
