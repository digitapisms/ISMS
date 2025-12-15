import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/timetable_providers.dart';
import '../../domain/timetable.dart';
import '../../domain/timetable_entry.dart';
import '../../../authentication/domain/user_role.dart';
import '../../../examination/application/examination_providers.dart';
import '../../../school_registration/application/school_providers.dart';
import '../../../staff_management/application/staff_providers.dart';

class TimetableEntryFormDialog extends ConsumerStatefulWidget {
  const TimetableEntryFormDialog({
    super.key,
    required this.timetable,
    this.entry,
    this.dayOfWeek,
    this.periodId,
  });

  final Timetable timetable;
  final TimetableEntry? entry;
  final int? dayOfWeek;
  final int? periodId;

  @override
  ConsumerState<TimetableEntryFormDialog> createState() =>
      _TimetableEntryFormDialogState();
}

class _TimetableEntryFormDialogState
    extends ConsumerState<TimetableEntryFormDialog> {
  int? _selectedDayOfWeek;
  int? _selectedPeriodId;
  int? _selectedSubjectId;
  String? _selectedTeacherId;
  int? _selectedRoomId;
  final _notesController = TextEditingController();
  bool _isSubstitute = false;
  String? _selectedSubstituteTeacherId;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.entry != null) {
      final entry = widget.entry!;
      _selectedDayOfWeek = entry.dayOfWeek;
      _selectedPeriodId = entry.periodId;
      _selectedSubjectId = entry.subjectId;
      _selectedTeacherId = entry.teacherId;
      _selectedRoomId = entry.roomId;
      _notesController.text = entry.notes ?? '';
      _isSubstitute = entry.isSubstitute;
      _selectedSubstituteTeacherId = entry.substituteTeacherId;
    } else {
      _selectedDayOfWeek = widget.dayOfWeek;
      _selectedPeriodId = widget.periodId;
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_selectedDayOfWeek == null || _selectedPeriodId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select day and period')),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final school = ref.read(currentSchoolProvider);
      if (school == null) throw Exception('School not found');

      final repo = ref.read(timetableRepositoryProvider);

      if (widget.entry == null) {
        await repo.createTimetableEntry(
          schoolId: school.id,
          timetableId: widget.timetable.id,
          dayOfWeek: _selectedDayOfWeek!,
          periodId: _selectedPeriodId!,
          subjectId: _selectedSubjectId,
          teacherId: _selectedTeacherId,
          roomId: _selectedRoomId,
          notes: _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
          isSubstitute: _isSubstitute,
          substituteTeacherId: _selectedSubstituteTeacherId,
        );
      } else {
        await repo.updateTimetableEntry(
          id: widget.entry!.id,
          subjectId: _selectedSubjectId,
          teacherId: _selectedTeacherId,
          roomId: _selectedRoomId,
          notes: _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
          isSubstitute: _isSubstitute,
          substituteTeacherId: _selectedSubstituteTeacherId,
        );
      }

      if (mounted) {
        ref.invalidate(timetableEntriesProvider(widget.timetable.id));
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.entry == null
                  ? 'Entry created successfully'
                  : 'Entry updated successfully',
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
    final subjectsAsync = ref.watch(subjectsProvider);
    final roomsAsync = ref.watch(roomsProvider);
    final periodsAsync = ref.watch(periodsProvider);

    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Form(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppBar(
                title: Text(
                  widget.entry == null
                      ? 'Add Timetable Entry'
                      : 'Edit Timetable Entry',
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
                      if (widget.entry == null) ...[
                        DropdownButtonFormField<int>(
                          decoration: const InputDecoration(
                            labelText: 'Day of Week *',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.calendar_today),
                          ),
                          value: _selectedDayOfWeek,
                          items: [
                            for (int i = 1; i <= 7; i++)
                              DropdownMenuItem(
                                value: i,
                                child: Text(_getDayName(i)),
                              ),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _selectedDayOfWeek = value;
                            });
                          },
                        ),
                        const SizedBox(height: 16),
                        periodsAsync.when(
                          data: (periods) => DropdownButtonFormField<int>(
                            decoration: const InputDecoration(
                              labelText: 'Period *',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.access_time),
                            ),
                            value: _selectedPeriodId,
                            items: periods.where((p) => p.isActive).map((
                              period,
                            ) {
                              return DropdownMenuItem(
                                value: period.id,
                                child: Text(
                                  '${period.name} (${period.timeRange})',
                                ),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedPeriodId = value;
                              });
                            },
                          ),
                          loading: () => const LinearProgressIndicator(),
                          error: (_, __) => const Text('Error'),
                        ),
                        const SizedBox(height: 16),
                      ],
                      subjectsAsync.when(
                        data: (subjects) => DropdownButtonFormField<int>(
                          decoration: const InputDecoration(
                            labelText: 'Subject',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.subject),
                          ),
                          value: _selectedSubjectId,
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
                      const SizedBox(height: 16),
                      ref
                          .watch(
                            staffListProvider((
                              query: null,
                              role: null,
                              status: 'active',
                            )),
                          )
                          .when(
                            data: (staff) {
                              final teachers = staff
                                  .where((s) => s.role == UserRole.teacher)
                                  .toList();
                              return DropdownButtonFormField<String>(
                                decoration: const InputDecoration(
                                  labelText: 'Teacher',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.person),
                                ),
                                value: _selectedTeacherId,
                                items: teachers.map((teacher) {
                                  return DropdownMenuItem(
                                    value: teacher.id,
                                    child: Text(
                                      teacher.fullName ?? teacher.email,
                                    ),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    _selectedTeacherId = value;
                                  });
                                },
                              );
                            },
                            loading: () => const LinearProgressIndicator(),
                            error: (_, __) => const Text('Error'),
                          ),
                      const SizedBox(height: 16),
                      roomsAsync.when(
                        data: (rooms) => DropdownButtonFormField<int>(
                          decoration: const InputDecoration(
                            labelText: 'Room',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.meeting_room),
                          ),
                          value: _selectedRoomId,
                          items: rooms.map((room) {
                            return DropdownMenuItem(
                              value: room.id,
                              child: Text(room.name),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedRoomId = value;
                            });
                          },
                        ),
                        loading: () => const LinearProgressIndicator(),
                        error: (_, __) => const Text('Error'),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _notesController,
                        decoration: const InputDecoration(
                          labelText: 'Notes',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.note),
                        ),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 16),
                      SwitchListTile(
                        title: const Text('Substitute Teacher'),
                        value: _isSubstitute,
                        onChanged: (value) {
                          setState(() {
                            _isSubstitute = value;
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
                          : Text(widget.entry == null ? 'Create' : 'Update'),
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

  String _getDayName(int dayOfWeek) {
    switch (dayOfWeek) {
      case 1:
        return 'Monday';
      case 2:
        return 'Tuesday';
      case 3:
        return 'Wednesday';
      case 4:
        return 'Thursday';
      case 5:
        return 'Friday';
      case 6:
        return 'Saturday';
      case 7:
        return 'Sunday';
      default:
        return 'Unknown';
    }
  }
}
