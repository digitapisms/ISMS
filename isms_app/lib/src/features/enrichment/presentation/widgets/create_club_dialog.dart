import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/enrichment_providers.dart';
import '../../domain/club.dart';

class CreateClubDialog extends ConsumerStatefulWidget {
  const CreateClubDialog({super.key});

  @override
  ConsumerState<CreateClubDialog> createState() => _CreateClubDialogState();
}

class _CreateClubDialogState extends ConsumerState<CreateClubDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _meetingScheduleController = TextEditingController();
  final _capacityController = TextEditingController();
  final _tagController = TextEditingController();

  ClubStatus _status = ClubStatus.active;
  List<String> _tags = [];
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _meetingScheduleController.dispose();
    _capacityController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  void _addTag() {
    final tag = _tagController.text.trim();
    if (tag.isNotEmpty && !_tags.contains(tag)) {
      setState(() {
        _tags.add(tag);
        _tagController.clear();
      });
    }
  }

  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final repo = ref.read(enrichmentRepositoryProvider);
      await repo.createClub({
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        'meeting_schedule': _meetingScheduleController.text.trim().isEmpty
            ? null
            : _meetingScheduleController.text.trim(),
        'capacity': _capacityController.text.trim().isEmpty
            ? null
            : int.tryParse(_capacityController.text.trim()),
        'tags': _tags,
        'status': _status.name,
      });

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Club created successfully'),
            backgroundColor: Colors.green,
          ),
        );
        // Refresh clubs list
        ref.invalidate(clubsProvider('active'));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: const BoxConstraints(maxWidth: 600),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Create Club',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Club Name *',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a club name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _meetingScheduleController,
                    decoration: const InputDecoration(
                      labelText: 'Meeting Schedule',
                      border: OutlineInputBorder(),
                      helperText: 'e.g., Every Monday 3-4 PM',
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _capacityController,
                    decoration: const InputDecoration(
                      labelText: 'Capacity',
                      border: OutlineInputBorder(),
                      helperText: 'Maximum number of members',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  Text('Tags', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _tagController,
                          decoration: const InputDecoration(
                            labelText: 'Add Tag',
                            border: OutlineInputBorder(),
                            hintText: 'Enter tag and press +',
                          ),
                          onFieldSubmitted: (_) => _addTag(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.add_circle),
                        onPressed: _addTag,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ],
                  ),
                  if (_tags.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: _tags.map((tag) {
                        return Chip(
                          label: Text(tag),
                          onDeleted: () => _removeTag(tag),
                        );
                      }).toList(),
                    ),
                  ],
                  const SizedBox(height: 16),
                  DropdownButtonFormField<ClubStatus>(
                    value: _status,
                    decoration: const InputDecoration(
                      labelText: 'Status',
                      border: OutlineInputBorder(),
                    ),
                    items: ClubStatus.values.map((status) {
                      return DropdownMenuItem(
                        value: status,
                        child: Text(status.name.toUpperCase()),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _status = value;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: _isSubmitting
                            ? null
                            : () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _isSubmitting ? null : _submit,
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Create Club'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
