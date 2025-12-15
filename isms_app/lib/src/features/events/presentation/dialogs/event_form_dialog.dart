import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../application/events_providers.dart';
import '../../domain/event.dart';
import '../../domain/event_type.dart';
import '../../../authentication/application/auth_providers.dart';

class EventFormDialog extends ConsumerStatefulWidget {
  final Event? event;

  const EventFormDialog({
    super.key,
    this.event,
  });

  @override
  ConsumerState<EventFormDialog> createState() => _EventFormDialogState();
}

class _EventFormDialogState extends ConsumerState<EventFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _startTimeController = TextEditingController();
  final _endTimeController = TextEditingController();
  final _maxParticipantsController = TextEditingController();

  EventType _eventType = EventType.other;
  DateTime _startDate = DateTime.now();
  DateTime? _endDate;
  DateTime? _registrationDeadline;
  bool _isAllDay = false;
  bool _requiresRegistration = false;
  int? _maxParticipants;
  EventStatus _status = EventStatus.draft;

  @override
  void initState() {
    super.initState();
    if (widget.event != null) {
      _titleController.text = widget.event!.title;
      _descriptionController.text = widget.event!.description ?? '';
      _locationController.text = widget.event!.location ?? '';
      _startTimeController.text = widget.event!.startTime ?? '';
      _endTimeController.text = widget.event!.endTime ?? '';
      _eventType = widget.event!.eventType;
      _startDate = widget.event!.startDate;
      _endDate = widget.event!.endDate;
      _registrationDeadline = widget.event!.registrationDeadline;
      _isAllDay = widget.event!.isAllDay;
      _requiresRegistration = widget.event!.requiresRegistration;
      _maxParticipants = widget.event!.maxParticipants;
      _status = widget.event!.status;
      if (_maxParticipants != null) {
        _maxParticipantsController.text = _maxParticipants.toString();
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _startTimeController.dispose();
    _endTimeController.dispose();
    _maxParticipantsController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final repo = ref.read(eventsRepositoryProvider);
    final currentUser = ref.read(currentUserProvider).value;
    if (currentUser?.id == null) return;

    final event = Event(
      id: widget.event?.id ?? '',
      schoolId: repo.schoolId ?? '',
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      eventType: _eventType,
      startDate: _startDate,
      endDate: _endDate,
      startTime: _isAllDay ? null : _startTimeController.text.trim().isEmpty
          ? null
          : _startTimeController.text.trim(),
      endTime: _isAllDay ? null : _endTimeController.text.trim().isEmpty
          ? null
          : _endTimeController.text.trim(),
      location: _locationController.text.trim().isEmpty
          ? null
          : _locationController.text.trim(),
      requiresRegistration: _requiresRegistration,
      maxParticipants: _maxParticipantsController.text.trim().isEmpty
          ? null
          : int.tryParse(_maxParticipantsController.text.trim()),
      registrationDeadline: _registrationDeadline,
      status: _status,
      isAllDay: _isAllDay,
      createdBy: currentUser!.id,
      createdAt: widget.event?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    try {
      if (widget.event == null) {
        await repo.createEvent(event);
      } else {
        await repo.updateEvent(event);
      }

      if (mounted) {
        Navigator.pop(context);
        ref.invalidate(eventsProvider);
        ref.invalidate(upcomingEventsProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.event == null
                  ? 'Event created successfully'
                  : 'Event updated successfully',
            ),
          ),
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
                Text(
                  widget.event == null ? 'Create Event' : 'Edit Event',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    labelText: 'Event Title *',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.title),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter event title';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<EventType>(
                  value: _eventType,
                  decoration: InputDecoration(
                    labelText: 'Event Type *',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: Icon(_eventType.icon),
                  ),
                  items: EventType.values.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Row(
                        children: [
                          Icon(type.icon, color: type.color, size: 20),
                          const SizedBox(width: 8),
                          Text(type.displayName),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _eventType = value);
                    }
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  decoration: InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.description),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                ListTile(
                  title: const Text('Start Date *'),
                  subtitle: Text(DateFormat('MMM d, y').format(_startDate)),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _startDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) {
                      setState(() => _startDate = picked);
                    }
                  },
                ),
                const SizedBox(height: 16),
                CheckboxListTile(
                  title: const Text('All Day Event'),
                  value: _isAllDay,
                  onChanged: (value) {
                    setState(() => _isAllDay = value ?? false);
                  },
                ),
                if (!_isAllDay) ...[
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _startTimeController,
                    decoration: InputDecoration(
                      labelText: 'Start Time',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.access_time),
                    ),
                    onTap: () async {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.now(),
                      );
                      if (time != null) {
                        _startTimeController.text =
                            '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _endTimeController,
                    decoration: InputDecoration(
                      labelText: 'End Time',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.access_time),
                    ),
                    onTap: () async {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.now(),
                      );
                      if (time != null) {
                        _endTimeController.text =
                            '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
                      }
                    },
                  ),
                ],
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
                CheckboxListTile(
                  title: const Text('Requires Registration'),
                  value: _requiresRegistration,
                  onChanged: (value) {
                    setState(() => _requiresRegistration = value ?? false);
                  },
                ),
                if (_requiresRegistration) ...[
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _maxParticipantsController,
                    decoration: InputDecoration(
                      labelText: 'Max Participants',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.people),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ],
                const SizedBox(height: 16),
                DropdownButtonFormField<EventStatus>(
                  value: _status,
                  decoration: InputDecoration(
                    labelText: 'Status',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: EventStatus.values.map((status) {
                    return DropdownMenuItem(
                      value: status,
                      child: Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: status.color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(status.displayName),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _status = value);
                    }
                  },
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
                      child: Text(widget.event == null ? 'Create' : 'Update'),
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

