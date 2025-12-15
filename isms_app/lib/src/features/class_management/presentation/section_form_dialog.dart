import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/class_providers.dart';
import '../domain/section_model.dart';

class SectionFormDialog extends ConsumerStatefulWidget {
  const SectionFormDialog({super.key, required this.classId, this.section});

  final int classId;
  final SectionModel? section;

  @override
  ConsumerState<SectionFormDialog> createState() => _SectionFormDialogState();
}

class _SectionFormDialogState extends ConsumerState<SectionFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _codeController = TextEditingController();
  final _capacityController = TextEditingController();
  bool _isActive = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.section != null) {
      _nameController.text = widget.section!.name;
      _codeController.text = widget.section!.code ?? '';
      _capacityController.text = widget.section!.capacity?.toString() ?? '';
      _isActive = widget.section!.isActive;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _capacityController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final repo = ref.read(classRepositoryProvider);

      if (widget.section == null) {
        // Create new section
        await repo.createSection(
          classId: widget.classId,
          name: _nameController.text.trim(),
          code: _codeController.text.trim().isEmpty
              ? null
              : _codeController.text.trim(),
          capacity: _capacityController.text.trim().isEmpty
              ? null
              : int.tryParse(_capacityController.text.trim()),
          isActive: _isActive,
        );
      } else {
        // Update existing section
        await repo.updateSection(
          id: widget.section!.id,
          name: _nameController.text.trim(),
          code: _codeController.text.trim().isEmpty
              ? null
              : _codeController.text.trim(),
          capacity: _capacityController.text.trim().isEmpty
              ? null
              : int.tryParse(_capacityController.text.trim()),
          isActive: _isActive,
        );
      }

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.section == null
                  ? 'Section created successfully'
                  : 'Section updated successfully',
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
                  widget.section == null ? 'Create Section' : 'Edit Section',
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
                          labelText: 'Section Name *',
                          hintText: 'e.g., A, B, Morning, Afternoon',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Section name is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _codeController,
                        decoration: const InputDecoration(
                          labelText: 'Section Code',
                          hintText: 'e.g., A, B, M, A',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _capacityController,
                        decoration: const InputDecoration(
                          labelText: 'Capacity',
                          hintText: 'Maximum number of students',
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
                      SwitchListTile(
                        title: const Text('Active'),
                        subtitle: const Text(
                          'Inactive sections won\'t appear in dropdowns',
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
                          : Text(widget.section == null ? 'Create' : 'Update'),
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
