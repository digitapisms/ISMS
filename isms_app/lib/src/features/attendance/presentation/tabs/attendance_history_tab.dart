import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../application/attendance_providers.dart';
import '../../domain/attendance_record.dart';
import '../../domain/attendance_status.dart';
import '../../../class_management/application/class_providers.dart';

class AttendanceHistoryTab extends ConsumerStatefulWidget {
  const AttendanceHistoryTab({super.key});

  @override
  ConsumerState<AttendanceHistoryTab> createState() =>
      _AttendanceHistoryTabState();
}

class _AttendanceHistoryTabState extends ConsumerState<AttendanceHistoryTab> {
  int? _selectedClassId;
  int? _selectedSectionId;
  String? _selectedStudentId;
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _endDate = DateTime.now();
    _startDate = DateTime.now().subtract(const Duration(days: 30));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Filters
        Container(
          padding: const EdgeInsets.all(16),
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: Column(
            children: [
              // Date Range
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _startDate ?? DateTime.now(),
                          firstDate: DateTime.now().subtract(
                            const Duration(days: 365),
                          ),
                          lastDate: DateTime.now(),
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
                          suffixIcon: Icon(Icons.calendar_today, size: 20),
                        ),
                        child: Text(
                          _startDate != null
                              ? DateFormat('MMM dd, yyyy').format(_startDate!)
                              : 'Select date',
                          style: Theme.of(context).textTheme.bodyMedium,
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
                          initialDate: _endDate ?? DateTime.now(),
                          firstDate:
                              _startDate ??
                              DateTime.now().subtract(
                                const Duration(days: 365),
                              ),
                          lastDate: DateTime.now(),
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
                          suffixIcon: Icon(Icons.calendar_today, size: 20),
                        ),
                        child: Text(
                          _endDate != null
                              ? DateFormat('MMM dd, yyyy').format(_endDate!)
                              : 'Select date',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Class Selection
              _ClassSelector(
                selectedClassId: _selectedClassId,
                onClassSelected: (classId) {
                  setState(() {
                    _selectedClassId = classId;
                    _selectedSectionId = null;
                    _selectedStudentId = null;
                  });
                },
              ),
              if (_selectedClassId != null) ...[
                const SizedBox(height: 16),
                _SectionSelector(
                  classId: _selectedClassId!,
                  selectedSectionId: _selectedSectionId,
                  onSectionSelected: (sectionId) {
                    setState(() {
                      _selectedSectionId = sectionId;
                      _selectedStudentId = null;
                    });
                  },
                ),
              ],
              if (_selectedClassId != null) ...[
                const SizedBox(height: 16),
                _StudentSelector(
                  classId: _selectedClassId!,
                  sectionId: _selectedSectionId,
                  selectedStudentId: _selectedStudentId,
                  onStudentSelected: (studentId) {
                    setState(() {
                      _selectedStudentId = studentId;
                    });
                  },
                ),
              ],
            ],
          ),
        ),
        // Attendance List
        Expanded(child: _buildAttendanceList()),
      ],
    );
  }

  Widget _buildAttendanceList() {
    if (_selectedStudentId != null && _startDate != null && _endDate != null) {
      final attendanceAsync = ref.watch(
        studentAttendanceProvider(
          StudentAttendanceFilter(
            studentId: _selectedStudentId!,
            startDate: _startDate,
            endDate: _endDate,
          ),
        ),
      );

      return attendanceAsync.when(
        data: (records) {
          if (records.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No attendance records found',
                    style: Theme.of(
                      context,
                    ).textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: records.length,
            itemBuilder: (context, index) {
              final record = records[index];
              return _AttendanceRecordCard(record: record);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
              const SizedBox(height: 16),
              Text(
                'Failed to load attendance',
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
      );
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.filter_list, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Select filters to view attendance history',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}

class _ClassSelector extends ConsumerWidget {
  const _ClassSelector({this.selectedClassId, required this.onClassSelected});

  final String? selectedClassId;
  final ValueChanged<String?> onClassSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final classesAsync = ref.watch(classesProvider);

    return classesAsync.when(
      data: (classes) {
        if (classes.isEmpty) {
          return const Text('No classes available');
        }
        return DropdownButtonFormField<String>(
          value: selectedClassId,
          decoration: const InputDecoration(
            labelText: 'Class (Optional)',
            border: OutlineInputBorder(),
          ),
          items: [
            const DropdownMenuItem<String>(
              value: null,
              child: Text('All Classes'),
            ),
            ...classes.map((cls) {
              return DropdownMenuItem<String>(value: cls.id, child: Text(cls.name));
            }),
          ],
          onChanged: onClassSelected,
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Text('Error: $error'),
    );
  }
}

class _SectionSelector extends ConsumerWidget {
  const _SectionSelector({
    required this.classId,
    this.selectedSectionId,
    required this.onSectionSelected,
  });

  final String classId;
  final int? selectedSectionId;
  final ValueChanged<int?> onSectionSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sectionsAsync = ref.watch(sectionsProvider(classId));

    return sectionsAsync.when(
      data: (sections) {
        return DropdownButtonFormField<int>(
          initialValue: selectedSectionId,
          decoration: const InputDecoration(
            labelText: 'Section (Optional)',
            border: OutlineInputBorder(),
          ),
          items: [
            const DropdownMenuItem<int>(
              value: null,
              child: Text('All Sections'),
            ),
            ...sections.map((section) {
              return DropdownMenuItem(
                value: section.id,
                child: Text(section.name),
              );
            }),
          ],
          onChanged: onSectionSelected,
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _StudentSelector extends ConsumerWidget {
  const _StudentSelector({
    required this.classId,
    this.sectionId,
    this.selectedStudentId,
    required this.onStudentSelected,
  });

  final int classId;
  final int? sectionId;
  final String? selectedStudentId;
  final ValueChanged<String?> onStudentSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final studentsAsync = ref.watch(
      studentsForAttendanceProvider(
        AttendanceFilter(classId: classId, sectionId: sectionId),
      ),
    );

    return studentsAsync.when(
      data: (students) {
        return DropdownButtonFormField<String>(
          initialValue: selectedStudentId,
          decoration: const InputDecoration(
            labelText: 'Student (Optional)',
            border: OutlineInputBorder(),
            helperText: 'Select a student to view their attendance history',
          ),
          items: [
            const DropdownMenuItem<String>(
              value: null,
              child: Text('All Students'),
            ),
            ...students.map((student) {
              return DropdownMenuItem(
                value: student.id,
                child: Text('${student.fullName} (${student.admissionNo})'),
              );
            }),
          ],
          onChanged: onStudentSelected,
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _AttendanceRecordCard extends StatelessWidget {
  const _AttendanceRecordCard({required this.record});

  final AttendanceRecord record;

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(record.status);
    final statusIcon = _getStatusIcon(record.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(statusIcon, color: statusColor, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    DateFormat('MMM dd, yyyy').format(record.attendanceDate),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    record.status.displayName,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (record.notes != null && record.notes!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      record.notes!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.present:
        return Colors.green;
      case AttendanceStatus.absent:
        return Colors.red;
      case AttendanceStatus.late:
        return Colors.orange;
      case AttendanceStatus.excused:
        return Colors.blue;
      case AttendanceStatus.halfDay:
        return Colors.purple;
    }
  }

  IconData _getStatusIcon(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.present:
        return Icons.check_circle;
      case AttendanceStatus.absent:
        return Icons.cancel;
      case AttendanceStatus.late:
        return Icons.schedule;
      case AttendanceStatus.excused:
        return Icons.info;
      case AttendanceStatus.halfDay:
        return Icons.hourglass_empty;
    }
  }
}
