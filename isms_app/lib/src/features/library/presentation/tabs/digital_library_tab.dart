import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';

import '../../../authentication/application/auth_providers.dart';
import '../../../authentication/domain/user_role.dart';
import '../../application/library_providers.dart';
import '../../domain/book_type.dart';
import '../widgets/digital_resource_item.dart';

class DigitalLibraryTab extends ConsumerStatefulWidget {
  const DigitalLibraryTab({super.key});

  @override
  ConsumerState<DigitalLibraryTab> createState() => _DigitalLibraryTabState();
}

class _DigitalLibraryTabState extends ConsumerState<DigitalLibraryTab> {
  DigitalResourceType? _selectedType;

  @override
  Widget build(BuildContext context) {
    final authUser = ref.watch(authStateProvider);
    final isAdmin =
        authUser?.role == UserRole.admin ||
        authUser?.role == UserRole.principal;
    final isTeacher = authUser?.role == UserRole.teacher;
    final canUpload = isAdmin || isTeacher;

    final resourcesAsync = ref.watch(digitalResourcesProvider);

    return Column(
      children: [
        if (canUpload)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<DigitalResourceType?>(
                    initialValue: _selectedType,
                    decoration: InputDecoration(
                      labelText: 'Filter by Type',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    items: [
                      const DropdownMenuItem<DigitalResourceType?>(
                        value: null,
                        child: Text('All Types'),
                      ),
                      ...DigitalResourceType.values.map(
                        (type) => DropdownMenuItem<DigitalResourceType?>(
                          value: type,
                          child: Text(type.displayName),
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() => _selectedType = value);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _uploadResource,
                  icon: const Icon(Icons.upload_file),
                  label: const Text('Upload Resource'),
                ),
              ],
            ),
          ),
        Expanded(
          child: resourcesAsync.when(
            data: (resources) {
              final filtered = _selectedType == null
                  ? resources
                  : resources
                        .where((r) => r.resourceType == _selectedType)
                        .toList();

              if (filtered.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.library_books_outlined,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No digital resources found',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                );
              }

              return GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.7,
                ),
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  return DigitalResourceItem(resource: filtered[index]);
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading resources',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    error.toString(),
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _uploadResource() async {
    final libraryRepo = ref.read(libraryRepositoryProvider);

    // Show file picker dialog
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => const _UploadResourceDialog(),
    );

    if (result == null) return;

    final fileBytes = result['fileBytes'] as Uint8List;
    final fileName = result['fileName'] as String;
    final resourceType = result['resourceType'] as DigitalResourceType;
    final title = result['title'] as String;
    final description = result['description'] as String;
    final accessLevel = result['accessLevel'] as AccessLevel;
    final downloadAllowed = result['downloadAllowed'] as bool;
    final maxDownloads = result['maxDownloads'] as int?;

    try {
      // Upload file to storage
      final fileUrl = await libraryRepo.uploadDigitalResourceFile(
        fileName: fileName,
        fileBytes: fileBytes,
        folder: resourceType.dbValue,
      );

      // Create digital resource record
      await libraryRepo.createDigitalResource(
        title: title,
        filePath: fileName,
        resourceType: resourceType,
        description: description,
        accessLevel: accessLevel,
        downloadAllowed: downloadAllowed,
        maxDownloads: maxDownloads,
      );

      // Refresh the resources list
      ref.invalidate(digitalResourcesProvider);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('$title uploaded successfully')));
    } catch (error) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Upload failed: $error')));
    }
  }
}

class _UploadResourceDialog extends StatefulWidget {
  const _UploadResourceDialog();

  @override
  State<_UploadResourceDialog> createState() => _UploadResourceDialogState();
}

class _UploadResourceDialogState extends State<_UploadResourceDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _maxDownloadsController = TextEditingController();

  DigitalResourceType _resourceType = DigitalResourceType.document;
  AccessLevel _accessLevel = AccessLevel.public;
  bool _downloadAllowed = true;
  Uint8List? _fileBytes;
  String? _fileName;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _maxDownloadsController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: [
          'pdf',
          'doc',
          'docx',
          'txt',
          'rtf',
          'ppt',
          'pptx',
          'xls',
          'xlsx',
          'jpg',
          'jpeg',
          'png',
          'gif',
          'bmp',
          'mp4',
          'avi',
          'mov',
          'wmv',
          'mp3',
          'wav',
          'ogg',
        ],
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        final fileBytes = file.bytes;

        if (fileBytes != null) {
          setState(() {
            _fileBytes = fileBytes;
            _fileName = file.name;
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to read file content')),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('File selection failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Upload Digital Resource'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton(
                onPressed: _pickFile,
                child: const Text('Select File'),
              ),
              if (_fileName != null) Text('Selected: $_fileName'),
              const SizedBox(height: 16),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Title'),
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Title is required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<DigitalResourceType>(
                initialValue: _resourceType,
                decoration: const InputDecoration(labelText: 'Resource Type'),
                items: DigitalResourceType.values.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(type.displayName),
                  );
                }).toList(),
                onChanged: (value) => setState(() => _resourceType = value!),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<AccessLevel>(
                initialValue: _accessLevel,
                decoration: const InputDecoration(labelText: 'Access Level'),
                items: AccessLevel.values.map((level) {
                  return DropdownMenuItem(
                    value: level,
                    child: Text(level.dbValue),
                  );
                }).toList(),
                onChanged: (value) => setState(() => _accessLevel = value!),
              ),
              const SizedBox(height: 16),
              CheckboxListTile(
                title: const Text('Allow Downloads'),
                value: _downloadAllowed,
                onChanged: (value) => setState(() => _downloadAllowed = value!),
              ),
              if (_downloadAllowed)
                TextFormField(
                  controller: _maxDownloadsController,
                  decoration: const InputDecoration(
                    labelText: 'Max Downloads (optional)',
                  ),
                  keyboardType: TextInputType.number,
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _fileBytes == null
              ? null
              : () {
                  if (_formKey.currentState!.validate()) {
                    Navigator.pop(context, {
                      'fileBytes': _fileBytes,
                      'fileName': _fileName,
                      'resourceType': _resourceType,
                      'title': _titleController.text,
                      'description': _descriptionController.text,
                      'accessLevel': _accessLevel,
                      'downloadAllowed': _downloadAllowed,
                      'maxDownloads': _maxDownloadsController.text.isEmpty
                          ? null
                          : int.tryParse(_maxDownloadsController.text),
                    });
                  }
                },
          child: const Text('Upload'),
        ),
      ],
    );
  }
}
