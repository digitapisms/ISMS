import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/discipline_providers.dart';
import '../../domain/discipline_incident.dart';
import '../../../authentication/application/auth_providers.dart';
import '../../../student_management/application/student_providers.dart';

class IncidentFormDialog extends ConsumerStatefulWidget {
  const IncidentFormDialog({super.key});

  @override
  ConsumerState<IncidentFormDialog> createState() => _IncidentFormDialogState();
}

class _IncidentFormDialogState extends ConsumerState<IncidentFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _categoryController = TextEditingController();

  String? _selectedStudentId;
  IncidentType _incidentType = IncidentType.minor;
  SeverityLevel _severityLevel = SeverityLevel.low;
  DateTime _incidentDate = DateTime.now();

  @override
  void dispose() {
    _descriptionController.dispose();
    _locationController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _selectedStudentId == null) {
      return;
    }

    final repo = ref.read(disciplineRepositoryProvider);
    final currentUser = ref.read(currentUserProvider).value;
    if (currentUser?.id == null) return;

    final incident = DisciplineIncident(
      id: '',
      schoolId: repo.schoolId ?? '',
      studentId: _selectedStudentId!,
      incidentDate: _incidentDate,
      incidentType: _incidentType,
      category: _categoryController.text.trim().isEmpty
          ? null
          : _categoryController.text.trim(),
      description: _descriptionController.text.trim(),
      location: _locationController.text.trim().isEmpty
          ? null
          : _locationController.text.trim(),
      createdBy: currentUser!.id,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    try {
      await repo.createIncident(incident);

      if (mounted) {
        Navigator.pop(context);
        ref.invalidate(disciplineIncidentsProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Incident reported successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final studentsAsync = ref.watch(studentsProvider);

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
                  'Report Incident',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                studentsAsync.when(
                  data: (students) {
                    return DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: 'Student *',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.person),
                      ),
                      items: students.map((student) {
                        return DropdownMenuItem(
                          value: student.id,
                          child: Text('${student.fullName} (${student.admissionNo})'),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() => _selectedStudentId = value);
                      },
                      validator: (value) {
                        if (value == null) {
                          return 'Please select a student';
                        }
                        return null;
                      },
                    );
                  },
                  loading: () => const CircularProgressIndicator(),
                  error: (error, stack) => Text('Error: $error'),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<IncidentType>(
                  value: _incidentType,
                  decoration: InputDecoration(
                    labelText: 'Incident Type *',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: IncidentType.values.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(type.displayName),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _incidentType = value);
                    }
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<SeverityLevel>(
                  value: _severityLevel,
                  decoration: InputDecoration(
                    labelText: 'Severity Level *',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: SeverityLevel.values.map((level) {
                    return DropdownMenuItem(
                      value: level,
                      child: Text(level.displayName),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _severityLevel = value);
                    }
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _categoryController,
                  decoration: InputDecoration(
                    labelText: 'Category (e.g., Bullying, Cheating)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.category),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  decoration: InputDecoration(
                    labelText: 'Description *',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.description),
                  ),
                  maxLines: 4,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter description';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _locationController,
                  decoration: InputDecoration(
                    labelText: 'Location',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.location_on),
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  title: const Text('Incident Date'),
                  subtitle: Text(
                    '${_incidentDate.year}-${_incidentDate.month}-${_incidentDate.day}',
                  ),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _incidentDate,
                      firstDate: DateTime.now().subtract(const Duration(days: 365)),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      setState(() => _incidentDate = picked);
                    }
                  },
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _save,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Report'),
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

