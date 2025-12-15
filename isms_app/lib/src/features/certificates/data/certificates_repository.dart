import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/network/supabase_client.dart';
import '../domain/certificate.dart';
import '../domain/certificate_template.dart';
import '../domain/certificate_field.dart';
import '../domain/certificate_type.dart';
import '../domain/certificate_data.dart';

class CertificatesRepository {
  SupabaseClient get _client => SupabaseManager.client;
  String? _schoolId;

  void setSchoolId(String? schoolId) {
    _schoolId = schoolId;
  }

  String? get schoolId => _schoolId;

  String _requireSchoolId() {
    final id = _schoolId;
    if (id == null) {
      throw Exception('School context is required');
    }
    return id;
  }

  Map<String, dynamic> _withSchoolId(Map<String, dynamic> data) {
    final id = _schoolId;
    if (id == null) return data;
    return {...data, 'school_id': id};
  }

  // ============================================================
  // CERTIFICATE TEMPLATES
  // ============================================================

  Future<CertificateTemplate> createTemplate(
    CertificateTemplate template,
  ) async {
    _requireSchoolId();
    final response = await _client
        .from('certificate_templates')
        .insert(_withSchoolId(template.toJson()))
        .select()
        .single();
    return CertificateTemplate.fromJson(response);
  }

  Future<List<CertificateTemplate>> fetchTemplates({
    CertificateType? certificateType,
    TemplateType? templateType,
    bool? isActive,
  }) async {
    _requireSchoolId();
    var query = _client
        .from('certificate_templates')
        .select()
        .eq('school_id', _requireSchoolId());

    if (certificateType != null) {
      query = query.eq('certificate_type', certificateType.dbValue);
    }
    if (templateType != null) {
      query = query.eq('template_type', templateType.dbValue);
    }
    if (isActive != null) {
      query = query.eq('is_active', isActive);
    }

    final response = await query.order('template_name');
    return (response as List)
        .map(
          (json) => CertificateTemplate.fromJson(json as Map<String, dynamic>),
        )
        .toList();
  }

  Future<CertificateTemplate> updateTemplate(
    CertificateTemplate template,
  ) async {
    _requireSchoolId();
    final response = await _client
        .from('certificate_templates')
        .update(template.toJson())
        .eq('id', template.id)
        .eq('school_id', _requireSchoolId())
        .select()
        .single();
    return CertificateTemplate.fromJson(response);
  }

  Future<void> deleteTemplate(String templateId) async {
    _requireSchoolId();
    await _client
        .from('certificate_templates')
        .delete()
        .eq('id', templateId)
        .eq('school_id', _requireSchoolId());
  }

  // ============================================================
  // CERTIFICATE FIELDS
  // ============================================================

  Future<CertificateField> createField(CertificateField field) async {
    _requireSchoolId();
    final response = await _client
        .from('certificate_fields')
        .insert(_withSchoolId(field.toJson()))
        .select()
        .single();
    return CertificateField.fromJson(response);
  }

  Future<List<CertificateField>> fetchFields(String templateId) async {
    _requireSchoolId();
    final response = await _client
        .from('certificate_fields')
        .select()
        .eq('template_id', templateId)
        .eq('school_id', _requireSchoolId())
        .order('field_order');

    return (response as List)
        .map((json) => CertificateField.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  // ============================================================
  // CERTIFICATES
  // ============================================================

  Future<Certificate> generateCertificate(Certificate certificate) async {
    _requireSchoolId();

    // Generate certificate number if not provided
    if (certificate.certificateNumber.isEmpty) {
      final response = await _client.rpc(
        'generate_certificate_number',
        params: {
          'p_school_id': _requireSchoolId(),
          'p_certificate_type': certificate.certificateType.dbValue,
        },
      );
      final certNumber = response as String;
      final updatedCert = Certificate(
        id: certificate.id,
        schoolId: certificate.schoolId,
        templateId: certificate.templateId,
        certificateNumber: certNumber,
        certificateType: certificate.certificateType,
        recipientType: certificate.recipientType,
        recipientId: certificate.recipientId,
        recipientName: certificate.recipientName,
        issuedDate: certificate.issuedDate,
        issuedBy: certificate.issuedBy,
        certificateData: certificate.certificateData,
        pdfUrl: certificate.pdfUrl,
        pdfPath: certificate.pdfPath,
        isDownloaded: certificate.isDownloaded,
        downloadedAt: certificate.downloadedAt,
        isPrinted: certificate.isPrinted,
        printedAt: certificate.printedAt,
        notes: certificate.notes,
        createdAt: certificate.createdAt,
        updatedAt: certificate.updatedAt,
      );
      final insertResponse = await _client
          .from('certificates')
          .insert(_withSchoolId(updatedCert.toJson()))
          .select()
          .single();
      return Certificate.fromJson(insertResponse);
    }

    final response = await _client
        .from('certificates')
        .insert(_withSchoolId(certificate.toJson()))
        .select()
        .single();
    return Certificate.fromJson(response);
  }

  Future<List<Certificate>> fetchCertificates({
    CertificateType? certificateType,
    RecipientType? recipientType,
    String? recipientId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    _requireSchoolId();
    var query = _client
        .from('certificates')
        .select()
        .eq('school_id', _requireSchoolId());

    if (certificateType != null) {
      query = query.eq('certificate_type', certificateType.dbValue);
    }
    if (recipientType != null) {
      query = query.eq('recipient_type', recipientType.dbValue);
    }
    if (recipientId != null) {
      query = query.eq('recipient_id', recipientId);
    }
    if (startDate != null) {
      query = query.gte('issued_date', startDate.toIso8601String());
    }
    if (endDate != null) {
      query = query.lte('issued_date', endDate.toIso8601String());
    }

    final response = await query.order('issued_date', ascending: false);
    return (response as List)
        .map((json) => Certificate.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<Certificate> updateCertificate(Certificate certificate) async {
    _requireSchoolId();
    final response = await _client
        .from('certificates')
        .update(certificate.toJson())
        .eq('id', certificate.id)
        .eq('school_id', _requireSchoolId())
        .select()
        .single();
    return Certificate.fromJson(response);
  }

  Future<void> markAsDownloaded(String certificateId) async {
    _requireSchoolId();
    await _client
        .from('certificates')
        .update({
          'is_downloaded': true,
          'downloaded_at': DateTime.now().toIso8601String(),
        })
        .eq('id', certificateId)
        .eq('school_id', _requireSchoolId());
  }

  Future<void> markAsPrinted(String certificateId) async {
    _requireSchoolId();
    await _client
        .from('certificates')
        .update({
          'is_printed': true,
          'printed_at': DateTime.now().toIso8601String(),
        })
        .eq('id', certificateId)
        .eq('school_id', _requireSchoolId());
  }

  Future<void> updatePdfUrl(
    String certificateId,
    String pdfUrl,
    String pdfPath,
  ) async {
    _requireSchoolId();
    await _client
        .from('certificates')
        .update({'pdf_url': pdfUrl, 'pdf_path': pdfPath})
        .eq('id', certificateId)
        .eq('school_id', _requireSchoolId());
  }

  Future<List<Certificate>> generateBulkCertificates({
    required String templateId,
    required List<String> recipientIds,
    required RecipientType recipientType,
    required String issuedBy,
    required Map<String, Map<String, dynamic>> certificateDataMap,
  }) async {
    _requireSchoolId();
    final certificates = <Certificate>[];

    // Get template to determine certificate type
    final template = await _client
        .from('certificate_templates')
        .select()
        .eq('id', templateId)
        .eq('school_id', _requireSchoolId())
        .single();
    final certificateTemplate = CertificateTemplate.fromJson(
      template,
    );

    for (final recipientId in recipientIds) {
      final certificate = Certificate(
        id: '',
        schoolId: _requireSchoolId(),
        templateId: templateId,
        certificateNumber: '', // Will be generated
        certificateType: certificateTemplate.certificateType,
        recipientType: recipientType,
        recipientId: recipientId,
        recipientName:
            certificateDataMap[recipientId]?['name'] as String? ?? 'Unknown',
        issuedDate: DateTime.now(),
        issuedBy: issuedBy,
        certificateData: certificateDataMap[recipientId] != null
            ? createCertificateDataFromJson(
                certificateDataMap[recipientId] as Map<String, dynamic>,
              )
            : null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final created = await generateCertificate(certificate);
      certificates.add(created);
    }

    return certificates;
  }
}
