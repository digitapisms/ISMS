import 'certificate_type.dart';

class CertificateTemplate {
  final String id;
  final String schoolId;
  final String templateName;
  final CertificateType certificateType;
  final TemplateType templateType;
  final String? description;
  final String templateContent;
  final List<String> templateVariables;
  final String? backgroundImageUrl;
  final String? signature1Label;
  final String? signature1UserId;
  final String? signature2Label;
  final String? signature2UserId;
  final String? sealImageUrl;
  final String? digitalSignature1Url;
  final String? digitalSignature2Url;
  final bool digitalSignatureEnabled;
  final bool isActive;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  CertificateTemplate({
    required this.id,
    required this.schoolId,
    required this.templateName,
    required this.certificateType,
    this.templateType = TemplateType.student,
    this.description,
    required this.templateContent,
    required this.templateVariables,
    this.backgroundImageUrl,
    this.signature1Label,
    this.signature1UserId,
    this.signature2Label,
    this.signature2UserId,
    this.sealImageUrl,
    this.digitalSignature1Url,
    this.digitalSignature2Url,
    this.digitalSignatureEnabled = false,
    this.isActive = true,
    this.createdBy = 'system',
    required this.createdAt,
    required this.updatedAt,
  });

  factory CertificateTemplate.fromJson(Map<String, dynamic> json) {
    return CertificateTemplate(
      id: json['id'] as String,
      schoolId: json['school_id'] as String,
      templateName: json['template_name'] as String,
      certificateType: CertificateTypeX.fromDb(json['certificate_type'] as String),
      templateType: TemplateTypeX.fromDb(json['template_type'] as String? ?? 'student'),
      description: json['description'] as String?,
      templateContent: json['template_content'] as String,
      templateVariables: json['template_variables'] != null
          ? List<String>.from(json['template_variables'] as List)
          : [],
      backgroundImageUrl: json['background_image_url'] as String?,
      signature1Label: json['signature_1_label'] as String?,
      signature1UserId: json['signature_1_user_id'] as String?,
      signature2Label: json['signature_2_label'] as String?,
      signature2UserId: json['signature_2_user_id'] as String?,
      sealImageUrl: json['seal_image_url'] as String?,
      digitalSignature1Url: json['digital_signature_1_url'] as String?,
      digitalSignature2Url: json['digital_signature_2_url'] as String?,
      digitalSignatureEnabled: json['digital_signature_enabled'] as bool? ?? false,
      isActive: json['is_active'] as bool? ?? true,
      createdBy: json['created_by'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'school_id': schoolId,
      'template_name': templateName,
      'certificate_type': certificateType.dbValue,
      'template_type': templateType.dbValue,
      'description': description,
      'template_content': templateContent,
      'template_variables': templateVariables,
      'background_image_url': backgroundImageUrl,
      'signature_1_label': signature1Label,
      'signature_1_user_id': signature1UserId,
      'signature_2_label': signature2Label,
      'signature_2_user_id': signature2UserId,
      'seal_image_url': sealImageUrl,
      'digital_signature_1_url': digitalSignature1Url,
      'digital_signature_2_url': digitalSignature2Url,
      'digital_signature_enabled': digitalSignatureEnabled,
      'is_active': isActive,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

