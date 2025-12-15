import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/discipline_providers.dart';
import '../../domain/discipline_action.dart';
import '../../../authentication/application/auth_providers.dart';

class ActionFormDialog extends ConsumerStatefulWidget {
  final String incidentId;
  final String studentId;

  const ActionFormDialog({
    super.key,
    required this.incidentId,
    required this.studentId,
  });

  @override
  ConsumerState<ActionFormDialog> createState() => _ActionFormDialogState();
}

class _ActionFormDialogState extends ConsumerState<ActionFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _notesController = TextEditingController();
  final _durationController = TextEditingController();

  ActionType _actionType = ActionType.warning;
  DateTime _actionDate = DateTime.now();
  DateTime? _startDate;
  DateTime? _endDate;
  bool _followUpRequired = false;
  DateTime? _followUpDate;

  @override
  void dispose() {
    _descriptionController.dispose();
    _notesController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final repo = ref.read(disciplineRepositoryProvider);
    final currentUser = ref.read(currentUserProvider).value;
    if (currentUser?.id == null) return;

    final action = DisciplineAction(
      id: '',
      schoolId: repo.schoolId ?? '',
      incidentId: widget.incidentId,
      studentId: widget.studentId,
      actionType: _actionType,
      actionDate: _actionDate,
      description: _descriptionController.text.trim(),
      durationDays: _durationController.text.trim().isEmpty
          ? null
          : int.tryParse(_durationController.text.trim()),
      startDate: _startDate,
      endDate: _endDate,
      assignedBy: currentUser!.id,
      followUpRequired: _followUpRequired,
      followUpDate: _followUpDate,
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    try {
      await repo.createAction(action);

      if (mounted) {
        Navigator.pop(context);
        ref.invalidate(disciplineActionsProvider(widget.incidentId));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Action created successfully')),
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
                const Text(
                  'Add Disciplinary Action',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<ActionType>(
                  value: _actionType,
                  decoration: InputDecoration(
                    labelText: 'Action Type *',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: ActionType.values.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(type.displayName),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _actionType = value);
                    }
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  decoration: InputDecoration(
                    labelText: 'Description *',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  maxLines: 3,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter description';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                ListTile(
                  title: const Text('Action Date'),
                  subtitle: Text(
                    '${_actionDate.year}-${_actionDate.month}-${_actionDate.day}',
                  ),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _actionDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) {
                      setState(() => _actionDate = picked);
                    }
                  },
                ),
                if (_actionType == ActionType.suspension ||
                    _actionType == ActionType.detention) ...[
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _durationController,
                    decoration: InputDecoration(
                      labelText: 'Duration (Days)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ],
                const SizedBox(height: 16),
                CheckboxListTile(
                  title: const Text('Follow-up Required'),
                  value: _followUpRequired,
                  onChanged: (value) {
                    setState(() => _followUpRequired = value ?? false);
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _notesController,
                  decoration: InputDecoration(
                    labelText: 'Notes',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  maxLines: 2,
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
                      child: const Text('Create'),
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

