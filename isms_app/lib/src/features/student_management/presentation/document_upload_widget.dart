import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class DocumentUploadWidget extends StatefulWidget {
  const DocumentUploadWidget({
    super.key,
    required this.onDocumentSelected,
    this.documentType,
    this.label,
  });

  final Function(String filePath, String fileName, String documentType)
  onDocumentSelected;
  final String? documentType;
  final String? label;

  @override
  State<DocumentUploadWidget> createState() => _DocumentUploadWidgetState();
}

class _DocumentUploadWidgetState extends State<DocumentUploadWidget> {
  String? _selectedFileName;
  String? _selectedFilePath;

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'doc', 'docx'],
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _selectedFilePath = result.files.single.path!;
          _selectedFileName = result.files.single.name;
        });
        widget.onDocumentSelected(
          _selectedFilePath!,
          _selectedFileName!,
          widget.documentType ?? 'document',
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error picking file: $e')));
      }
    }
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(source: ImageSource.gallery);

      if (image != null) {
        setState(() {
          _selectedFilePath = image.path;
          _selectedFileName = image.name;
        });
        widget.onDocumentSelected(
          _selectedFilePath!,
          _selectedFileName!,
          widget.documentType ?? 'photo',
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error picking image: $e')));
      }
    }
  }

  void _showPickerOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Pick from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage();
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              onTap: () async {
                Navigator.pop(context);
                try {
                  final picker = ImagePicker();
                  final image = await picker.pickImage(
                    source: ImageSource.camera,
                  );
                  if (image != null) {
                    setState(() {
                      _selectedFilePath = image.path;
                      _selectedFileName = image.name;
                    });
                    widget.onDocumentSelected(
                      _selectedFilePath!,
                      _selectedFileName!,
                      widget.documentType ?? 'photo',
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text('Error: $e')));
                  }
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.insert_drive_file),
              title: const Text('Pick Document'),
              onTap: () {
                Navigator.pop(context);
                _pickFile();
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.label ?? 'Upload Document',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            if (_selectedFileName != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _selectedFileName!,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        setState(() {
                          _selectedFileName = null;
                          _selectedFilePath = null;
                        });
                      },
                    ),
                  ],
                ),
              ),
            OutlinedButton.icon(
              icon: const Icon(Icons.upload_file),
              label: Text(
                _selectedFileName != null ? 'Change File' : 'Select File',
              ),
              onPressed: _showPickerOptions,
            ),
          ],
        ),
      ),
    );
  }
}
