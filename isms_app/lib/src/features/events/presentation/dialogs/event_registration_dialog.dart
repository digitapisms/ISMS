import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/events_providers.dart';
import '../../domain/event.dart';
import '../../../student_management/application/student_providers.dart';

class EventRegistrationDialog extends ConsumerStatefulWidget {
  final Event event;

  const EventRegistrationDialog({
    super.key,
    required this.event,
  });

  @override
  ConsumerState<EventRegistrationDialog> createState() =>
      _EventRegistrationDialogState();
}

class _EventRegistrationDialogState
    extends ConsumerState<EventRegistrationDialog> {
  String? _selectedStudentId;
  final _notesController = TextEditingController();

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (_selectedStudentId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a student')),
      );
      return;
    }

    final repo = ref.read(eventsRepositoryProvider);
    try {
      await repo.registerForEvent(
        eventId: widget.event.id,
        studentId: _selectedStudentId!,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );

      if (mounted) {
        Navigator.pop(context);
        ref.invalidate(eventRegistrationsProvider(widget.event.id));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registered successfully')),
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
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Register for Event',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            studentsAsync.when(
              data: (students) {
                return DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: 'Select Student *',
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
                );
              },
              loading: () => const CircularProgressIndicator(),
              error: (error, stack) => Text('Error: $error'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesController,
              decoration: InputDecoration(
                labelText: 'Notes (Optional)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
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
                  onPressed: _register,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Register'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

