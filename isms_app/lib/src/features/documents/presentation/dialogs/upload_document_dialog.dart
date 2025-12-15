import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';

import '../../application/documents_providers.dart';

class UploadDocumentDialog extends ConsumerStatefulWidget {
  const UploadDocumentDialog({super.key});

  @override
  ConsumerState<UploadDocumentDialog> createState() => _UploadDocumentDialogState();
}

class _UploadDocumentDialogState extends ConsumerState<UploadDocumentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _documentTypeController = TextEditingController();

  FilePickerResult? _fileResult;
  bool _isPublic = false;
  bool _isUploading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _documentTypeController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.any,
      allowMultiple: false,
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        _fileResult = result;
        if (_titleController.text.isEmpty) {
          _titleController.text = result.files.single.name;
        }
      });
    }
  }

  Future<void> _upload() async {
    if (!_formKey.currentState!.validate() || _fileResult == null) {
      return;
    }

    setState(() => _isUploading = true);

    try {
      final repo = ref.read(documentsRepositoryProvider);
      final file = File(_fileResult!.files.single.path!);

      await repo.uploadDocument(
        title: _titleController.text.trim(),
        file: file,
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        documentType: _documentTypeController.text.trim().isEmpty
            ? null
            : _documentTypeController.text.trim(),
        accessLevel: _isPublic ? 'public' : 'private',
      );

      if (mounted) {
        Navigator.pop(context);
        ref.invalidate(documentsProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Document uploaded successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
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
                  'Upload Document',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _pickFile,
                  icon: const Icon(Icons.attach_file),
                  label: Text(_fileResult == null
                      ? 'Select File'
                      : _fileResult!.files.single.name),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    labelText: 'Title *',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.title),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter title';
                    }
                    return null;
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
                TextFormField(
                  controller: _documentTypeController,
                  decoration: InputDecoration(
                    labelText: 'Document Type',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.category),
                    hintText: 'e.g., academic, administrative',
                  ),
                ),
                const SizedBox(height: 16),
                CheckboxListTile(
                  title: const Text('Make Public'),
                  subtitle: const Text('Visible to all school users'),
                  value: _isPublic,
                  onChanged: (value) {
                    setState(() => _isPublic = value ?? false);
                  },
                ),
                const SizedBox(height: 24),
                if (_isUploading)
                  const Center(child: CircularProgressIndicator()),
                if (!_isUploading)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _upload,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Upload'),
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

