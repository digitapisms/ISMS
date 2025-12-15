import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../authentication/application/auth_providers.dart';
import '../application/student_providers.dart';

class EditApplicationScreen extends ConsumerStatefulWidget {
  const EditApplicationScreen({super.key, required this.applicationId});

  final String applicationId;

  @override
  ConsumerState<EditApplicationScreen> createState() =>
      _EditApplicationScreenState();
}

class _EditApplicationScreenState extends ConsumerState<EditApplicationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _dobController = TextEditingController();
  final _nationalityController = TextEditingController();
  final _religionController = TextEditingController();
  final _medicalInfoController = TextEditingController();
  final _previousSchoolController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _zipCodeController = TextEditingController();

  String? _selectedGender;
  String? _selectedBloodGroup;
  int? _selectedClassId;
  String? _transportRequired;
  String? _transportRoute;
  DateTime? _selectedDob;
  List<Map<String, dynamic>> _classes = [];
  List<Map<String, dynamic>> _transportRoutes = [];
  bool _isLoading = false;
  bool _isLoadingData = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final repo = ref.read(studentRepositoryProvider);
      final appDetails = await repo.fetchApplicationDetails(
        widget.applicationId,
      );

      if (appDetails != null) {
        final studentDetails =
            appDetails['student_details'] as Map<String, dynamic>?;
        final classes = await repo.fetchClasses();

        setState(() {
          _classes = classes;
          if (studentDetails != null) {
            _firstNameController.text =
                studentDetails['first_name'] as String? ?? '';
            _lastNameController.text =
                studentDetails['last_name'] as String? ?? '';
            _selectedGender = studentDetails['gender'] as String?;
            _selectedBloodGroup = studentDetails['blood_group'] as String?;
            _nationalityController.text =
                studentDetails['nationality'] as String? ?? '';
            _religionController.text =
                studentDetails['religion'] as String? ?? '';
            _medicalInfoController.text =
                studentDetails['medical_info'] as String? ?? '';
            _previousSchoolController.text =
                appDetails['previous_school'] as String? ?? '';
            _addressController.text =
                studentDetails['address'] as String? ?? '';
            _cityController.text = studentDetails['city'] as String? ?? '';
            _stateController.text = studentDetails['state'] as String? ?? '';
            _zipCodeController.text =
                studentDetails['zip_code'] as String? ?? '';

            if (studentDetails['dob'] != null) {
              _selectedDob = DateTime.parse(studentDetails['dob']);
              _dobController.text = DateFormat(
                'yyyy-MM-dd',
              ).format(_selectedDob!);
            }

            _selectedClassId = appDetails['desired_class_id'] as int?;
            // Handle null transport_required - default to null if not set
            if (studentDetails['transport_required'] != null) {
              _transportRequired = studentDetails['transport_required'] == true
                  ? 'yes'
                  : 'no';
            } else {
              _transportRequired = null;
            }
            _transportRoute = studentDetails['transport_route'] as String?;
          }
        });
      }

      final routes = await repo.fetchTransportRoutes();
      setState(() {
        _transportRoutes = routes;
        _isLoadingData = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingData = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading data: $e')));
      }
    }
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate:
          _selectedDob ??
          DateTime.now().subtract(const Duration(days: 365 * 5)),
      firstDate: DateTime(1990),
      lastDate: DateTime.now(),
    );
    if (date != null) {
      setState(() {
        _selectedDob = date;
        _dobController.text = DateFormat('yyyy-MM-dd').format(date);
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final authUser = ref.read(authStateProvider);
      if (authUser == null) throw Exception('Not authenticated');

      final repo = ref.read(studentRepositoryProvider);
      await repo.updateStudentApplication(
        applicationId: widget.applicationId,
        userId: authUser.id,
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
        address: _addressController.text.trim().isEmpty
            ? null
            : _addressController.text.trim(),
        city: _cityController.text.trim().isEmpty
            ? null
            : _cityController.text.trim(),
        state: _stateController.text.trim().isEmpty
            ? null
            : _stateController.text.trim(),
        zipCode: _zipCodeController.text.trim().isEmpty
            ? null
            : _zipCodeController.text.trim(),
        transportRequired: _transportRequired,
        transportRoute: _transportRoute,
      );

      if (!mounted) return;

      ref.invalidate(applicationStatusProvider(authUser.id));
      ref.invalidate(applicationDetailProvider(widget.applicationId));

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Application updated successfully')),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _dobController.dispose();
    _nationalityController.dispose();
    _religionController.dispose();
    _medicalInfoController.dispose();
    _previousSchoolController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _zipCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingData) {
      return Scaffold(
        appBar: AppBar(title: const Text('Edit Application')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Application'),
        actions: [
          if (_isLoading)
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
              onPressed: _save,
              tooltip: 'Save',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Personal Information',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _firstNameController,
                      decoration: const InputDecoration(
                        labelText: 'First Name',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) =>
                          (v == null || v.isEmpty) ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _lastNameController,
                      decoration: const InputDecoration(
                        labelText: 'Last Name',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) =>
                          (v == null || v.isEmpty) ? 'Required' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _dobController,
                decoration: InputDecoration(
                  labelText: 'Date of Birth',
                  border: const OutlineInputBorder(),
                  suffixIcon: const Icon(Icons.calendar_today),
                ),
                readOnly: true,
                onTap: _selectDate,
                validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _selectedGender,
                decoration: const InputDecoration(
                  labelText: 'Gender',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'male', child: Text('Male')),
                  DropdownMenuItem(value: 'female', child: Text('Female')),
                  DropdownMenuItem(value: 'other', child: Text('Other')),
                ],
                onChanged: (v) => setState(() => _selectedGender = v),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _selectedBloodGroup,
                decoration: const InputDecoration(
                  labelText: 'Blood Group',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'A+', child: Text('A+')),
                  DropdownMenuItem(value: 'A-', child: Text('A-')),
                  DropdownMenuItem(value: 'B+', child: Text('B+')),
                  DropdownMenuItem(value: 'B-', child: Text('B-')),
                  DropdownMenuItem(value: 'AB+', child: Text('AB+')),
                  DropdownMenuItem(value: 'AB-', child: Text('AB-')),
                  DropdownMenuItem(value: 'O+', child: Text('O+')),
                  DropdownMenuItem(value: 'O-', child: Text('O-')),
                ],
                onChanged: (v) => setState(() => _selectedBloodGroup = v),
              ),
              const SizedBox(height: 24),
              Text(
                'Academic Information',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int?>(
                initialValue: _selectedClassId,
                decoration: const InputDecoration(
                  labelText: 'Desired Class',
                  border: OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem(value: null, child: Text('Select')),
                  ..._classes.map(
                    (c) => DropdownMenuItem<int?>(
                      value: c['id'] as int,
                      child: Text(c['name'] as String),
                    ),
                  ),
                ],
                onChanged: (v) => setState(() => _selectedClassId = v),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _previousSchoolController,
                decoration: const InputDecoration(
                  labelText: 'Previous School',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Transport Information',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String?>(
                initialValue: _transportRequired,
                decoration: const InputDecoration(
                  labelText: 'Transport Required',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem<String?>(value: null, child: Text('Select')),
                  DropdownMenuItem(value: 'no', child: Text('No')),
                  DropdownMenuItem(value: 'yes', child: Text('Yes')),
                ],
                onChanged: (v) => setState(() => _transportRequired = v),
              ),
              if (_transportRequired == 'yes') ...[
                const SizedBox(height: 16),
                DropdownButtonFormField<String?>(
                  initialValue: _transportRoute,
                  decoration: const InputDecoration(
                    labelText: 'Transport Route',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('Select Route'),
                    ),
                    ..._transportRoutes.map(
                      (r) => DropdownMenuItem<String?>(
                        value: r['id'] as String,
                        child: Text(r['name'] as String),
                      ),
                    ),
                  ],
                  onChanged: (v) => setState(() => _transportRoute = v),
                ),
              ],
              const SizedBox(height: 24),
              Text(
                'Additional Information',
                style: Theme.of(context).textTheme.titleLarge,
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
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              Text('Address', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Address',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _cityController,
                      decoration: const InputDecoration(
                        labelText: 'City',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _stateController,
                      decoration: const InputDecoration(
                        labelText: 'State',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
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
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isLoading ? null : _save,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save Changes'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
