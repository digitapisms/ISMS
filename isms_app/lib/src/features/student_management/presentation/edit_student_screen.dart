import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/student_providers.dart';
import '../domain/student.dart';

class EditStudentScreen extends ConsumerStatefulWidget {
  const EditStudentScreen({super.key, required this.student});

  final Student student;

  @override
  ConsumerState<EditStudentScreen> createState() => _EditStudentScreenState();
}

class _EditStudentScreenState extends ConsumerState<EditStudentScreen> {
  final _formKey = GlobalKey<FormState>();
  late int? _selectedClassId;
  late int? _selectedSectionId;
  late DateTime? _selectedDob;
  late String? _selectedGender;
  late String? _selectedBloodGroup;
  late String _medicalInfo;
  late String _status;

  List<Map<String, dynamic>> _classes = [];
  List<Map<String, dynamic>> _sections = [];
  bool _isLoading = false;
  bool _isLoadingClasses = true;

  @override
  void initState() {
    super.initState();
    _selectedClassId = widget.student.classId;
    _selectedSectionId = widget.student.sectionId;
    _selectedDob = widget.student.dob;
    _selectedGender = widget.student.gender;
    _selectedBloodGroup = widget.student.bloodGroup;
    _medicalInfo = widget.student.medicalInfo ?? '';
    _status = widget.student.status ?? 'active';
    _loadClasses();
  }

  Future<void> _loadClasses() async {
    final repo = ref.read(studentRepositoryProvider);
    final classes = await repo.fetchClasses();
    setState(() {
      _classes = classes;
      _isLoadingClasses = false;
    });
    if (_selectedClassId != null) {
      _loadSections(_selectedClassId!);
    }
  }

  Future<void> _loadSections(int classId) async {
    final repo = ref.read(studentRepositoryProvider);
    final sections = await repo.fetchSections(classId);
    setState(() {
      _sections = sections;
      if (!sections.any((s) => s['id'] == _selectedSectionId)) {
        _selectedSectionId = null;
      }
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final repo = ref.read(studentRepositoryProvider);
      await repo.updateStudent(
        studentId: widget.student.id,
        classId: _selectedClassId,
        sectionId: _selectedSectionId,
        status: _status,
        dob: _selectedDob,
        gender: _selectedGender,
        bloodGroup: _selectedBloodGroup,
        medicalInfo: _medicalInfo.isEmpty ? null : _medicalInfo,
      );

      if (!mounted) return;
      ref.invalidate(studentDetailProvider(widget.student.id));
      ref.invalidate(studentsProvider);
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Student updated successfully')),
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
      appBar: AppBar(
        title: const Text('Edit Student'),
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
            IconButton(icon: const Icon(Icons.save), onPressed: _save),
        ],
      ),
      body: _isLoadingClasses
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Card(
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
                              initialValue: _selectedClassId,
                              decoration: const InputDecoration(
                                labelText: 'Class',
                                border: OutlineInputBorder(),
                              ),
                              items: [
                                const DropdownMenuItem<int?>(
                                  value: null,
                                  child: Text('None'),
                                ),
                                ..._classes.map(
                                  (c) => DropdownMenuItem<int?>(
                                    value: c['id'] as int,
                                    child: Text(c['name'] as String),
                                  ),
                                ),
                              ],
                              onChanged: (value) {
                                setState(() {
                                  _selectedClassId = value;
                                  _selectedSectionId = null;
                                });
                                if (value != null) {
                                  _loadSections(value);
                                } else {
                                  setState(() {
                                    _sections = [];
                                  });
                                }
                              },
                            ),
                            const SizedBox(height: 16),
                            DropdownButtonFormField<int?>(
                              initialValue: _selectedSectionId,
                              decoration: const InputDecoration(
                                labelText: 'Section',
                                border: OutlineInputBorder(),
                              ),
                              items: [
                                const DropdownMenuItem<int?>(
                                  value: null,
                                  child: Text('None'),
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
                              initialValue: _status,
                              decoration: const InputDecoration(
                                labelText: 'Status',
                                border: OutlineInputBorder(),
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: 'active',
                                  child: Text('Active'),
                                ),
                                DropdownMenuItem(
                                  value: 'pending',
                                  child: Text('Pending'),
                                ),
                                DropdownMenuItem(
                                  value: 'inactive',
                                  child: Text('Inactive'),
                                ),
                                DropdownMenuItem(
                                  value: 'alumni',
                                  child: Text('Alumni'),
                                ),
                              ],
                              onChanged: (value) {
                                setState(() {
                                  _status = value!;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Card(
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
                              title: const Text('Date of Birth'),
                              subtitle: Text(
                                _selectedDob != null
                                    ? '${_selectedDob!.day}/${_selectedDob!.month}/${_selectedDob!.year}'
                                    : 'Not set',
                              ),
                              trailing: const Icon(Icons.calendar_today),
                              onTap: () async {
                                final date = await showDatePicker(
                                  context: context,
                                  initialDate: _selectedDob ?? DateTime.now(),
                                  firstDate: DateTime(1990),
                                  lastDate: DateTime.now(),
                                );
                                if (date != null) {
                                  setState(() {
                                    _selectedDob = date;
                                  });
                                }
                              },
                            ),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<String?>(
                              initialValue: _selectedGender,
                              decoration: const InputDecoration(
                                labelText: 'Gender',
                                border: OutlineInputBorder(),
                              ),
                              items: const [
                                DropdownMenuItem<String?>(
                                  value: null,
                                  child: Text('Not specified'),
                                ),
                                DropdownMenuItem(
                                  value: 'Male',
                                  child: Text('Male'),
                                ),
                                DropdownMenuItem(
                                  value: 'Female',
                                  child: Text('Female'),
                                ),
                                DropdownMenuItem(
                                  value: 'Other',
                                  child: Text('Other'),
                                ),
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
                                DropdownMenuItem<String?>(
                                  value: null,
                                  child: Text('Not specified'),
                                ),
                                DropdownMenuItem(
                                  value: 'A+',
                                  child: Text('A+'),
                                ),
                                DropdownMenuItem(
                                  value: 'A-',
                                  child: Text('A-'),
                                ),
                                DropdownMenuItem(
                                  value: 'B+',
                                  child: Text('B+'),
                                ),
                                DropdownMenuItem(
                                  value: 'B-',
                                  child: Text('B-'),
                                ),
                                DropdownMenuItem(
                                  value: 'AB+',
                                  child: Text('AB+'),
                                ),
                                DropdownMenuItem(
                                  value: 'AB-',
                                  child: Text('AB-'),
                                ),
                                DropdownMenuItem(
                                  value: 'O+',
                                  child: Text('O+'),
                                ),
                                DropdownMenuItem(
                                  value: 'O-',
                                  child: Text('O-'),
                                ),
                              ],
                              onChanged: (value) {
                                setState(() {
                                  _selectedBloodGroup = value;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Medical Information',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              initialValue: _medicalInfo,
                              decoration: const InputDecoration(
                                labelText: 'Medical Notes',
                                border: OutlineInputBorder(),
                                hintText: 'Any medical conditions or notes',
                              ),
                              maxLines: 4,
                              onChanged: (value) {
                                _medicalInfo = value;
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
