import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr/qr.dart';

import '../../../../core/utils/qr_code_generator.dart';

class IdCardPdfGenerator {
  /// Generate and save PDF for student ID card
  static Future<File> generatePdf({
    required String studentName,
    required String admissionNo,
    String? className,
    String? sectionName,
    String? photoUrl,
    String? schoolName,
    String? studentId,
  }) async {
    final pdf = pw.Document();

    // Generate QR code data
    final qrData = QrCodeGenerator.generateStudentIdQrData(
      admissionNo: admissionNo,
      studentName: studentName,
      studentId: studentId,
    );

    // Generate QR code matrix
    final qrCode = QrCodeGenerator.generateQrCode(qrData);

    // Load photo if available
    pw.ImageProvider? photoProvider;
    if (photoUrl != null && photoUrl.isNotEmpty) {
      try {
        if (photoUrl.startsWith('http')) {
          final response = await http.get(Uri.parse(photoUrl));
          if (response.statusCode == 200) {
            photoProvider = pw.MemoryImage(response.bodyBytes);
          }
        } else {
          final file = File(photoUrl);
          if (await file.exists()) {
            final bytes = await file.readAsBytes();
            photoProvider = pw.MemoryImage(bytes);
          }
        }
      } catch (e) {
        // Photo loading failed, will use placeholder
        print('Failed to load photo: $e');
      }
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat(
          85.6 * 72 / 25.4,
          53.98 * 72 / 25.4,
          marginAll: 0,
        ), // ID card size (mm to points)
        build: (pw.Context context) {
          return pw.Container(
            decoration: pw.BoxDecoration(
              gradient: pw.LinearGradient(
                begin: pw.Alignment.topLeft,
                end: pw.Alignment.bottomRight,
                colors: [PdfColors.blue700, PdfColors.blue900],
              ),
              borderRadius: pw.BorderRadius.circular(8),
            ),
            padding: const pw.EdgeInsets.all(12),
            child: pw.Row(
              children: [
                // Photo section
                pw.Container(
                  width: 60,
                  height: 60,
                  decoration: pw.BoxDecoration(
                    color: PdfColors.white,
                    borderRadius: pw.BorderRadius.circular(4),
                  ),
                  child: photoProvider != null
                      ? pw.ClipRRect(
                          horizontalRadius: 4,
                          verticalRadius: 4,
                          child: pw.Image(photoProvider, fit: pw.BoxFit.cover),
                        )
                      : pw.Center(
                          child: pw.Text(
                            'PHOTO',
                            style: pw.TextStyle(
                              fontSize: 8,
                              color: PdfColors.grey700,
                            ),
                          ),
                        ),
                ),
                pw.SizedBox(width: 12),
                // Details section
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    mainAxisAlignment: pw.MainAxisAlignment.center,
                    children: [
                      pw.Text(
                        schoolName ?? 'ISMS',
                        style: pw.TextStyle(
                          color: PdfColors.white,
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        studentName,
                        style: pw.TextStyle(
                          color: PdfColors.white,
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold,
                        ),
                        maxLines: 1,
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        'Adm No: $admissionNo',
                        style: pw.TextStyle(
                          color: PdfColors.white,
                          fontSize: 8,
                        ),
                      ),
                      if (className != null) ...[
                        pw.SizedBox(height: 2),
                        pw.Text(
                          'Class: $className',
                          style: pw.TextStyle(
                            color: PdfColors.white,
                            fontSize: 8,
                          ),
                        ),
                      ],
                      if (sectionName != null) ...[
                        pw.SizedBox(height: 2),
                        pw.Text(
                          'Section: $sectionName',
                          style: pw.TextStyle(
                            color: PdfColors.white,
                            fontSize: 8,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                // QR Code
                pw.Container(
                  width: 40,
                  height: 40,
                  decoration: pw.BoxDecoration(
                    color: PdfColors.white,
                    borderRadius: pw.BorderRadius.circular(4),
                  ),
                  padding: const pw.EdgeInsets.all(2),
                  child: _buildQrCode(qrCode, 36),
                ),
              ],
            ),
          );
        },
      ),
    );

    // Save PDF to temporary directory
    final output = await getTemporaryDirectory();
    final file = File('${output.path}/student_id_$admissionNo.pdf');
    await file.writeAsBytes(await pdf.save());

    return file;
  }

  /// Print the ID card PDF
  static Future<void> printPdf(File pdfFile) async {
    final bytes = await pdfFile.readAsBytes();
    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => bytes);
  }

  /// Share/download the PDF
  static Future<void> sharePdf(File pdfFile) async {
    final bytes = await pdfFile.readAsBytes();
    await Printing.sharePdf(
      bytes: bytes,
      filename: pdfFile.path.split('/').last,
    );
  }

  /// Build QR code widget for PDF
  /// Note: Using simplified QR code rendering
  /// For full QR code support, consider using qr_flutter to generate image first
  static pw.Widget _buildQrCode(QrCode qrCode, double size) {
    // For now, render a placeholder pattern
    // Full QR code rendering would require accessing module data directly
    // which may vary by qr package version
    return pw.Container(
      width: size,
      height: size,
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        border: pw.Border.all(color: PdfColors.black, width: 1),
      ),
      child: pw.Center(
        child: pw.Text(
          'QR',
          style: pw.TextStyle(
            fontSize: size * 0.3,
            color: PdfColors.black,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
