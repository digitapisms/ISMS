import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/timetable_providers.dart';
import '../../domain/period.dart';
import '../../../school_registration/application/school_providers.dart';

class PeriodFormDialog extends ConsumerStatefulWidget {
  const PeriodFormDialog({super.key, this.period});

  final Period? period;

  @override
  ConsumerState<PeriodFormDialog> createState() => _PeriodFormDialogState();
}

class _PeriodFormDialogState extends ConsumerState<PeriodFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  PeriodType _periodType = PeriodType.regular;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  int _displayOrder = 0;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.period != null) {
      final period = widget.period!;
      _nameController.text = period.name;
      _periodType = period.periodType;
      _startTime = TimeOfDay.fromDateTime(period.startTime);
      _endTime = TimeOfDay.fromDateTime(period.endTime);
      _displayOrder = period.displayOrder;
    } else {
      _startTime = const TimeOfDay(hour: 8, minute: 0);
      _endTime = const TimeOfDay(hour: 8, minute: 45);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_startTime == null || _endTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select start and end times')),
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
      final startDateTime = DateTime(
        2000,
        1,
        1,
        _startTime!.hour,
        _startTime!.minute,
      );
      final endDateTime = DateTime(
        2000,
        1,
        1,
        _endTime!.hour,
        _endTime!.minute,
      );

      if (widget.period == null) {
        await repo.createPeriod(
          schoolId: school.id,
          name: _nameController.text.trim(),
          startTime: startDateTime,
          endTime: endDateTime,
          periodType: _periodType,
          displayOrder: _displayOrder,
        );
      } else {
        await repo.updatePeriod(
          id: widget.period!.id,
          name: _nameController.text.trim(),
          startTime: startDateTime,
          endTime: endDateTime,
          periodType: _periodType,
          displayOrder: _displayOrder,
        );
      }

      if (mounted) {
        ref.invalidate(periodsProvider);
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.period == null
                  ? 'Period created successfully'
                  : 'Period updated successfully',
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
                  widget.period == null ? 'Add Period' : 'Edit Period',
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
                        labelText: 'Period Name *',
                        hintText: 'e.g., Period 1, Recess, Lunch',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.access_time),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Period name is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<PeriodType>(
                      decoration: const InputDecoration(
                        labelText: 'Period Type *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.category),
                      ),
                      value: _periodType,
                      items: PeriodType.values.map((type) {
                        return DropdownMenuItem(
                          value: type,
                          child: Text(type.dbValue),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _periodType = value;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final time = await showTimePicker(
                                context: context,
                                initialTime: _startTime ?? TimeOfDay.now(),
                              );
                              if (time != null) {
                                setState(() {
                                  _startTime = time;
                                });
                              }
                            },
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Start Time *',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.schedule),
                              ),
                              child: Text(
                                _startTime != null
                                    ? _startTime!.format(context)
                                    : 'Select start time',
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final time = await showTimePicker(
                                context: context,
                                initialTime: _endTime ?? TimeOfDay.now(),
                              );
                              if (time != null) {
                                setState(() {
                                  _endTime = time;
                                });
                              }
                            },
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'End Time *',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.schedule),
                              ),
                              child: Text(
                                _endTime != null
                                    ? _endTime!.format(context)
                                    : 'Select end time',
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      initialValue: _displayOrder.toString(),
                      decoration: const InputDecoration(
                        labelText: 'Display Order',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.sort),
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        _displayOrder = int.tryParse(value) ?? 0;
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
                          : Text(widget.period == null ? 'Create' : 'Update'),
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
