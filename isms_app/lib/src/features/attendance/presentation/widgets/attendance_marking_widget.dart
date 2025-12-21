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
  /// User edits only (do not preload from DB to avoid init/race loops).
  final Map<String, AttendanceStatus> _statusOverrides = {};
  final Map<String, String> _notesOverrides = {};
  bool _isSaving = false;
  bool _useExistingValues = true;
  String _filterKey = '';

  @override
  void didUpdateWidget(covariant AttendanceMarkingWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    final nextKey = _computeFilterKey(
      classId: widget.classId,
      sectionId: widget.sectionId,
      date: widget.attendanceDate,
    );

    // If the user changes class/section/date, don't leak previous overrides.
    if (_filterKey.isNotEmpty && _filterKey != nextKey) {
      setState(() {
        _statusOverrides.clear();
        _notesOverrides.clear();
        _useExistingValues = true;
        _filterKey = nextKey;
      });
    }
  }

  String _computeFilterKey({
    required int classId,
    required int? sectionId,
    required DateTime date,
  }) {
    // Keep it stable and date-only (matches DB date storage).
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$classId:${sectionId ?? 'all'}:$y-$m-$d';
  }

  @override
  Widget build(BuildContext context) {
    _filterKey = _computeFilterKey(
      classId: widget.classId,
      sectionId: widget.sectionId,
      date: widget.attendanceDate,
    );

    final filter = AttendanceMarkingDataFilter(
      classId: widget.classId,
      sectionId: widget.sectionId,
      attendanceDate: widget.attendanceDate,
    );

    final dataAsync = ref.watch(attendanceMarkingDataProvider(filter));

    return dataAsync.when(
      data: (data) {
        final students = data.students;
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
                const SizedBox(height: 8),
                Text(
                  'Please check if students are enrolled in this class/section',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.grey[500]),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        final existingByStudentId = data.existingByStudentId;

        return Column(
          children: [
            if (data.warning != null)
              Container(
                margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange[200]!),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.orange[700],
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        data.warning!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.orange[900],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            if (data.summary != null) _SummaryCard(summary: data.summary!),

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
                        _statusOverrides.clear();
                        _notesOverrides.clear();
                        _useExistingValues = false;
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
                  final existing = existingByStudentId[student.id];
                  final existingStatus = existing?.status;
                  final existingNotes = existing?.notes ?? '';

                  final status =
                      _statusOverrides[student.id] ??
                      (_useExistingValues
                          ? (existingStatus ?? AttendanceStatus.present)
                          : AttendanceStatus.present);
                  final notes =
                      _notesOverrides[student.id] ??
                      (_useExistingValues ? existingNotes : '');

                  return _StudentAttendanceCard(
                    student: student,
                    status: status,
                    notes: notes,
                    onStatusChanged: (newStatus) {
                      setState(() {
                        _statusOverrides[student.id] = newStatus;
                        _useExistingValues = false;
                      });
                    },
                    onNotesChanged: (notes) {
                      setState(() {
                        _notesOverrides[student.id] = notes;
                        _useExistingValues = false;
                      });
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
      loading: () => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'Loading attendance…',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
      error: (error, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
              const SizedBox(height: 16),
              Text(
                'Unable to load attendance',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                _getErrorMessage(error),
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _statusOverrides.clear();
                    _notesOverrides.clear();
                    _useExistingValues = true;
                  });
                  ref.invalidate(attendanceMarkingDataProvider(filter));
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getErrorMessage(Object error) {
    final errorString = error.toString().toLowerCase();
    if (errorString.contains('network') || errorString.contains('connection')) {
      return 'Network error. Please check your internet connection and try again.';
    } else if (errorString.contains('timeout')) {
      return 'Request timed out. Please try again.';
    } else if (errorString.contains('permission') ||
        errorString.contains('unauthorized')) {
      return 'You do not have permission to view this data.';
    } else {
      return 'An error occurred while loading students. Please try again.';
    }
  }

  void _markAll(List<Student> students, AttendanceStatus status) {
    setState(() {
      for (final student in students) {
        _statusOverrides[student.id] = status;
      }
      _useExistingValues = false;
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
        final status = _statusOverrides[student.id] ?? AttendanceStatus.present;
        final notesValue = _notesOverrides[student.id];
        return {
          'student_id': student.id,
          'status': status.dbValue,
          'notes': (notesValue?.trim().isNotEmpty ?? false)
              ? notesValue!.trim()
              : null,
        };
      }).toList();

      await repo.bulkMarkAttendance(
        schoolId: school.id,
        classId: widget.classId,
        sectionId: widget.sectionId,
        attendanceDate: widget.attendanceDate,
        records: records,
      );

      // Refresh the composite provider (single source of truth for this screen).
      ref.invalidate(
        attendanceMarkingDataProvider(
          AttendanceMarkingDataFilter(
            classId: widget.classId,
            sectionId: widget.sectionId,
            attendanceDate: widget.attendanceDate,
          ),
        ),
      );

      // Reset local overrides so UI reflects the freshly loaded DB state.
      if (mounted) {
        setState(() {
          _statusOverrides.clear();
          _notesOverrides.clear();
          _useExistingValues = true;
        });
      }

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
