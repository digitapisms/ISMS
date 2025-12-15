import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/messaging_providers.dart';
import '../../domain/announcement.dart';
import '../../domain/messaging_type.dart';
import '../../../authentication/application/auth_providers.dart';

class AnnouncementFormDialog extends ConsumerStatefulWidget {
  const AnnouncementFormDialog({super.key});

  @override
  ConsumerState<AnnouncementFormDialog> createState() => _AnnouncementFormDialogState();
}

class _AnnouncementFormDialogState extends ConsumerState<AnnouncementFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  AnnouncementType _announcementType = AnnouncementType.general;
  Priority _priority = Priority.normal;
  TargetAudience _targetAudience = TargetAudience.all;
  bool _requiresAcknowledgment = false;

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final repo = ref.read(messagingRepositoryProvider);
    final currentUser = ref.read(currentUserProvider).value;
    if (currentUser?.id == null) return;

    final announcement = Announcement(
      id: '',
      schoolId: repo.schoolId ?? '',
      title: _titleController.text.trim(),
      content: _contentController.text.trim(),
      announcementType: _announcementType,
      priority: _priority,
      targetAudience: _targetAudience,
      publishedBy: currentUser!.id,
      isPublished: false,
      requiresAcknowledgment: _requiresAcknowledgment,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    try {
      await repo.createAnnouncement(announcement);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Announcement created successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating announcement: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Create Announcement',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a title';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _contentController,
                  decoration: const InputDecoration(
                    labelText: 'Content',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 5,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter content';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<AnnouncementType>(
                  value: _announcementType,
                  decoration: const InputDecoration(
                    labelText: 'Type',
                    border: OutlineInputBorder(),
                  ),
                  items: AnnouncementType.values.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(type.displayName),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _announcementType = value);
                    }
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<Priority>(
                  value: _priority,
                  decoration: const InputDecoration(
                    labelText: 'Priority',
                    border: OutlineInputBorder(),
                  ),
                  items: Priority.values.map((priority) {
                    return DropdownMenuItem(
                      value: priority,
                      child: Text(priority.displayName),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _priority = value);
                    }
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<TargetAudience>(
                  value: _targetAudience,
                  decoration: const InputDecoration(
                    labelText: 'Target Audience',
                    border: OutlineInputBorder(),
                  ),
                  items: TargetAudience.values.map((audience) {
                    return DropdownMenuItem(
                      value: audience,
                      child: Text(audience.displayName),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _targetAudience = value);
                    }
                  },
                ),
                const SizedBox(height: 16),
                CheckboxListTile(
                  title: const Text('Requires Acknowledgment'),
                  value: _requiresAcknowledgment,
                  onChanged: (value) {
                    setState(() => _requiresAcknowledgment = value ?? false);
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _submit,
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

