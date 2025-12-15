import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/certificates_providers.dart';
import '../../domain/certificate_template.dart';
import '../../domain/certificate_type.dart';
import '../../../authentication/application/auth_providers.dart';

class TemplateFormDialog extends ConsumerStatefulWidget {
  const TemplateFormDialog({super.key});

  @override
  ConsumerState<TemplateFormDialog> createState() => _TemplateFormDialogState();
}

class _TemplateFormDialogState extends ConsumerState<TemplateFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _contentController = TextEditingController();
  CertificateType _certificateType = CertificateType.leaving;
  TemplateType _templateType = TemplateType.student;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final repo = ref.read(certificatesRepositoryProvider);
    final currentUser = ref.read(currentUserProvider).value;
    if (currentUser?.id == null) return;

    final template = CertificateTemplate(
      id: '',
      schoolId: repo.schoolId ?? '',
      templateName: _nameController.text.trim(),
      certificateType: _certificateType,
      templateType: _templateType,
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      templateContent: _contentController.text.trim(),
      templateVariables: _extractVariables(_contentController.text),
      isActive: true,
      createdBy: currentUser!.id,
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
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  List<String> _extractVariables(String content) {
    final pattern = RegExp(r'\{(\w+)\}');
    return pattern
        .allMatches(content)
        .map((match) => match.group(1)!)
        .toSet()
        .toList();
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
                  'Create Certificate Template',
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
                DropdownButtonFormField<CertificateType>(
                  initialValue: _certificateType,
                  decoration: const InputDecoration(
                    labelText: 'Certificate Type',
                    border: OutlineInputBorder(),
                  ),
                  items: CertificateType.values.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(type.displayName),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _certificateType = value);
                    }
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<TemplateType>(
                  initialValue: _templateType,
                  decoration: const InputDecoration(
                    labelText: 'Template Type',
                    border: OutlineInputBorder(),
                  ),
                  items: TemplateType.values.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(type.displayName),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _templateType = value);
                    }
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description (Optional)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _contentController,
                  decoration: const InputDecoration(
                    labelText: 'Template Content (Use {variable_name} for placeholders)',
                    border: OutlineInputBorder(),
                    helperText: 'Example: This is to certify that {student_name}...',
                  ),
                  maxLines: 10,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter template content';
                    }
                    return null;
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

