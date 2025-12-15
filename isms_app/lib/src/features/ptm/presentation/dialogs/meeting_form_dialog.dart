import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/ptm_providers.dart';
import '../../domain/ptm_meeting.dart';
import '../../../authentication/application/auth_providers.dart';
import '../../../student_management/application/student_providers.dart';

class MeetingFormDialog extends ConsumerStatefulWidget {
  const MeetingFormDialog({super.key});

  @override
  ConsumerState<MeetingFormDialog> createState() => _MeetingFormDialogState();
}

class _MeetingFormDialogState extends ConsumerState<MeetingFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _agendaController = TextEditingController();
  final _locationController = TextEditingController();

  String? _selectedStudentId;
  DateTime _meetingDate = DateTime.now();
  TimeOfDay _meetingTime = TimeOfDay.now();
  int _durationMinutes = 30;
  MeetingType _meetingType = MeetingType.scheduled;

  @override
  void dispose() {
    _agendaController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _selectedStudentId == null) {
      return;
    }

    final repo = ref.read(ptmRepositoryProvider);
    final currentUser = ref.read(currentUserProvider).value;
    if (currentUser?.id == null) return;

    final meetingDateTime = DateTime(
      _meetingDate.year,
      _meetingDate.month,
      _meetingDate.day,
      _meetingTime.hour,
      _meetingTime.minute,
    );

    final meeting = PTMMeeting(
      id: '',
      schoolId: repo.schoolId ?? '',
      studentId: _selectedStudentId!,
      teacherId: currentUser!.id, // TODO: Get actual teacher ID
      meetingDate: meetingDateTime,
      durationMinutes: _durationMinutes,
      meetingType: _meetingType,
      location: _locationController.text.trim().isEmpty
          ? null
          : _locationController.text.trim(),
      agenda: _agendaController.text.trim().isEmpty
          ? null
          : _agendaController.text.trim(),
      scheduledBy: currentUser.id,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    try {
      await repo.createMeeting(meeting);

      if (mounted) {
        Navigator.pop(context);
        ref.invalidate(ptmMeetingsProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Meeting scheduled successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final studentsAsync = ref.watch(studentsProvider);

    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Schedule PTM',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                studentsAsync.when(
                  data: (students) {
                    return DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: 'Student *',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.person),
                      ),
                      items: students.map((student) {
                        return DropdownMenuItem(
                          value: student.id,
                          child: Text('${student.fullName} (${student.admissionNo})'),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() => _selectedStudentId = value);
                      },
                      validator: (value) {
                        if (value == null) {
                          return 'Please select a student';
                        }
                        return null;
                      },
                    );
                  },
                  loading: () => const CircularProgressIndicator(),
                  error: (error, stack) => Text('Error: $error'),
                ),
                const SizedBox(height: 16),
                ListTile(
                  title: const Text('Meeting Date'),
                  subtitle: Text(
                    '${_meetingDate.year}-${_meetingDate.month}-${_meetingDate.day}',
                  ),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _meetingDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) {
                      setState(() => _meetingDate = picked);
                    }
                  },
                ),
                ListTile(
                  title: const Text('Meeting Time'),
                  subtitle: Text(_meetingTime.format(context)),
                  trailing: const Icon(Icons.access_time),
                  onTap: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: _meetingTime,
                    );
                    if (picked != null) {
                      setState(() => _meetingTime = picked);
                    }
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _locationController,
                  decoration: InputDecoration(
                    labelText: 'Location',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.location_on),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _agendaController,
                  decoration: InputDecoration(
                    labelText: 'Agenda',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.notes),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _save,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Schedule'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

