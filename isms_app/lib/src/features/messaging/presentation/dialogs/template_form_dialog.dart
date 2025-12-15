import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/messaging_providers.dart';
import '../../domain/message_template.dart';
import '../../domain/messaging_type.dart';
import '../../../authentication/application/auth_providers.dart';

class TemplateFormDialog extends ConsumerStatefulWidget {
  const TemplateFormDialog({super.key});

  @override
  ConsumerState<TemplateFormDialog> createState() => _TemplateFormDialogState();
}

class _TemplateFormDialogState extends ConsumerState<TemplateFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _subjectController = TextEditingController();
  final _contentController = TextEditingController();
  TemplateCategory? _category;

  @override
  void dispose() {
    _nameController.dispose();
    _subjectController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final repo = ref.read(messagingRepositoryProvider);
    final currentUser = ref.read(currentUserProvider).value;

    // Extract variables from content (e.g., {student_name}, {date})
    final content = _contentController.text.trim();
    final variablePattern = RegExp(r'\{(\w+)\}');
    final variables = variablePattern
        .allMatches(content)
        .map((match) => match.group(1)!)
        .toSet()
        .toList();

    final template = MessageTemplate(
      id: '',
      schoolId: repo.schoolId ?? '',
      templateName: _nameController.text.trim(),
      templateCategory: _category,
      subject: _subjectController.text.trim().isEmpty
          ? null
          : _subjectController.text.trim(),
      content: content,
      variables: variables.isEmpty ? null : variables,
      isActive: true,
      createdBy: currentUser?.id,
      usageCount: 0,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    try {
      await repo.createTemplate(template);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Template created successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating template: $e')),
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
                  'Create Message Template',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Template Name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a template name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _subjectController,
                  decoration: const InputDecoration(
                    labelText: 'Subject (Optional)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _contentController,
                  decoration: const InputDecoration(
                    labelText: 'Content (Use {variable_name} for placeholders)',
                    border: OutlineInputBorder(),
                    helperText: 'Example: Hello {student_name}, your fee is due on {date}',
                  ),
                  maxLines: 8,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter content';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<TemplateCategory>(
                  initialValue: _category,
                  decoration: const InputDecoration(
                    labelText: 'Category (Optional)',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem<TemplateCategory>(
                      value: null,
                      child: Text('None'),
                    ),
                    ...TemplateCategory.values.map((category) {
                      return DropdownMenuItem(
                        value: category,
                        child: Text(category.displayName),
                      );
                    }),
                  ],
                  onChanged: (value) {
                    setState(() => _category = value);
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

