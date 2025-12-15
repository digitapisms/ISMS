import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/tenant/tenant_context.dart';
import '../../authentication/application/auth_providers.dart';
import '../application/student_providers.dart';
import 'form_draft_service.dart';

class StudentRegistrationScreen extends ConsumerStatefulWidget {
  const StudentRegistrationScreen({super.key});

  @override
  ConsumerState<StudentRegistrationScreen> createState() =>
      _StudentRegistrationScreenState();
}

class _StudentRegistrationScreenState
    extends ConsumerState<StudentRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _pageController = PageController();
  int _currentPage = 0;

  // Documents
  final Map<String, List<int>> _documentBytes = {}; // documentType -> fileBytes
  final Map<String, String> _documentNames = {}; // documentType -> fileName

  // Personal Information
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _dobController = TextEditingController();
  String? _selectedGender;
  String? _selectedBloodGroup;
  final _nationalityController = TextEditingController();
  final _religionController = TextEditingController();
  final _medicalInfoController = TextEditingController();

  // Academic Information
  int? _selectedClassId;
  int? _selectedSectionId;
  final _previousSchoolController = TextEditingController();

  // Family Information
  final _fatherNameController = TextEditingController();
  final _fatherContactController = TextEditingController();
  final _fatherOccupationController = TextEditingController();
  final _motherNameController = TextEditingController();
  final _motherContactController = TextEditingController();
  final _motherOccupationController = TextEditingController();
  final _guardianNameController = TextEditingController();
  final _guardianContactController = TextEditingController();
  final _guardianRelationController = TextEditingController();

  // Emergency Contact
  final _emergencyNameController = TextEditingController();
  final _emergencyPhoneController = TextEditingController();
  final _emergencyRelationController = TextEditingController();

  // Address
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _zipCodeController = TextEditingController();

  List<Map<String, dynamic>> _classes = [];
  List<Map<String, dynamic>> _sections = [];
  List<Map<String, dynamic>> _transportRoutes = [];
  bool _isLoading = false;
  bool _isLoadingClasses = true;
  DateTime? _selectedDob;
  String? _transportRequired;
  String? _transportRoute;

  @override
  void initState() {
    super.initState();
    _loadClasses();
    _loadTransportRoutes();
    _loadDraft();
  }

  Future<void> _loadDraft() async {
    final draft = FormDraftService.loadRegistrationDraft();
    if (draft != null) {
      setState(() {
        _firstNameController.text = draft['firstName'] ?? '';
        _lastNameController.text = draft['lastName'] ?? '';
        _nationalityController.text = draft['nationality'] ?? '';
        _religionController.text = draft['religion'] ?? '';
        _medicalInfoController.text = draft['medicalInfo'] ?? '';
        _previousSchoolController.text = draft['previousSchool'] ?? '';
        _addressController.text = draft['address'] ?? '';
        _cityController.text = draft['city'] ?? '';
        _stateController.text = draft['state'] ?? '';
        _zipCodeController.text = draft['zipCode'] ?? '';
        _fatherNameController.text = draft['fatherName'] ?? '';
        _fatherContactController.text = draft['fatherContact'] ?? '';
        _fatherOccupationController.text = draft['fatherOccupation'] ?? '';
        _motherNameController.text = draft['motherName'] ?? '';
        _motherContactController.text = draft['motherContact'] ?? '';
        _motherOccupationController.text = draft['motherOccupation'] ?? '';
        _guardianNameController.text = draft['guardianName'] ?? '';
        _guardianContactController.text = draft['guardianContact'] ?? '';
        _guardianRelationController.text = draft['guardianRelation'] ?? '';
        _emergencyNameController.text = draft['emergencyName'] ?? '';
        _emergencyPhoneController.text = draft['emergencyPhone'] ?? '';
        _emergencyRelationController.text = draft['emergencyRelation'] ?? '';
        _selectedGender = draft['gender'];
        _selectedBloodGroup = draft['bloodGroup'];
        _selectedClassId = draft['classId'];
        _selectedSectionId = draft['sectionId'];
        _transportRequired = draft['transportRequired'];
        _transportRoute = draft['transportRoute'];
        if (draft['dob'] != null) {
          _selectedDob = DateTime.parse(draft['dob']);
          _dobController.text = _selectedDob!.toString().split(' ')[0];
        }
        _currentPage = draft['currentPage'] ?? 0;
      });
      if (_currentPage > 0) {
        _pageController.jumpToPage(_currentPage);
      }
    }
  }

  Future<void> _saveDraft() async {
    final draft = {
      'firstName': _firstNameController.text,
      'lastName': _lastNameController.text,
      'nationality': _nationalityController.text,
      'religion': _religionController.text,
      'medicalInfo': _medicalInfoController.text,
      'previousSchool': _previousSchoolController.text,
      'address': _addressController.text,
      'city': _cityController.text,
      'state': _stateController.text,
      'zipCode': _zipCodeController.text,
      'fatherName': _fatherNameController.text,
      'fatherContact': _fatherContactController.text,
      'fatherOccupation': _fatherOccupationController.text,
      'motherName': _motherNameController.text,
      'motherContact': _motherContactController.text,
      'motherOccupation': _motherOccupationController.text,
      'guardianName': _guardianNameController.text,
      'guardianContact': _guardianContactController.text,
      'guardianRelation': _guardianRelationController.text,
      'emergencyName': _emergencyNameController.text,
      'emergencyPhone': _emergencyPhoneController.text,
      'emergencyRelation': _emergencyRelationController.text,
      'gender': _selectedGender,
      'bloodGroup': _selectedBloodGroup,
      'classId': _selectedClassId,
      'sectionId': _selectedSectionId,
      'transportRequired': _transportRequired,
      'transportRoute': _transportRoute,
      'dob': _selectedDob?.toIso8601String(),
      'currentPage': _currentPage,
    };
    await FormDraftService.saveRegistrationDraft(draft);
  }

  Future<void> _loadTransportRoutes() async {
    final repo = ref.read(studentRepositoryProvider);
    final routes = await repo.fetchTransportRoutes();
    setState(() {
      _transportRoutes = routes;
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _dobController.dispose();
    _nationalityController.dispose();
    _religionController.dispose();
    _medicalInfoController.dispose();
    _previousSchoolController.dispose();
    _fatherNameController.dispose();
    _fatherContactController.dispose();
    _fatherOccupationController.dispose();
    _motherNameController.dispose();
    _motherContactController.dispose();
    _motherOccupationController.dispose();
    _guardianNameController.dispose();
    _guardianContactController.dispose();
    _guardianRelationController.dispose();
    _emergencyNameController.dispose();
    _emergencyPhoneController.dispose();
    _emergencyRelationController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _zipCodeController.dispose();
    super.dispose();
  }

  Future<void> _loadClasses() async {
    final repo = ref.read(studentRepositoryProvider);
    final classes = await repo.fetchClasses();
    setState(() {
      _classes = classes;
      _isLoadingClasses = false;
    });
  }

  Future<void> _loadSections(int classId) async {
    final repo = ref.read(studentRepositoryProvider);
    final sections = await repo.fetchSections(classId);
    setState(() {
      _sections = sections;
      _selectedSectionId = null;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final authUser = ref.read(authStateProvider);
      if (authUser == null) {
        throw Exception('Not authenticated');
      }
      final tenantSchool = ref.read(tenantContextProvider);
      final schoolId = tenantSchool?.id ?? authUser.schoolId;
      if (schoolId == null) {
        throw Exception(
          'Please choose a school before submitting the application.',
        );
      }

      final repo = ref.read(studentRepositoryProvider);

      // Submit application first to get student ID
      final studentId = await repo.submitStudentApplication(
        applicantUserId: authUser.id,
        schoolId: schoolId,
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        dob: _selectedDob,
        gender: _selectedGender,
        bloodGroup: _selectedBloodGroup,
        nationality: _nationalityController.text.trim().isEmpty
            ? null
            : _nationalityController.text.trim(),
        religion: _religionController.text.trim().isEmpty
            ? null
            : _religionController.text.trim(),
        medicalInfo: _medicalInfoController.text.trim().isEmpty
            ? null
            : _medicalInfoController.text.trim(),
        desiredClassId: _selectedClassId,
        previousSchool: _previousSchoolController.text.trim().isEmpty
            ? null
            : _previousSchoolController.text.trim(),
        address: _addressController.text.trim(),
        city: _cityController.text.trim(),
        state: _stateController.text.trim(),
        zipCode: _zipCodeController.text.trim().isEmpty
            ? null
            : _zipCodeController.text.trim(),
        fatherName: _fatherNameController.text.trim().isEmpty
            ? null
            : _fatherNameController.text.trim(),
        fatherContact: _fatherContactController.text.trim().isEmpty
            ? null
            : _fatherContactController.text.trim(),
        fatherOccupation: _fatherOccupationController.text.trim().isEmpty
            ? null
            : _fatherOccupationController.text.trim(),
        motherName: _motherNameController.text.trim().isEmpty
            ? null
            : _motherNameController.text.trim(),
        motherContact: _motherContactController.text.trim().isEmpty
            ? null
            : _motherContactController.text.trim(),
        motherOccupation: _motherOccupationController.text.trim().isEmpty
            ? null
            : _motherOccupationController.text.trim(),
        guardianName: _guardianNameController.text.trim().isEmpty
            ? null
            : _guardianNameController.text.trim(),
        guardianContact: _guardianContactController.text.trim().isEmpty
            ? null
            : _guardianContactController.text.trim(),
        guardianRelation: _guardianRelationController.text.trim().isEmpty
            ? null
            : _guardianRelationController.text.trim(),
        emergencyName: _emergencyNameController.text.trim(),
        emergencyPhone: _emergencyPhoneController.text.trim(),
        emergencyRelation: _emergencyRelationController.text.trim().isEmpty
            ? null
            : _emergencyRelationController.text.trim(),
        transportRequired: _transportRequired,
        transportRoute: _transportRoute,
      );

      // Upload documents if any
      if (_documentBytes.isNotEmpty) {
        for (final entry in _documentBytes.entries) {
          try {
            await repo.uploadDocument(
              studentId: studentId,
              documentType: entry.key,
              fileBytes: entry.value,
              fileName: _documentNames[entry.key] ?? 'document',
              schoolId: schoolId,
            );
          } catch (e) {
            // Log error but don't fail the whole submission
            debugPrint('Error uploading ${entry.key}: $e');
          }
        }
      }

      // Clear draft after successful submission
      await FormDraftService.clearRegistrationDraft();

      if (!mounted) return;
      Navigator.of(context).pop();
      ref.invalidate(applicationStatusProvider(authUser.id));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Application submitted successfully!')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Student Registration')),
      body: _isLoadingClasses
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: LinearProgressIndicator(
                          value: (_currentPage + 1) / 6,
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.save_outlined),
                        onPressed: _saveDraft,
                        tooltip: 'Save Draft',
                      ),
                    ],
                  ),
                  Expanded(
                    child: PageView(
                      controller: _pageController,
                      onPageChanged: (page) {
                        setState(() {
                          _currentPage = page;
                        });
                        _saveDraft(); // Auto-save on page change
                      },
                      children: [
                        _buildPersonalInfoPage(),
                        _buildAcademicInfoPage(),
                        _buildFamilyInfoPage(),
                        _buildEmergencyContactPage(),
                        _buildAddressPage(),
                        _buildDocumentsPage(),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        if (_currentPage > 0)
                          TextButton(
                            onPressed: () {
                              _pageController.previousPage(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            },
                            child: const Text('Previous'),
                          ),
                        const Spacer(),
                        if (_currentPage < 5)
                          FilledButton(
                            onPressed: () {
                              if (_validateCurrentPage()) {
                                _pageController.nextPage(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                );
                              }
                            },
                            child: const Text('Next'),
                          )
                        else
                          FilledButton(
                            onPressed: _isLoading ? null : _submit,
                            child: _isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text('Submit Application'),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  bool _validateCurrentPage() {
    switch (_currentPage) {
      case 0:
        if (_firstNameController.text.trim().isEmpty ||
            _lastNameController.text.trim().isEmpty ||
            _selectedDob == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please fill all required fields')),
          );
          return false;
        }
        return true;
      case 1:
        if (_selectedClassId == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please select a class')),
          );
          return false;
        }
        return true;
      case 4:
        if (_emergencyNameController.text.trim().isEmpty ||
            _emergencyPhoneController.text.trim().isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please fill emergency contact details'),
            ),
          );
          return false;
        }
        return true;
      case 5:
        // Documents are optional
        return true;
      default:
        return true;
    }
  }

  Widget _buildPersonalInfoPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Personal Information',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _firstNameController,
            decoration: const InputDecoration(
              labelText: 'First Name *',
              border: OutlineInputBorder(),
            ),
            validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _lastNameController,
            decoration: const InputDecoration(
              labelText: 'Last Name *',
              border: OutlineInputBorder(),
            ),
            validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _dobController,
            decoration: const InputDecoration(
              labelText: 'Date of Birth *',
              border: OutlineInputBorder(),
            ),
            readOnly: true,
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: DateTime.now().subtract(
                  const Duration(days: 365 * 5),
                ),
                firstDate: DateTime(1990),
                lastDate: DateTime.now(),
              );
              if (date != null) {
                setState(() {
                  _selectedDob = date;
                  _dobController.text =
                      '${date.day}/${date.month}/${date.year}';
                });
              }
            },
            validator: (v) => _selectedDob == null ? 'Required' : null,
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String?>(
            initialValue: _selectedGender,
            decoration: const InputDecoration(
              labelText: 'Gender',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem<String?>(value: null, child: Text('Select')),
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
            initialValue: _selectedBloodGroup,
            decoration: const InputDecoration(
              labelText: 'Blood Group',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem<String?>(value: null, child: Text('Select')),
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
            controller: _nationalityController,
            decoration: const InputDecoration(
              labelText: 'Nationality',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _religionController,
            decoration: const InputDecoration(
              labelText: 'Religion',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _medicalInfoController,
            decoration: const InputDecoration(
              labelText: 'Medical Information',
              border: OutlineInputBorder(),
              hintText: 'Any medical conditions or allergies',
            ),
            maxLines: 3,
          ),
        ],
      ),
    );
  }

  Widget _buildAcademicInfoPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Academic Information',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 24),
          DropdownButtonFormField<int?>(
            initialValue: _selectedClassId,
            decoration: const InputDecoration(
              labelText: 'Desired Class *',
              border: OutlineInputBorder(),
            ),
            items: [
              const DropdownMenuItem<int?>(value: null, child: Text('Select')),
              ..._classes.map(
                (c) => DropdownMenuItem<int?>(
                  value: c['id'] as int,
                  child: Text(c['name'] as String),
                ),
              ),
            ],
            validator: (v) => v == null ? 'Required' : null,
            onChanged: (value) {
              setState(() {
                _selectedClassId = value;
                _selectedSectionId = null;
              });
              if (value != null) {
                _loadSections(value);
              }
            },
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<int?>(
            initialValue: _selectedSectionId,
            decoration: const InputDecoration(
              labelText: 'Preferred Section',
              border: OutlineInputBorder(),
            ),
            items: [
              const DropdownMenuItem<int?>(value: null, child: Text('Any')),
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
          TextFormField(
            controller: _previousSchoolController,
            decoration: const InputDecoration(
              labelText: 'Previous School',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFamilyInfoPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Family Information',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 24),
          Text(
            'Father\'s Information',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _fatherNameController,
            decoration: const InputDecoration(
              labelText: 'Father\'s Name',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _fatherContactController,
            decoration: const InputDecoration(
              labelText: 'Contact',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _fatherOccupationController,
            decoration: const InputDecoration(
              labelText: 'Occupation',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Mother\'s Information',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _motherNameController,
            decoration: const InputDecoration(
              labelText: 'Mother\'s Name',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _motherContactController,
            decoration: const InputDecoration(
              labelText: 'Contact',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _motherOccupationController,
            decoration: const InputDecoration(
              labelText: 'Occupation',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Guardian Information (if applicable)',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _guardianNameController,
            decoration: const InputDecoration(
              labelText: 'Guardian\'s Name',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _guardianContactController,
            decoration: const InputDecoration(
              labelText: 'Contact',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _guardianRelationController,
            decoration: const InputDecoration(
              labelText: 'Relation',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyContactPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Emergency Contact',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _emergencyNameController,
            decoration: const InputDecoration(
              labelText: 'Name *',
              border: OutlineInputBorder(),
            ),
            validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _emergencyPhoneController,
            decoration: const InputDecoration(
              labelText: 'Phone Number *',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.phone,
            validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
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
    );
  }

  Widget _buildAddressPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Address Information',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _addressController,
            decoration: const InputDecoration(
              labelText: 'Address',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _cityController,
            decoration: const InputDecoration(
              labelText: 'City',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _stateController,
            decoration: const InputDecoration(
              labelText: 'State',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _zipCodeController,
            decoration: const InputDecoration(
              labelText: 'Zip Code',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 24),
          Text(
            'Transport Preference',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String?>(
            initialValue: _transportRequired,
            decoration: const InputDecoration(
              labelText: 'Transport Required?',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem<String?>(
                value: null,
                child: Text('Select an option'),
              ),
              DropdownMenuItem<String?>(value: 'yes', child: Text('Yes')),
              DropdownMenuItem<String?>(value: 'no', child: Text('No')),
            ],
            onChanged: (value) {
              setState(() {
                _transportRequired = value;
                if (value != 'yes') {
                  _transportRoute = null;
                }
              });
            },
          ),
          if (_transportRequired == 'yes') ...[
            const SizedBox(height: 16),
            DropdownButtonFormField<String?>(
              initialValue: _transportRoute,
              decoration: const InputDecoration(
                labelText: 'Preferred Route',
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('Select a route'),
                ),
                ..._transportRoutes.map(
                  (route) => DropdownMenuItem<String?>(
                    value: route['id'] as String?,
                    child: Text(route['name'] as String),
                  ),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  _transportRoute = value;
                });
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDocumentsPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Documents (Optional)',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'You can upload documents now or later',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          _buildDocumentUploadCard(
            'Birth Certificate',
            'birth_certificate',
            Icons.description,
          ),
          const SizedBox(height: 16),
          _buildDocumentUploadCard(
            'Transfer Certificate',
            'transfer_certificate',
            Icons.school,
          ),
          const SizedBox(height: 16),
          _buildDocumentUploadCard(
            'Previous Marksheet',
            'previous_marksheet',
            Icons.assignment,
          ),
          const SizedBox(height: 16),
          _buildDocumentUploadCard('Photo', 'photo', Icons.camera_alt),
        ],
      ),
    );
  }

  Widget _buildDocumentUploadCard(
    String label,
    String documentType,
    IconData icon,
  ) {
    final hasFile = _documentBytes.containsKey(documentType);
    final fileName = _documentNames[documentType];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: Theme.of(context).textTheme.titleSmall),
                  if (hasFile && fileName != null)
                    Text(
                      fileName,
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: Colors.green),
                    ),
                ],
              ),
            ),
            if (hasFile)
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  setState(() {
                    _documentBytes.remove(documentType);
                    _documentNames.remove(documentType);
                  });
                },
              ),
            OutlinedButton(
              onPressed: () => _pickDocument(documentType),
              child: Text(hasFile ? 'Change' : 'Upload'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDocument(String documentType) async {
    try {
      if (documentType == 'photo') {
        final picker = ImagePicker();
        final image = await picker.pickImage(source: ImageSource.gallery);
        if (image != null) {
          final bytes = await image.readAsBytes();
          setState(() {
            _documentBytes[documentType] = bytes;
            _documentNames[documentType] = image.name;
          });
        }
      } else {
        final result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'doc', 'docx'],
        );
        if (result != null && result.files.single.bytes != null) {
          // Web: use bytes directly
          setState(() {
            _documentBytes[documentType] = result.files.single.bytes!;
            _documentNames[documentType] = result.files.single.name;
          });
        } else if (result != null && result.files.single.path != null) {
          // Mobile: read from path
          final file = File(result.files.single.path!);
          final bytes = await file.readAsBytes();
          setState(() {
            _documentBytes[documentType] = bytes;
            _documentNames[documentType] = result.files.single.name;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }
}
