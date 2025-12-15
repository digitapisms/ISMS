import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/attendance_providers.dart';
import '../../domain/attendance_status.dart';
import '../../domain/attendance_summary.dart';
import '../../../school_registration/application/school_providers.dart';
import '../../../student_management/domain/student.dart';

class AttendanceMarkingWidget extends ConsumerStatefulWidget {
  const AttendanceMarkingWidget({
    super.key,
    required this.classId,
    this.sectionId,
    required this.attendanceDate,
  });

  final int classId;
  final int? sectionId;
  final DateTime attendanceDate;

  @override
  ConsumerState<AttendanceMarkingWidget> createState() =>
      _AttendanceMarkingWidgetState();
}

class _AttendanceMarkingWidgetState
    extends ConsumerState<AttendanceMarkingWidget> {
  final Map<String, AttendanceStatus> _attendanceMap = {};
  final Map<String, String> _notesMap = {};
  bool _isSaving = false;

  @override
  Widget build(BuildContext context) {
    final studentsAsync = ref.watch(
      studentsForAttendanceProvider(
        AttendanceFilter(classId: widget.classId, sectionId: widget.sectionId),
      ),
    );

    final summaryAsync = ref.watch(
      classAttendanceSummaryProvider(
        ClassAttendanceSummaryFilter(
          classId: widget.classId,
          sectionId: widget.sectionId,
          attendanceDate: widget.attendanceDate,
        ),
      ),
    );

    final existingAttendanceAsync = ref.watch(
      classAttendanceProvider(
        ClassAttendanceFilter(
          classId: widget.classId,
          sectionId: widget.sectionId,
          attendanceDate: widget.attendanceDate,
        ),
      ),
    );

    return studentsAsync.when(
      data: (students) {
        // Load existing attendance into map
        existingAttendanceAsync.whenData((records) {
          for (final record in records) {
            if (!_attendanceMap.containsKey(record.studentId)) {
              _attendanceMap[record.studentId] = record.status;
              _notesMap[record.studentId] = record.notes ?? '';
            }
          }
        });

        if (students.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'No students found',
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            // Summary Card
            summaryAsync.when(
              data: (summary) => _SummaryCard(summary: summary),
              loading: () => const LinearProgressIndicator(),
              error: (_, __) => const SizedBox.shrink(),
            ),
            // Quick Actions
            Container(
              padding: const EdgeInsets.all(16),
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _QuickActionButton(
                    icon: Icons.check_circle,
                    label: 'Mark All Present',
                    color: Colors.green,
                    onPressed: () =>
                        _markAll(students, AttendanceStatus.present),
                  ),
                  _QuickActionButton(
                    icon: Icons.cancel,
                    label: 'Mark All Absent',
                    color: Colors.red,
                    onPressed: () =>
                        _markAll(students, AttendanceStatus.absent),
                  ),
                  _QuickActionButton(
                    icon: Icons.clear_all,
                    label: 'Clear All',
                    color: Colors.grey,
                    onPressed: () {
                      setState(() {
                        _attendanceMap.clear();
                        _notesMap.clear();
                      });
                    },
                  ),
                ],
              ),
            ),
            // Student List
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: students.length,
                itemBuilder: (context, index) {
                  final student = students[index];
                  final status =
                      _attendanceMap[student.id] ?? AttendanceStatus.present;
                  return _StudentAttendanceCard(
                    student: student,
                    status: status,
                    notes: _notesMap[student.id] ?? '',
                    onStatusChanged: (newStatus) {
                      setState(() {
                        _attendanceMap[student.id] = newStatus;
                      });
                    },
                    onNotesChanged: (notes) {
                      _notesMap[student.id] = notes;
                    },
                  );
                },
              ),
            ),
            // Save Button
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : () => _saveAttendance(students),
                  icon: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save),
                  label: Text(_isSaving ? 'Saving...' : 'Save Attendance'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ),
          ],
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
              'Failed to load students',
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

  void _markAll(List<Student> students, AttendanceStatus status) {
    setState(() {
      for (final student in students) {
        _attendanceMap[student.id] = status;
      }
    });
  }

  Future<void> _saveAttendance(List<Student> students) async {
    if (_isSaving) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final school = ref.read(currentSchoolProvider);
      if (school == null) {
        throw Exception('No school context available');
      }

      final repo = ref.read(attendanceRepositoryProvider);
      final records = students.map((student) {
        final status = _attendanceMap[student.id] ?? AttendanceStatus.present;
        return {
          'student_id': student.id,
          'status': status.dbValue,
          'notes': _notesMap[student.id]?.trim().isEmpty == true
              ? null
              : _notesMap[student.id]?.trim(),
        };
      }).toList();

      await repo.bulkMarkAttendance(
        schoolId: school.id,
        classId: widget.classId,
        sectionId: widget.sectionId,
        attendanceDate: widget.attendanceDate,
        records: records,
      );

      // Invalidate providers to refresh data
      ref.invalidate(
        classAttendanceProvider(
          ClassAttendanceFilter(
            classId: widget.classId,
            sectionId: widget.sectionId,
            attendanceDate: widget.attendanceDate,
          ),
        ),
      );
      ref.invalidate(
        classAttendanceSummaryProvider(
          ClassAttendanceSummaryFilter(
            classId: widget.classId,
            sectionId: widget.sectionId,
            attendanceDate: widget.attendanceDate,
          ),
        ),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Attendance saved successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save attendance: ${e.toString()}'),
            backgroundColor: Colors.red,
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
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.summary});

  final AttendanceSummary summary;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Attendance Summary',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _SummaryItem(
                  label: 'Total',
                  value: summary.totalStudents.toString(),
                  color: Colors.blue,
                ),
              ),
              Expanded(
                child: _SummaryItem(
                  label: 'Present',
                  value: summary.presentCount.toString(),
                  color: Colors.green,
                ),
              ),
              Expanded(
                child: _SummaryItem(
                  label: 'Absent',
                  value: summary.absentCount.toString(),
                  color: Colors.red,
                ),
              ),
              Expanded(
                child: _SummaryItem(
                  label: 'Unmarked',
                  value: summary.unmarkedCount.toString(),
                  color: Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: summary.totalStudents > 0
                ? summary.markedCount / summary.totalStudents
                : 0,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
          ),
          const SizedBox(height: 4),
          Text(
            '${summary.markedCount}/${summary.totalStudents} marked (${summary.attendancePercentage.toStringAsFixed(1)}% attendance)',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  const _SummaryItem({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
        ),
      ],
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      icon: Icon(icon, size: 18),
      label: Text(label),
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color),
      ),
    );
  }
}

class _StudentAttendanceCard extends StatefulWidget {
  const _StudentAttendanceCard({
    required this.student,
    required this.status,
    required this.notes,
    required this.onStatusChanged,
    required this.onNotesChanged,
  });

  final Student student;
  final AttendanceStatus status;
  final String notes;
  final ValueChanged<AttendanceStatus> onStatusChanged;
  final ValueChanged<String> onNotesChanged;

  @override
  State<_StudentAttendanceCard> createState() => _StudentAttendanceCardState();
}

class _StudentAttendanceCardState extends State<_StudentAttendanceCard> {
  bool _showNotes = false;

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(widget.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.student.fullName,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Admission: ${widget.student.admissionNo}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                // Status Selector
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: statusColor),
                  ),
                  child: DropdownButton<AttendanceStatus>(
                    value: widget.status,
                    underline: const SizedBox.shrink(),
                    iconSize: 20,
                    items: AttendanceStatus.values.map((status) {
                      return DropdownMenuItem(
                        value: status,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _getStatusIcon(status),
                              size: 16,
                              color: _getStatusColor(status),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              status.displayName,
                              style: TextStyle(
                                color: _getStatusColor(status),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (status) {
                      if (status != null) {
                        widget.onStatusChanged(status);
                      }
                    },
                  ),
                ),
              ],
            ),
            // Notes Toggle
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  icon: Icon(
                    _showNotes ? Icons.expand_less : Icons.expand_more,
                    size: 16,
                  ),
                  label: Text(_showNotes ? 'Hide Notes' : 'Add Notes'),
                  onPressed: () {
                    setState(() {
                      _showNotes = !_showNotes;
                    });
                  },
                ),
              ],
            ),
            // Notes Field
            if (_showNotes)
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Notes',
                  border: OutlineInputBorder(),
                  hintText: 'Optional notes...',
                ),
                maxLines: 2,
                onChanged: widget.onNotesChanged,
                controller: TextEditingController(text: widget.notes),
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
