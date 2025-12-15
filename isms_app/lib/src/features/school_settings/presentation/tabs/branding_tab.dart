import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/branding/school_branding.dart';
import '../../../../core/network/supabase_client.dart';
import '../../../../core/tenant/tenant_context.dart';
import '../../../school_registration/application/school_providers.dart';
import '../../../school_registration/domain/school.dart';

class BrandingTab extends ConsumerStatefulWidget {
  const BrandingTab({super.key, required this.school});

  final School school;

  @override
  ConsumerState<BrandingTab> createState() => _BrandingTabState();
}

class _BrandingTabState extends ConsumerState<BrandingTab> {
  String? _logoUrl;
  Color? _primaryColor;
  Color? _secondaryColor;
  bool _isUploading = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _logoUrl = widget.school.logoUrl;
    _primaryColor = widget.school.primaryColor != null
        ? Color(
            int.parse(widget.school.primaryColor!.replaceFirst('#', '0xFF')),
          )
        : null;
    _secondaryColor = widget.school.secondaryColor != null
        ? Color(
            int.parse(widget.school.secondaryColor!.replaceFirst('#', '0xFF')),
          )
        : null;
  }

  Future<void> _pickAndUploadLogo() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) return;

      setState(() {
        _isUploading = true;
      });

      final file = result.files.single;
      Uint8List? bytes;

      if (file.bytes != null) {
        bytes = file.bytes;
      } else if (file.path != null) {
        // For non-web platforms, you'd need to read the file
        // For now, we'll handle web only
        throw Exception('File path not supported. Please use web platform.');
      }

      if (bytes == null) {
        throw Exception('Could not read file');
      }

      // Validate image size (200x200 recommended)
      // Note: Full validation would require image processing library

      // Upload to Supabase Storage
      final fileName =
          '${widget.school.id}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final client = SupabaseManager.client;

      await client.storage
          .from('school-logos')
          .uploadBinary(
            fileName,
            bytes,
            fileOptions: const FileOptions(
              upsert: true,
              contentType: 'image/jpeg',
            ),
          );

      final newLogoUrl = client.storage
          .from('school-logos')
          .getPublicUrl(fileName);

      setState(() {
        _logoUrl = newLogoUrl;
        _isUploading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Logo uploaded successfully')),
      );
    } catch (e) {
      setState(() {
        _isUploading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error uploading logo: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _save() async {
    setState(() {
      _isSaving = true;
    });

    try {
      final repo = ref.read(schoolRepositoryProvider);
      await repo.updateSchoolBranding(
        schoolId: widget.school.id,
        logoUrl: _logoUrl,
        primaryColorHex: _primaryColor != null
            ? '#${_primaryColor!.value.toRadixString(16).substring(2)}'
            : null,
        secondaryColorHex: _secondaryColor != null
            ? '#${_secondaryColor!.value.toRadixString(16).substring(2)}'
            : null,
      );

      // Refresh school data
      ref.invalidate(schoolProvider(widget.school.id));
      ref.invalidate(currentSchoolProvider);

      // Update tenant context and branding
      final updatedSchool = await repo.getSchoolById(widget.school.id);
      if (updatedSchool != null) {
        ref.read(tenantContextProvider.notifier).setSchool(updatedSchool);
        ref
            .read(schoolBrandingProvider.notifier)
            .updateBranding(
              SchoolBranding(
                schoolName: updatedSchool.name,
                logoUrl: updatedSchool.logoUrl,
                primaryColor: updatedSchool.primaryColor != null
                    ? Color(
                        int.parse(
                          updatedSchool.primaryColor!.replaceFirst('#', '0xFF'),
                        ),
                      )
                    : null,
                secondaryColor: updatedSchool.secondaryColor != null
                    ? Color(
                        int.parse(
                          updatedSchool.secondaryColor!.replaceFirst(
                            '#',
                            '0xFF',
                          ),
                        ),
                      )
                    : null,
              ),
            );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Branding updated successfully')),
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Branding & Appearance',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Customize your school\'s logo and theme colors to match your brand.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 32),
          // Logo Section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'School Logo',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Recommended size: 200x200 pixels. Logo will be displayed in the app header.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      if (_logoUrl != null)
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Theme.of(context).colorScheme.outline,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              _logoUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  const Icon(Icons.broken_image),
                            ),
                          ),
                        )
                      else
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.surfaceContainerHighest,
                            border: Border.all(
                              color: Theme.of(context).colorScheme.outline,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.image, size: 48),
                        ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            FilledButton.icon(
                              icon: _isUploading
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.upload),
                              label: Text(
                                _logoUrl == null
                                    ? 'Upload Logo'
                                    : 'Change Logo',
                              ),
                              onPressed: _isUploading
                                  ? null
                                  : _pickAndUploadLogo,
                            ),
                            if (_logoUrl != null) ...[
                              const SizedBox(height: 8),
                              TextButton.icon(
                                icon: const Icon(Icons.delete_outline),
                                label: const Text('Remove Logo'),
                                onPressed: () {
                                  setState(() {
                                    _logoUrl = null;
                                  });
                                },
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Color Section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Theme Colors',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Set your school\'s primary and secondary colors. These will be used throughout the portal.',
                    style: Theme.of(context).textTheme.bodySmall,
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
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 12),
                            InkWell(
                              onTap: () async {
                                final color = await showDialog<Color>(
                                  context: context,
                                  builder: (context) => _ColorPickerDialog(
                                    initialColor: _primaryColor ?? Colors.blue,
                                  ),
                                );
                                if (color != null) {
                                  setState(() {
                                    _primaryColor = color;
                                  });
                                }
                              },
                              child: Container(
                                width: double.infinity,
                                height: 60,
                                decoration: BoxDecoration(
                                  color: _primaryColor ?? Colors.grey,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.outline,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    _primaryColor != null
                                        ? '#${_primaryColor!.value.toRadixString(16).substring(2).toUpperCase()}'
                                        : 'Select Color',
                                    style: TextStyle(
                                      color: _primaryColor != null
                                          ? (_primaryColor!.computeLuminance() >
                                                    0.5
                                                ? Colors.black
                                                : Colors.white)
                                          : null,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            if (_primaryColor != null) ...[
                              const SizedBox(height: 8),
                              TextButton(
                                onPressed: () {
                                  setState(() {
                                    _primaryColor = null;
                                  });
                                },
                                child: const Text('Clear'),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Secondary Color',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 12),
                            InkWell(
                              onTap: () async {
                                final color = await showDialog<Color>(
                                  context: context,
                                  builder: (context) => _ColorPickerDialog(
                                    initialColor:
                                        _secondaryColor ?? Colors.orange,
                                  ),
                                );
                                if (color != null) {
                                  setState(() {
                                    _secondaryColor = color;
                                  });
                                }
                              },
                              child: Container(
                                width: double.infinity,
                                height: 60,
                                decoration: BoxDecoration(
                                  color: _secondaryColor ?? Colors.grey,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.outline,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    _secondaryColor != null
                                        ? '#${_secondaryColor!.value.toRadixString(16).substring(2).toUpperCase()}'
                                        : 'Select Color',
                                    style: TextStyle(
                                      color: _secondaryColor != null
                                          ? (_secondaryColor!
                                                        .computeLuminance() >
                                                    0.5
                                                ? Colors.black
                                                : Colors.white)
                                          : null,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            if (_secondaryColor != null) ...[
                              const SizedBox(height: 8),
                              TextButton(
                                onPressed: () {
                                  setState(() {
                                    _secondaryColor = null;
                                  });
                                },
                                child: const Text('Clear'),
                              ),
                            ],
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
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _isSaving ? null : _save,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save Changes'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ColorPickerDialog extends StatefulWidget {
  const _ColorPickerDialog({required this.initialColor});

  final Color initialColor;

  @override
  State<_ColorPickerDialog> createState() => _ColorPickerDialogState();
}

class _ColorPickerDialogState extends State<_ColorPickerDialog> {
  late Color _selectedColor;

  @override
  void initState() {
    super.initState();
    _selectedColor = widget.initialColor;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Select Color',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 24),
              // Simple color grid
              GridView.builder(
                shrinkWrap: true,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 8,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                ),
                itemCount: _presetColors.length,
                itemBuilder: (context, index) {
                  final color = _presetColors[index];
                  final isSelected = _selectedColor.value == color.value;
                  return InkWell(
                    onTap: () {
                      setState(() {
                        _selectedColor = color;
                      });
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected
                              ? Theme.of(context).colorScheme.primary
                              : Colors.transparent,
                          width: isSelected ? 3 : 0,
                        ),
                      ),
                      child: isSelected
                          ? const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 20,
                            )
                          : null,
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () => Navigator.of(context).pop(_selectedColor),
                    child: const Text('Select'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static final List<Color> _presetColors = [
    Colors.blue,
    Colors.green,
    Colors.red,
    Colors.orange,
    Colors.purple,
    Colors.teal,
    Colors.pink,
    Colors.indigo,
    Colors.cyan,
    Colors.amber,
    Colors.brown,
    Colors.deepPurple,
    Colors.lightBlue,
    Colors.lightGreen,
    Colors.deepOrange,
    Colors.blueGrey,
    Colors.grey,
    Colors.black,
    Colors.white,
    Colors.yellow,
    Colors.lime,
    Colors.blue.shade700,
    Colors.green.shade700,
    Colors.red.shade700,
    Colors.orange.shade700,
    Colors.purple.shade700,
    Colors.teal.shade700,
    Colors.pink.shade700,
    Colors.indigo.shade700,
    Colors.cyan.shade700,
    Colors.amber.shade700,
    Colors.brown.shade700,
  ];
}
