import '../../../core/network/supabase_client.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/certificate.dart';
import '../domain/certificate_template.dart';
import 'pdf_generator.dart';

class CertificateEmailService {
  final SupabaseClient _client = SupabaseManager.client;
  final CertificatePdfGenerator _pdfGenerator = CertificatePdfGenerator();

  /// Send certificate via email
  Future<void> sendCertificateViaEmail({
    required Certificate certificate,
    required CertificateTemplate template,
    required Map<String, String> variableValues,
    required String recipientEmail,
    String? subject,
    String? message,
  }) async {
    // Generate PDF
    final pdfBytes = await _pdfGenerator.generatePdf(
      template: template,
      certificate: certificate,
      variableValues: variableValues,
    );

    // Upload PDF to Supabase Storage
    final fileName = 'certificate_${certificate.certificateNumber}.pdf';
    final filePath = 'certificates/${certificate.schoolId}/$fileName';
    
    await _client.storage
        .from('certificates')
        .uploadBinary(
          filePath,
          pdfBytes,
          fileOptions: const FileOptions(
            contentType: 'application/pdf',
            upsert: true,
          ),
        );

    // Get public URL
    final pdfUrl = _client.storage
        .from('certificates')
        .getPublicUrl(filePath);

    // Update certificate with PDF URL
    // TODO: Update certificate record with pdf_url

    // Call Edge Function to send email
    try {
      await _client.functions.invoke(
        'send-certificate-email',
        body: {
          'to': recipientEmail,
          'subject': subject ?? 'Your Certificate - ${certificate.certificateNumber}',
          'message': message ?? 'Please find your certificate attached.',
          'certificate_number': certificate.certificateNumber,
          'pdf_url': pdfUrl,
        },
      );
    } catch (e) {
      // If Edge Function doesn't exist, log error
      print('Email service not configured: $e');
      throw Exception('Email service is not available. Please configure email settings.');
    }
  }

  /// Send bulk certificates via email
  Future<Map<String, dynamic>> sendBulkCertificates({
    required List<Certificate> certificates,
    required CertificateTemplate template,
    required Map<String, Map<String, String>> variableValuesMap, // certificateId -> variableValues
  }) async {
    int successCount = 0;
    int failCount = 0;
    final errors = <String>[];

    for (final certificate in certificates) {
      try {
        final variableValues = variableValuesMap[certificate.id] ?? {};
        final recipientEmail = variableValues['email'] ?? '';
        
        if (recipientEmail.isEmpty) {
          failCount++;
          errors.add('${certificate.recipientName}: No email address');
          continue;
        }

        await sendCertificateViaEmail(
          certificate: certificate,
          template: template,
          variableValues: variableValues,
          recipientEmail: recipientEmail,
        );
        successCount++;
      } catch (e) {
        failCount++;
        errors.add('${certificate.recipientName}: $e');
      }
    }

    return {
      'success_count': successCount,
      'fail_count': failCount,
      'errors': errors,
    };
  }
}

