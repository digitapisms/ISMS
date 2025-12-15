import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/storage_providers.dart';
import '../../../core/tenant/tenant_context.dart';
import '../../authentication/application/auth_providers.dart';
import '../application/student_providers.dart';

class AddStudentScreen extends ConsumerStatefulWidget {
  const AddStudentScreen({super.key});

  @override
  ConsumerState<AddStudentScreen> createState() => _AddStudentScreenState();
}

class _AddStudentScreenState extends ConsumerState<AddStudentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _admissionController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _medicalInfoController = TextEditingController();
  final _fatherNameController = TextEditingController();
  final _fatherPhoneController = TextEditingController();
  final _motherNameController = TextEditingController();
  final _motherPhoneController = TextEditingController();
  final _guardianNameController = TextEditingController();
  final _guardianRelationController = TextEditingController();
  final _guardianPhoneController = TextEditingController();
  final _emergencyNameController = TextEditingController();
  final _emergencyPhoneController = TextEditingController();
  final _emergencyRelationController = TextEditingController(text: 'Parent');

  int? _selectedClassId;
  int? _selectedSectionId;
  DateTime? _selectedDob;
  String? _selectedGender;
  String? _selectedBloodGroup;
  String _status = 'active';
  bool _isSubmitting = false;

  List<Map<String, dynamic>> _classes = [];
  List<Map<String, dynamic>> _sections = [];
  PlatformFile? _selectedPhoto;
  Uint8List? _photoPreview;

  @override
  void initState() {
    super.initState();
    _loadClasses();
  }

  @override
  void dispose() {
    _admissionController.dispose();
    _fullNameController.dispose();
    _medicalInfoController.dispose();
    _fatherNameController.dispose();
    _fatherPhoneController.dispose();
    _motherNameController.dispose();
    _motherPhoneController.dispose();
    _guardianNameController.dispose();
    _guardianRelationController.dispose();
    _guardianPhoneController.dispose();
    _emergencyNameController.dispose();
    _emergencyPhoneController.dispose();
    _emergencyRelationController.dispose();
    super.dispose();
  }

  Future<void> _loadClasses() async {
    final repo = ref.read(studentRepositoryProvider);
    final classes = await repo.fetchClasses();
    setState(() {
      _classes = classes;
    });
  }

  Future<void> _loadSections(int? classId) async {
    if (classId == null) {
      setState(() {
        _sections = [];
        _selectedSectionId = null;
      });
      return;
    }
    final repo = ref.read(studentRepositoryProvider);
    final sections = await repo.fetchSections(classId);
    setState(() {
      _sections = sections;
      _selectedSectionId = null;
    });
  }

  Future<void> _pickPhoto() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );

    if (result == null || result.files.isEmpty) return;

    setState(() {
      _selectedPhoto = result.files.single;
      _photoPreview = _selectedPhoto?.bytes;
    });
  }

  Future<String?> _uploadPhoto() async {
    if (_selectedPhoto == null) return null;
    final bytes = _selectedPhoto!.bytes;
    if (bytes == null) {
      throw Exception('Unable to read the selected image. Please try again.');
    }

    final schoolId = ref.read(tenantContextProvider)?.id ??
        ref.read(authStateProvider)?.schoolId ??
        'global';
    final storage = ref.read(storageServiceProvider);
    final sanitizedName =
        _selectedPhoto!.name.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
    final fileName =
        '${schoolId}_avatar_${DateTime.now().millisecondsSinceEpoch}_$sanitizedName';

    return storage.uploadFileFromBytes(
      bucket: 'student-media',
      bytes: bytes,
      fileName: fileName,
      folder: 'avatars/$schoolId',
      contentType: _selectedPhoto!.extension?.toLowerCase() == 'png'
          ? 'image/png'
          : 'image/jpeg',
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final avatarUrl = await _uploadPhoto();
      final repo = ref.read(studentRepositoryProvider);

      final studentId = await repo.createStudent(
        admissionNo: _admissionController.text.trim(),
        fullName: _fullNameController.text.trim(),
        classId: _selectedClassId,
        sectionId: _selectedSectionId,
        status: _status,
        dob: _selectedDob,
        gender: _selectedGender,
        bloodGroup: _selectedBloodGroup,
        medicalInfo: _medicalInfoController.text.trim().isEmpty
            ? null
            : _medicalInfoController.text.trim(),
        avatarUrl: avatarUrl,
      );

      if (_fatherNameController.text.trim().isNotEmpty) {
        await repo.addFamilyMember(
          studentId: studentId,
          relation: 'Father',
          name: _fatherNameController.text.trim(),
          contact: _fatherPhoneController.text.trim().isEmpty
              ? null
              : _fatherPhoneController.text.trim(),
        );
      }

      if (_motherNameController.text.trim().isNotEmpty) {
        await repo.addFamilyMember(
          studentId: studentId,
          relation: 'Mother',
          name: _motherNameController.text.trim(),
          contact: _motherPhoneController.text.trim().isEmpty
              ? null
              : _motherPhoneController.text.trim(),
        );
      }

      if (_guardianNameController.text.trim().isNotEmpty) {
        await repo.addFamilyMember(
          studentId: studentId,
          relation: _guardianRelationController.text.trim().isEmpty
              ? 'Guardian'
              : _guardianRelationController.text.trim(),
          name: _guardianNameController.text.trim(),
          contact: _guardianPhoneController.text.trim().isEmpty
              ? null
              : _guardianPhoneController.text.trim(),
        );
      }

      if (_emergencyNameController.text.trim().isNotEmpty &&
          _emergencyPhoneController.text.trim().isNotEmpty) {
        await repo.addEmergencyContact(
          studentId: studentId,
          name: _emergencyNameController.text.trim(),
          phone: _emergencyPhoneController.text.trim(),
          relation: _emergencyRelationController.text.trim().isEmpty
              ? null
              : _emergencyRelationController.text.trim(),
        );
      }

      if (!mounted) return;
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Student added successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to add student: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Student'),
        actions: [
          if (_isSubmitting)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _submit,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildBasicInfoCard(),
              const SizedBox(height: 16),
              _buildAcademicInfoCard(),
              const SizedBox(height: 16),
              _buildPersonalInfoCard(),
              const SizedBox(height: 16),
              _buildFamilyInfoCard(),
              const SizedBox(height: 16),
              _buildEmergencyCard(),
              const SizedBox(height: 24),
              FilledButton.icon(
                icon: const Icon(Icons.check),
                label: const Text('Save Student'),
                onPressed: _isSubmitting ? null : _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBasicInfoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Basic Information',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _admissionController,
              decoration: const InputDecoration(
                labelText: 'Admission Number',
                border: OutlineInputBorder(),
              ),
              validator: (value) =>
                  value == null || value.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _fullNameController,
              decoration: const InputDecoration(
                labelText: 'Full Name',
                border: OutlineInputBorder(),
              ),
              validator: (value) =>
                  value == null || value.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              icon: const Icon(Icons.photo_camera),
              label: Text(_selectedPhoto == null
                  ? 'Upload Student Photo'
                  : 'Change Photo'),
              onPressed: _pickPhoto,
            ),
            if (_photoPreview != null) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.memory(
                  _photoPreview!,
                  height: 150,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAcademicInfoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Academic Information',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int?>(
              decoration: const InputDecoration(
                labelText: 'Class',
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem<int?>(
                  value: null,
                  child: Text('Select class'),
                ),
                ..._classes.map(
                  (c) => DropdownMenuItem<int?>(
                    value: c['id'] as int,
                    child: Text(c['name'] as String),
                  ),
                ),
              ],
              initialValue: _selectedClassId,
              onChanged: (value) {
                setState(() {
                  _selectedClassId = value;
                  _selectedSectionId = null;
                });
                _loadSections(value);
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int?>(
              decoration: const InputDecoration(
                labelText: 'Section',
                border: OutlineInputBorder(),
              ),
              initialValue: _selectedSectionId,
              items: [
                const DropdownMenuItem<int?>(
                  value: null,
                  child: Text('Select section'),
                ),
                ..._sections.map(
                  (s) => DropdownMenuItem<int?>(
                    value: s['id'] as int,
                    child: Text(s['name'] as String),
                  ),
                ),
              ],
              onChanged: _selectedClassId == null
                  ? null
                  : (value) {
                      setState(() {
                        _selectedSectionId = value;
                      });
                    },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Status',
                border: OutlineInputBorder(),
              ),
              initialValue: _status,
              items: const [
                DropdownMenuItem(value: 'active', child: Text('Active')),
                DropdownMenuItem(value: 'pending', child: Text('Pending')),
                DropdownMenuItem(value: 'inactive', child: Text('Inactive')),
                DropdownMenuItem(value: 'alumni', child: Text('Alumni')),
              ],
              onChanged: (value) {
                if (value == null) return;
                setState(() {
                  _status = value;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonalInfoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Personal Information',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Date of Birth'),
              subtitle: Text(
                _selectedDob == null
                    ? 'Not set'
                    : '${_selectedDob!.day}/${_selectedDob!.month}/${_selectedDob!.year}',
              ),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _selectedDob ?? DateTime(2010, 1, 1),
                  firstDate: DateTime(1990),
                  lastDate: DateTime.now(),
                );
                if (picked != null) {
                  setState(() {
                    _selectedDob = picked;
                  });
                }
              },
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String?>(
              decoration: const InputDecoration(
                labelText: 'Gender',
                border: OutlineInputBorder(),
              ),
              initialValue: _selectedGender,
              items: const [
                DropdownMenuItem<String?>(
                  value: null,
                  child: Text('Not specified'),
                ),
                DropdownMenuItem(value: 'Male', child: Text('Male')),
                DropdownMenuItem(value: 'Female', child: Text('Female')),
                DropdownMenuItem(value: 'Other', child: Text('Other')),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedGender = value;
                });
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String?>(
              decoration: const InputDecoration(
                labelText: 'Blood Group',
                border: OutlineInputBorder(),
              ),
              initialValue: _selectedBloodGroup,
              items: const [
                DropdownMenuItem<String?>(
                  value: null,
                  child: Text('Not specified'),
                ),
                DropdownMenuItem(value: 'A+', child: Text('A+')),
                DropdownMenuItem(value: 'A-', child: Text('A-')),
                DropdownMenuItem(value: 'B+', child: Text('B+')),
                DropdownMenuItem(value: 'B-', child: Text('B-')),
                DropdownMenuItem(value: 'AB+', child: Text('AB+')),
                DropdownMenuItem(value: 'AB-', child: Text('AB-')),
                DropdownMenuItem(value: 'O+', child: Text('O+')),
                DropdownMenuItem(value: 'O-', child: Text('O-')),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedBloodGroup = value;
                });
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _medicalInfoController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Medical Notes',
                hintText: 'Any allergies, medical conditions, or notes',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFamilyInfoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Family Information',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            _buildContactSection(
              title: 'Father',
              nameController: _fatherNameController,
              phoneController: _fatherPhoneController,
            ),
            const SizedBox(height: 16),
            _buildContactSection(
              title: 'Mother',
              nameController: _motherNameController,
              phoneController: _motherPhoneController,
            ),
            const SizedBox(height: 16),
            Text(
              'Guardian (optional)',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _guardianNameController,
              decoration: const InputDecoration(
                labelText: 'Guardian Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _guardianRelationController,
              decoration: const InputDecoration(
                labelText: 'Relation',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _guardianPhoneController,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactSection({
    required String title,
    required TextEditingController nameController,
    required TextEditingController phoneController,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: nameController,
          decoration: InputDecoration(
            labelText: '$title Name',
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: phoneController,
          decoration: const InputDecoration(
            labelText: 'Phone Number',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.phone,
        ),
      ],
    );
  }

  Widget _buildEmergencyCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Emergency Contact',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _emergencyNameController,
              decoration: const InputDecoration(
                labelText: 'Contact Name',
                border: OutlineInputBorder(),
              ),
              validator: (value) =>
                  value == null || value.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _emergencyPhoneController,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
              validator: (value) =>
                  value == null || value.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _emergencyRelationController,
              decoration: const InputDecoration(
                labelText: 'Relation',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }

}
