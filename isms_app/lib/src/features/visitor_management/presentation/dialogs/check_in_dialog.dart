import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/visitor_providers.dart';
import '../../domain/visit.dart';
import '../../domain/visitor.dart';
import '../../domain/visitor_type.dart';
import '../../../authentication/application/auth_providers.dart';
import '../../../student_management/application/student_providers.dart';

class CheckInDialog extends ConsumerStatefulWidget {
  const CheckInDialog({super.key});

  @override
  ConsumerState<CheckInDialog> createState() => _CheckInDialogState();
}

class _CheckInDialogState extends ConsumerState<CheckInDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _idNumberController = TextEditingController();
  final _purposeDescriptionController = TextEditingController();
  final _vehicleNumberController = TextEditingController();
  
  VisitorType _visitorType = VisitorType.guest;
  VisitPurpose _visitPurpose = VisitPurpose.meeting;
  HostType _hostType = HostType.staff;
  String? _selectedHostId;
  String? _selectedStudentId;
  String _entryGate = 'Main Gate';
  int _numberOfVisitors = 1;
  bool _isEscortRequired = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _idNumberController.dispose();
    _purposeDescriptionController.dispose();
    _vehicleNumberController.dispose();
    super.dispose();
  }

  Future<void> _checkIn() async {
    if (!_formKey.currentState!.validate()) return;

    final repo = ref.read(visitorRepositoryProvider);
    final currentUser = ref.read(currentUserProvider).value;
    if (currentUser?.id == null) return;

    // Check if visitor exists by phone
    Visitor? visitor;
    if (_phoneController.text.trim().isNotEmpty) {
      visitor = await repo.findVisitorByPhone(_phoneController.text.trim());
    }

    // Create visitor if doesn't exist
    if (visitor == null) {
      visitor = Visitor(
        id: '',
        schoolId: repo.schoolId ?? '',
        visitorIdNumber: _idNumberController.text.trim().isEmpty
            ? null
            : _idNumberController.text.trim(),
        fullName: _nameController.text.trim(),
        phoneNumber: _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
        visitorType: _visitorType,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      visitor = await repo.createVisitor(visitor);
    }

    // Determine host
    final hostId = _selectedHostId ?? _selectedStudentId;
    if (hostId == null && _hostType != HostType.department) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a host')),
      );
      return;
    }

    // Get host name (placeholder for now)
    final hostName = 'Host Name'; // TODO: Fetch from student/staff data

    // Create visit
    final visit = Visit(
      id: '',
      schoolId: repo.schoolId ?? '',
      visitorId: visitor.id,
      visitPurpose: _visitPurpose,
      purposeDescription: _purposeDescriptionController.text.trim().isEmpty
          ? null
          : _purposeDescriptionController.text.trim(),
      hostType: _hostType,
      hostId: hostId,
      hostName: hostName,
      entryGate: _entryGate,
      vehicleNumber: _vehicleNumberController.text.trim().isEmpty
          ? null
          : _vehicleNumberController.text.trim(),
      numberOfVisitors: _numberOfVisitors,
      isEscortRequired: _isEscortRequired,
      createdBy: currentUser!.id,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    try {
      final createdVisit = await repo.createVisit(visit);
      
      // Generate badge and check in
      final badgeNumber = await repo.generateBadgeNumber();
      await repo.issueBadge(createdVisit.id, badgeNumber, currentUser.id);
      await repo.checkIn(createdVisit.id, badgeNumber: badgeNumber, entryGate: _entryGate);
      
      if (mounted) {
        Navigator.pop(context);
        ref.invalidate(activeVisitsProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Visitor checked in successfully. Badge: $badgeNumber'),
          ),
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
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Visitor Check-In',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Full Name *',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter visitor name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _idNumberController,
                  decoration: const InputDecoration(
                    labelText: 'ID Number (CNIC/Passport)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<VisitorType>(
                  value: _visitorType,
                  decoration: const InputDecoration(
                    labelText: 'Visitor Type',
                    border: OutlineInputBorder(),
                  ),
                  items: VisitorType.values.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(type.displayName),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _visitorType = value);
                    }
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<VisitPurpose>(
                  value: _visitPurpose,
                  decoration: const InputDecoration(
                    labelText: 'Visit Purpose *',
                    border: OutlineInputBorder(),
                  ),
                  items: VisitPurpose.values.map((purpose) {
                    return DropdownMenuItem(
                      value: purpose,
                      child: Text(purpose.displayName),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _visitPurpose = value);
                    }
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _purposeDescriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Purpose Description',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<HostType>(
                  value: _hostType,
                  decoration: const InputDecoration(
                    labelText: 'Host Type *',
                    border: OutlineInputBorder(),
                  ),
                  items: HostType.values.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(type.displayName),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _hostType = value;
                        _selectedHostId = null;
                        _selectedStudentId = null;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
                if (_hostType == HostType.student)
                  studentsAsync.when(
                    data: (students) {
                      return DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: 'Select Student',
                          border: OutlineInputBorder(),
                        ),
                        items: students.map((student) {
                          return DropdownMenuItem(
                            value: student.id,
                            child: Text('${student.fullName} (${student.admissionNo})'),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedStudentId = value;
                            _selectedHostId = null;
                          });
                        },
                        validator: (value) {
                          if (_hostType == HostType.student && value == null) {
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
                TextFormField(
                  controller: _vehicleNumberController,
                  decoration: const InputDecoration(
                    labelText: 'Vehicle Number (Optional)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Text('Number of Visitors: '),
                    IconButton(
                      icon: const Icon(Icons.remove),
                      onPressed: () {
                        if (_numberOfVisitors > 1) {
                          setState(() => _numberOfVisitors--);
                        }
                      },
                    ),
                    Text('$_numberOfVisitors'),
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () {
                        setState(() => _numberOfVisitors++);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                CheckboxListTile(
                  title: const Text('Escort Required'),
                  value: _isEscortRequired,
                  onChanged: (value) {
                    setState(() => _isEscortRequired = value ?? false);
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _checkIn,
                      child: const Text('Check In'),
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

