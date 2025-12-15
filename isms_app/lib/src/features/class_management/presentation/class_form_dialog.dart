import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/class_providers.dart';
import '../domain/class_model.dart';

class ClassFormDialog extends ConsumerStatefulWidget {
  const ClassFormDialog({super.key, this.classModel});

  final ClassModel? classModel;

  @override
  ConsumerState<ClassFormDialog> createState() => _ClassFormDialogState();
}

class _ClassFormDialogState extends ConsumerState<ClassFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _codeController = TextEditingController();
  final _levelController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isActive = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.classModel != null) {
      _nameController.text = widget.classModel!.name;
      _codeController.text = widget.classModel!.code ?? '';
      _levelController.text = widget.classModel!.level?.toString() ?? '';
      _descriptionController.text = widget.classModel!.description ?? '';
      _isActive = widget.classModel!.isActive;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _levelController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final repo = ref.read(classRepositoryProvider);

      if (widget.classModel == null) {
        // Create new class
        await repo.createClass(
          name: _nameController.text.trim(),
          code: _codeController.text.trim().isEmpty
              ? null
              : _codeController.text.trim(),
          level: _levelController.text.trim().isEmpty
              ? null
              : int.tryParse(_levelController.text.trim()),
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          isActive: _isActive,
        );
      } else {
        // Update existing class
        await repo.updateClass(
          id: widget.classModel!.id,
          name: _nameController.text.trim(),
          code: _codeController.text.trim().isEmpty
              ? null
              : _codeController.text.trim(),
          level: _levelController.text.trim().isEmpty
              ? null
              : int.tryParse(_levelController.text.trim()),
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          isActive: _isActive,
        );
      }

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.classModel == null
                  ? 'Class created successfully'
                  : 'Class updated successfully',
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
                  widget.classModel == null ? 'Create Class' : 'Edit Class',
                ),
                automaticallyImplyLeading: false,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Class Name *',
                          hintText: 'e.g., Grade 1, Class 1, Year 1',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Class name is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _codeController,
                        decoration: const InputDecoration(
                          labelText: 'Class Code',
                          hintText: 'e.g., G1, C1, Y1',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _levelController,
                        decoration: const InputDecoration(
                          labelText: 'Level',
                          hintText: 'e.g., 1, 2, 3',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value != null &&
                              value.trim().isNotEmpty &&
                              int.tryParse(value.trim()) == null) {
                            return 'Please enter a valid number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                          hintText: 'Optional description',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 16),
                      SwitchListTile(
                        title: const Text('Active'),
                        subtitle: const Text(
                          'Inactive classes won\'t appear in dropdowns',
                        ),
                        value: _isActive,
                        onChanged: (value) {
                          setState(() {
                            _isActive = value;
                          });
                        },
                      ),
                    ],
                  ),
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
                          : Text(
                              widget.classModel == null ? 'Create' : 'Update',
                            ),
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
