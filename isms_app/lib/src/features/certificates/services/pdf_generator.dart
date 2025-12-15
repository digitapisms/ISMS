import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../domain/certificate.dart';
import '../domain/certificate_template.dart';
import '../domain/certificate_type.dart';

class CertificatePdfGenerator {
  /// Generate PDF from certificate template and data
  Future<Uint8List> generatePdf({
    required CertificateTemplate template,
    required Certificate certificate,
    required Map<String, String> variableValues,
  }) async {
    final pdf = pw.Document();

    // Replace template variables with actual values
    String content = template.templateContent;
    for (var variable in template.templateVariables) {
      final value = variableValues[variable] ?? '';
      content = content.replaceAll('{$variable}', value);
    }

    // Pre-load images before building PDF
    pw.MemoryImage? backgroundImage;
    if (template.backgroundImageUrl != null) {
      try {
        backgroundImage = await _loadImage(template.backgroundImageUrl!);
      } catch (e) {
        // Ignore image loading errors
      }
    }

    pw.MemoryImage? signature1Image;
    if (template.digitalSignature1Url != null) {
      try {
        signature1Image = await _loadImage(template.digitalSignature1Url!);
      } catch (e) {
        // Ignore image loading errors
      }
    }

    pw.MemoryImage? signature2Image;
    if (template.digitalSignature2Url != null) {
      try {
        signature2Image = await _loadImage(template.digitalSignature2Url!);
      } catch (e) {
        // Ignore image loading errors
      }
    }

    pw.MemoryImage? sealImage;
    if (template.sealImageUrl != null) {
      try {
        sealImage = await _loadImage(template.sealImageUrl!);
      } catch (e) {
        // Ignore image loading errors
      }
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(0),
        build: (pw.Context context) {
          return pw.Stack(
            children: [
              // Background image if available
              if (backgroundImage != null)
                pw.Positioned.fill(
                  child: pw.Image(
                    backgroundImage,
                    fit: pw.BoxFit.cover,
                  ),
                ),
              
              // Main content
              pw.Padding(
                padding: const pw.EdgeInsets.all(80),
                child: pw.Column(
                  mainAxisAlignment: pw.MainAxisAlignment.center,
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    // Certificate title
                    pw.Text(
                      template.certificateType.displayName,
                      style: pw.TextStyle(
                        fontSize: 32,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.black,
                      ),
                      textAlign: pw.TextAlign.center,
                    ),
                    pw.SizedBox(height: 40),
                    
                    // Certificate content
                    pw.Text(
                      content,
                      style: const pw.TextStyle(
                        fontSize: 16,
                        height: 1.5,
                        color: PdfColors.black,
                      ),
                      textAlign: pw.TextAlign.center,
                    ),
                    pw.SizedBox(height: 60),
                    
                    // Signatures section
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                      children: [
                        // Signature 1
                        if (template.signature1Label != null)
                          pw.Column(
                            children: [
                              if (signature1Image != null)
                                pw.Image(
                                  signature1Image,
                                  width: 150,
                                  height: 60,
                                )
                              else
                                pw.Container(
                                  width: 150,
                                  height: 60,
                                  decoration: pw.BoxDecoration(
                                    border: pw.Border.all(color: PdfColors.black),
                                  ),
                                  child: template.signature1UserId != null
                                      ? pw.Center(
                                          child: pw.Text(
                                            'Signature',
                                            style: const pw.TextStyle(fontSize: 12),
                                          ),
                                        )
                                      : null,
                                ),
                              pw.SizedBox(height: 8),
                              pw.Text(
                                template.signature1Label!,
                                style: const pw.TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        
                        // Seal if available
                        if (sealImage != null)
                          pw.Image(
                            sealImage,
                            width: 80,
                            height: 80,
                          ),
                        
                        // Signature 2
                        if (template.signature2Label != null)
                          pw.Column(
                            children: [
                              if (signature2Image != null)
                                pw.Image(
                                  signature2Image,
                                  width: 150,
                                  height: 60,
                                )
                              else
                                pw.Container(
                                  width: 150,
                                  height: 60,
                                  decoration: pw.BoxDecoration(
                                    border: pw.Border.all(color: PdfColors.black),
                                  ),
                                  child: template.signature2UserId != null
                                      ? pw.Center(
                                          child: pw.Text(
                                            'Signature',
                                            style: const pw.TextStyle(fontSize: 12),
                                          ),
                                        )
                                      : null,
                                ),
                              pw.SizedBox(height: 8),
                              pw.Text(
                                template.signature2Label!,
                                style: const pw.TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                      ],
                    ),
                    
                    // Certificate number at bottom
                    pw.SizedBox(height: 40),
                    pw.Text(
                      'Certificate No: ${certificate.certificateNumber}',
                      style: const pw.TextStyle(
                        fontSize: 10,
                        color: PdfColors.grey700,
                      ),
                    ),
                    pw.Text(
                      'Issued Date: ${certificate.issuedDate.year}-${certificate.issuedDate.month.toString().padLeft(2, '0')}-${certificate.issuedDate.day.toString().padLeft(2, '0')}',
                      style: const pw.TextStyle(
                        fontSize: 10,
                        color: PdfColors.grey700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  Future<pw.MemoryImage> _loadImage(String url) async {
    final response = await http.get(Uri.parse(url));
    return pw.MemoryImage(response.bodyBytes);
  }

  /// Preview PDF
  Future<void> previewPdf({
    required CertificateTemplate template,
    required Certificate certificate,
    required Map<String, String> variableValues,
  }) async {
    final pdfBytes = await generatePdf(
      template: template,
      certificate: certificate,
      variableValues: variableValues,
    );
    
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdfBytes,
    );
  }

  /// Save PDF to file
  Future<File> savePdfToFile({
    required CertificateTemplate template,
    required Certificate certificate,
    required Map<String, String> variableValues,
    required String filePath,
  }) async {
    final pdfBytes = await generatePdf(
      template: template,
      certificate: certificate,
      variableValues: variableValues,
    );
    
    final file = File(filePath);
    await file.writeAsBytes(pdfBytes);
    return file;
  }
}

