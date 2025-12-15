import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/branding/school_branding.dart';
import '../../../core/storage/storage_providers.dart';
import '../../school_registration/application/school_providers.dart';

class SchoolBrandingSettingsScreen extends ConsumerStatefulWidget {
  const SchoolBrandingSettingsScreen({super.key});

  @override
  ConsumerState<SchoolBrandingSettingsScreen> createState() =>
      _SchoolBrandingSettingsScreenState();
}

class _SchoolBrandingSettingsScreenState
    extends ConsumerState<SchoolBrandingSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _schoolNameController = TextEditingController();
  String? _logoPath;
  Color? _selectedPrimaryColor;
  Color? _selectedSecondaryColor;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentBranding();
  }

  void _loadCurrentBranding() {
    final branding = ref.read(schoolBrandingProvider);
    _schoolNameController.text = branding.schoolName ?? '';
    _selectedPrimaryColor = branding.primaryColor;
    _selectedSecondaryColor = branding.secondaryColor;
    _logoPath = branding.logoUrl;
  }

  @override
  void dispose() {
    _schoolNameController.dispose();
    super.dispose();
  }

  Future<void> _pickLogo() async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          _logoPath = image.path;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error picking image: $e')));
      }
    }
  }

  Future<void> _saveBranding() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isUploading = true;
    });

    try {
      final notifier = ref.read(schoolBrandingProvider.notifier);
      final storageService = ref.read(storageServiceProvider);
      final school = ref.read(currentSchoolProvider);

      // Upload logo to Supabase Storage if _logoPath is a local file
      String? logoUrl = _logoPath;
      if (_logoPath != null && !_logoPath!.startsWith('http')) {
        try {
          if (school != null) {
            logoUrl = await storageService.uploadSchoolLogo(
              schoolId: school.id,
              filePath: _logoPath!,
            );
          } else {
            // Fallback: upload to generic bucket
            logoUrl = await storageService.uploadFile(
              bucket: 'school-assets',
              filePath: _logoPath!,
              folder: 'logos',
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('Error uploading logo: $e')));
          }
          return;
        }
      }

      notifier.updateBranding(
        SchoolBranding(
          schoolName: _schoolNameController.text.trim().isEmpty
              ? null
              : _schoolNameController.text.trim(),
          logoUrl: logoUrl,
          primaryColor: _selectedPrimaryColor,
          secondaryColor: _selectedSecondaryColor,
        ),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Branding updated successfully')),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('School Branding')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'School Information',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: _schoolNameController,
                        decoration: const InputDecoration(
                          labelText: 'School Name',
                          hintText: 'Enter your school name',
                          prefixIcon: Icon(Icons.school),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'School name is required';
                          }
                          if (value.trim().length < 3) {
                            return 'School name must be at least 3 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      Text('School Logo', style: theme.textTheme.titleMedium),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          if (_logoPath != null)
                            Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: _logoPath!.startsWith('http')
                                    ? Image.network(
                                        _logoPath!,
                                        fit: BoxFit.cover,
                                      )
                                    : Image.file(
                                        File(_logoPath!),
                                        fit: BoxFit.cover,
                                      ),
                              ),
                            )
                          else
                            Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                color: colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: Icon(
                                Icons.image,
                                size: 40,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.upload),
                              label: const Text('Upload Logo'),
                              onPressed: _pickLogo,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Color Theme',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Customize your school colors',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Primary Color',
                                  style: theme.textTheme.titleSmall,
                                ),
                                const SizedBox(height: 8),
                                GestureDetector(
                                  onTap: () async {
                                    // Color picker would go here
                                    // For now, show a simple color selection
                                  },
                                  child: Container(
                                    width: double.infinity,
                                    height: 60,
                                    decoration: BoxDecoration(
                                      color:
                                          _selectedPrimaryColor ??
                                          colorScheme.primary,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.grey.shade300,
                                        width: 2,
                                      ),
                                    ),
                                    child: Center(
                                      child: Text(
                                        'Tap to change',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Secondary Color',
                                  style: theme.textTheme.titleSmall,
                                ),
                                const SizedBox(height: 8),
                                GestureDetector(
                                  onTap: () async {
                                    // Color picker would go here
                                  },
                                  child: Container(
                                    width: double.infinity,
                                    height: 60,
                                    decoration: BoxDecoration(
                                      color:
                                          _selectedSecondaryColor ??
                                          colorScheme.secondary,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.grey.shade300,
                                        width: 2,
                                      ),
                                    ),
                                    child: Center(
                                      child: Text(
                                        'Tap to change',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              FilledButton(
                onPressed: _isUploading ? null : _saveBranding,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isUploading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save Branding'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
