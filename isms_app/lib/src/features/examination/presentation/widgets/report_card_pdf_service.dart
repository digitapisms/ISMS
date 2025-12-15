import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../domain/report_card.dart';
import '../../../student_management/domain/student.dart';
import '../../../school_registration/domain/school.dart';

class ReportCardPdfService {
  static Future<void> generateAndPrint({
    required ReportCard reportCard,
    Student? student,
    School? school,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              _buildHeader(school),
              pw.SizedBox(height: 20),
              pw.Divider(),
              pw.SizedBox(height: 20),
              // Title
              pw.Center(
                child: pw.Text(
                  'REPORT CARD',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 20),
              // Student Information
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Student Information',
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    if (student != null) ...[
                      _buildInfoRow('Name:', student.fullName),
                      _buildInfoRow('Admission No:', student.admissionNo),
                      if (student.className != null)
                        _buildInfoRow('Class:', student.className!),
                    ],
                    _buildInfoRow('Academic Year:', reportCard.academicYear),
                    _buildInfoRow('Term:', reportCard.term),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),
              // Academic Performance
              pw.Text(
                'Academic Performance',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 12),
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Column(
                  children: [
                    if (reportCard.overallPercentage != null)
                      _buildSummaryRow(
                        'Overall Percentage:',
                        '${reportCard.overallPercentage!.toStringAsFixed(2)}%',
                      ),
                    if (reportCard.overallGrade != null)
                      _buildSummaryRow(
                        'Overall Grade:',
                        reportCard.overallGrade!,
                      ),
                    if (reportCard.division != null)
                      _buildSummaryRow('Division:', reportCard.division!),
                    if (reportCard.classPosition != null)
                      _buildSummaryRow(
                        'Class Position:',
                        '${reportCard.classPosition} out of ${reportCard.totalStudents ?? 0}',
                      ),
                    if (reportCard.attendancePercentage != null)
                      _buildSummaryRow(
                        'Attendance:',
                        '${reportCard.attendancePercentage!.toStringAsFixed(2)}%',
                      ),
                  ],
                ),
              ),
              if (reportCard.teacherRemarks != null ||
                  reportCard.principalRemarks != null) ...[
                pw.SizedBox(height: 20),
                pw.Text(
                  'Remarks',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 12),
                if (reportCard.teacherRemarks != null)
                  pw.Container(
                    padding: const pw.EdgeInsets.all(12),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.grey100,
                      borderRadius: pw.BorderRadius.circular(4),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'Teacher Remarks:',
                          style: pw.TextStyle(
                            fontSize: 12,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          reportCard.teacherRemarks!,
                          style: const pw.TextStyle(fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                if (reportCard.principalRemarks != null) ...[
                  pw.SizedBox(height: 8),
                  pw.Container(
                    padding: const pw.EdgeInsets.all(12),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.grey100,
                      borderRadius: pw.BorderRadius.circular(4),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'Principal Remarks:',
                          style: pw.TextStyle(
                            fontSize: 12,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          reportCard.principalRemarks!,
                          style: const pw.TextStyle(fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
              pw.Spacer(),
              // Footer
              pw.Divider(),
              pw.SizedBox(height: 10),
              pw.Center(
                child: pw.Text(
                  'This is a computer-generated report card. No signature required.',
                  style: pw.TextStyle(
                    fontSize: 10,
                    color: PdfColors.grey600,
                    fontStyle: pw.FontStyle.italic,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  static pw.Widget _buildHeader(School? school) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: school != null
              ? [
                  pw.Text(
                    school.name,
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  if (school.address != null && school.address!.isNotEmpty)
                    pw.Text(
                      school.address!,
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                  pw.Text(
                    'Phone: ${school.phone}',
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                  pw.Text(
                    'Email: ${school.email}',
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                ]
              : [
                  pw.Text(
                    'School Management System',
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text(
              'REPORT CARD',
              style: pw.TextStyle(
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blue700,
              ),
            ),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildInfoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Row(
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(width: 8),
          pw.Text(value, style: const pw.TextStyle(fontSize: 11)),
        ],
      ),
    );
  }

  static pw.Widget _buildSummaryRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
