import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../authentication/application/auth_providers.dart';
import '../../../student_management/domain/student.dart';
import '../../../student_management/application/student_providers.dart';
import '../../domain/certificate.dart';
import '../../domain/certificate_template.dart';
import '../../domain/certificate_type.dart';
import '../../domain/certificate_data.dart';
import '../../application/certificates_providers.dart';

class BulkGenerateDialog extends ConsumerStatefulWidget {
  final CertificateTemplate template;

  const BulkGenerateDialog({super.key, required this.template});

  @override
  ConsumerState<BulkGenerateDialog> createState() => _BulkGenerateDialogState();
}

class _BulkGenerateDialogState extends ConsumerState<BulkGenerateDialog> {
  final Set<String> _selectedRecipients = {};
  bool _selectAll = false;

  @override
  Widget build(BuildContext context) {
    final studentsAsync = ref.watch(studentsProvider);

    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Bulk Generate Certificates',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(),
            CheckboxListTile(
              title: const Text('Select All'),
              value: _selectAll,
              onChanged: (value) {
                setState(() {
                  _selectAll = value ?? false;
                  if (_selectAll) {
                    studentsAsync.whenData((students) {
                      _selectedRecipients.clear();
                      _selectedRecipients.addAll(students.map((s) => s.id));
                    });
                  } else {
                    _selectedRecipients.clear();
                  }
                });
              },
            ),
            const Divider(),
            Expanded(
              child: studentsAsync.when(
                data: (students) {
                  if (students.isEmpty) {
                    return const Center(child: Text('No students available'));
                  }

                  return ListView.builder(
                    itemCount: students.length,
                    itemBuilder: (context, index) {
                      final student = students[index];
                      final isSelected = _selectedRecipients.contains(
                        student.id,
                      );

                      return CheckboxListTile(
                        title: Text(student.fullName),
                        subtitle: Text('Admission: ${student.admissionNo}'),
                        value: isSelected,
                        onChanged: (value) {
                          setState(() {
                            if (value == true) {
                              _selectedRecipients.add(student.id);
                            } else {
                              _selectedRecipients.remove(student.id);
                              _selectAll = false;
                            }
                          });
                        },
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Center(child: Text('Error: $error')),
              ),
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Selected: ${_selectedRecipients.length}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                  ),
                ),
                Row(
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _selectedRecipients.isEmpty
                          ? null
                          : () => _generateBulk(),
                      child: Text('Generate (${_selectedRecipients.length})'),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _generateBulk() async {
    if (_selectedRecipients.isEmpty) return;

    final repo = ref.read(certificatesRepositoryProvider);
    final currentUser = ref.read(currentUserProvider).value;
    if (currentUser?.id == null) return;

    final studentsAsync = ref.read(studentsProvider);
    final students = studentsAsync.value;
    if (students == null) return;

    int successCount = 0;
    int failCount = 0;

    for (final studentId in _selectedRecipients) {
      final student = students.firstWhere((s) => s.id == studentId);

      try {
        // Create appropriate certificate data based on template type
        final certificateData = _createCertificateData(
          widget.template.certificateType,
          student,
        );

        final certificate = Certificate(
          id: '',
          schoolId: repo.schoolId ?? '',
          templateId: widget.template.id,
          certificateNumber: '',
          certificateType: widget.template.certificateType,
          recipientType: RecipientType.student,
          recipientId: student.id,
          recipientName: student.fullName,
          issuedDate: DateTime.now(),
          issuedBy: currentUser!.id,
          certificateData: certificateData,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await repo.generateCertificate(certificate);
        successCount++;
      } catch (e) {
        failCount++;
      }
    }

    if (mounted) {
      Navigator.pop(context);
      ref.invalidate(certificateTemplatesProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Generated: $successCount, Failed: $failCount'),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  CertificateData? _createCertificateData(
    CertificateType certificateType,
    Student student,
  ) {
    switch (certificateType) {
      case CertificateType.leaving:
        return EducationalCertificateData(
          programName: student.classId?.toString() ?? 'General Course',
          programDuration: '1 Year',
          enrollmentDate: DateTime.now().subtract(const Duration(days: 365)),
          completionDate: DateTime.now(),
          gradeObtained: 'A',
          totalMarks: '850',
          division: 'First',
          institutionName: 'School Name',
          boardUniversity: 'Education Board',
        );
      case CertificateType.achievement:
        return AcademicCertificateData(
          academicYear: '2024-2025',
          semester: '1',
          courseName: 'General Achievement',
          courseCode: 'GEN001',
          creditsEarned: '3',
          gradePoints: '4.0',
          cgpa: '3.8',
          sgpa: '3.9',
          rankInClass: '1',
          isPassWithDistinction: true,
        );
      case CertificateType.participation:
        return ExperienceCertificateData(
          position: 'Participant',
          department: 'General',
          employmentStartDate: DateTime.now(),
          employmentEndDate: DateTime.now(),
          responsibilities: 'Active participation',
          achievements: 'Excellent performance',
          supervisorName: 'Teacher',
          supervisorPosition: 'Supervisor',
          reasonForLeaving: 'Course completion',
          isEligibleForRehire: true,
        );
      default:
        return null;
    }
  }
}
