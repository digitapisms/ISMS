import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/student_providers.dart';
import '../domain/student.dart';
import '../../school_registration/application/school_providers.dart';
import 'widgets/id_card_pdf_generator.dart';

class StudentIdCardScreen extends ConsumerWidget {
  const StudentIdCardScreen({super.key, required this.studentId});

  final String studentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final studentAsync = ref.watch(studentDetailProvider(studentId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Student ID Card'),
      ),
      body: studentAsync.when(
        data: (student) {
          if (student == null) {
            return const Center(child: Text('Student not found'));
          }

          // Convert Student to Map for ID card
          final studentMap = {
            'full_name': student.fullName,
            'admission_no': student.admissionNo,
            'class_name': student.className,
            'section_name': student.sectionName,
            'photo_url': student.avatarUrl,
          };

          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  _buildIdCard(context, studentMap),
                  const SizedBox(height: 24),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ID Card Information',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 12),
                          Text('This is a preview of the student ID card.'),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              ElevatedButton.icon(
                                onPressed: () => _downloadPdf(context, ref, student),
                                icon: const Icon(Icons.download),
                                label: const Text('Download PDF'),
                              ),
                              ElevatedButton.icon(
                                onPressed: () => _printPdf(context, ref, student),
                                icon: const Icon(Icons.print),
                                label: const Text('Print'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Future<void> _downloadPdf(BuildContext context, WidgetRef ref, Student student) async {
    try {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Generating PDF...')));

      final school = ref.read(currentSchoolProvider);
      final pdfFile = await IdCardPdfGenerator.generatePdf(
        studentName: student.fullName,
        admissionNo: student.admissionNo,
        className: student.className,
        sectionName: student.sectionName,
        photoUrl: student.avatarUrl,
        schoolName: school?.name,
        studentId: student.id,
      );

      await IdCardPdfGenerator.sharePdf(pdfFile);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PDF generated successfully')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error generating PDF: $e')));
      }
    }
  }

  Future<void> _printPdf(BuildContext context, WidgetRef ref, Student student) async {
    try {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Preparing for print...')));

      final school = ref.read(currentSchoolProvider);
      final pdfFile = await IdCardPdfGenerator.generatePdf(
        studentName: student.fullName,
        admissionNo: student.admissionNo,
        className: student.className,
        sectionName: student.sectionName,
        photoUrl: student.avatarUrl,
        schoolName: school?.name,
        studentId: student.id,
      );

      await IdCardPdfGenerator.printPdf(pdfFile);

      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Print dialog opened')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error printing: $e')));
      }
    }
  }

  Widget _buildIdCard(BuildContext context, Map<String, dynamic> student) {
    return Container(
      width: 400,
      height: 250,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.primaryContainer,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            // Photo section
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: student['photo_url'] != null
                    ? Image.network(
                        student['photo_url'] as String,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            const Icon(Icons.person, size: 60),
                      )
                    : const Icon(Icons.person, size: 60),
              ),
            ),
            const SizedBox(width: 20),
            // Details section
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'ISMS',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    student['full_name'] as String? ?? 'N/A',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Adm No: ${student['admission_no'] as String? ?? 'N/A'}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                  if (student['class_name'] != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Class: ${student['class_name']}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                  if (student['section_name'] != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Section: ${student['section_name']}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // QR Code section (placeholder)
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.qr_code, size: 40),
            ),
          ],
        ),
      ),
    );
  }
}
