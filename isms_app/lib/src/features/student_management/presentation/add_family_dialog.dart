import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/student_providers.dart';

class AddFamilyDialog extends ConsumerStatefulWidget {
  const AddFamilyDialog({super.key, required this.studentId});

  final String studentId;

  @override
  ConsumerState<AddFamilyDialog> createState() => _AddFamilyDialogState();
}

class _AddFamilyDialogState extends ConsumerState<AddFamilyDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _relationController = TextEditingController();
  final _contactController = TextEditingController();
  final _occupationController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _relationController.dispose();
    _contactController.dispose();
    _occupationController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final repo = ref.read(studentRepositoryProvider);
      await repo.addFamilyMember(
        studentId: widget.studentId,
        relation: _relationController.text.trim(),
        name: _nameController.text.trim(),
        contact: _contactController.text.trim().isEmpty
            ? null
            : _contactController.text.trim(),
        occupation: _occupationController.text.trim().isEmpty
            ? null
            : _occupationController.text.trim(),
      );

      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
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
    return AlertDialog(
      title: const Text('Add Family Member'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _relationController,
                decoration: const InputDecoration(
                  labelText: 'Relation',
                  border: OutlineInputBorder(),
                  hintText: 'e.g., Father, Mother, Guardian',
                ),
                validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _contactController,
                decoration: const InputDecoration(
                  labelText: 'Contact',
                  border: OutlineInputBorder(),
                  hintText: 'Phone number or email',
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _occupationController,
                decoration: const InputDecoration(
                  labelText: 'Occupation',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isSubmitting ? null : _submit,
          child: _isSubmitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Add'),
        ),
      ],
    );
  }
}
