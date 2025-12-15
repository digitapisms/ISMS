import 'certificate_type.dart';

class Certificate {
  final String id;
  final String schoolId;
  final String templateId;
  final String certificateNumber;
  final CertificateType certificateType;
  final RecipientType recipientType;
  final String recipientId;
  final String recipientName;
  final DateTime issuedDate;
  final String issuedBy;
  final Map<String, dynamic>? certificateData;
  final String? pdfUrl;
  final String? pdfPath;
  final bool isDownloaded;
  final DateTime? downloadedAt;
  final bool isPrinted;
  final DateTime? printedAt;
  final bool signatureVerified;
  final DateTime? signatureVerifiedAt;
  final String? signatureVerifiedBy;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  Certificate({
    required this.id,
    required this.schoolId,
    required this.templateId,
    required this.certificateNumber,
    required this.certificateType,
    required this.recipientType,
    required this.recipientId,
    required this.recipientName,
    required this.issuedDate,
    required this.issuedBy,
    this.certificateData,
    this.pdfUrl,
    this.pdfPath,
    this.isDownloaded = false,
    this.downloadedAt,
    this.isPrinted = false,
    this.printedAt,
    this.signatureVerified = false,
    this.signatureVerifiedAt,
    this.signatureVerifiedBy,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Certificate.fromJson(Map<String, dynamic> json) {
    return Certificate(
      id: json['id'] as String,
      schoolId: json['school_id'] as String,
      templateId: json['template_id'] as String,
      certificateNumber: json['certificate_number'] as String,
      certificateType: CertificateTypeX.fromDb(json['certificate_type'] as String),
      recipientType: RecipientTypeX.fromDb(json['recipient_type'] as String),
      recipientId: json['recipient_id'] as String,
      recipientName: json['recipient_name'] as String,
      issuedDate: DateTime.parse(json['issued_date'] as String),
      issuedBy: json['issued_by'] as String,
      certificateData: json['certificate_data'] != null
          ? json['certificate_data'] as Map<String, dynamic>
          : null,
      pdfUrl: json['pdf_url'] as String?,
      pdfPath: json['pdf_path'] as String?,
      isDownloaded: json['is_downloaded'] as bool? ?? false,
      downloadedAt: json['downloaded_at'] != null
          ? DateTime.parse(json['downloaded_at'] as String)
          : null,
      isPrinted: json['is_printed'] as bool? ?? false,
      printedAt: json['printed_at'] != null
          ? DateTime.parse(json['printed_at'] as String)
          : null,
      signatureVerified: json['signature_verified'] as bool? ?? false,
      signatureVerifiedAt: json['signature_verified_at'] != null
          ? DateTime.parse(json['signature_verified_at'] as String)
          : null,
      signatureVerifiedBy: json['signature_verified_by'] as String?,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'school_id': schoolId,
      'template_id': templateId,
      'certificate_number': certificateNumber,
      'certificate_type': certificateType.dbValue,
      'recipient_type': recipientType.dbValue,
      'recipient_id': recipientId,
      'recipient_name': recipientName,
      'issued_date': issuedDate.toIso8601String(),
      'issued_by': issuedBy,
      'certificate_data': certificateData,
      'pdf_url': pdfUrl,
      'pdf_path': pdfPath,
      'is_downloaded': isDownloaded,
      'downloaded_at': downloadedAt?.toIso8601String(),
      'is_printed': isPrinted,
      'printed_at': printedAt?.toIso8601String(),
      'signature_verified': signatureVerified,
      'signature_verified_at': signatureVerifiedAt?.toIso8601String(),
      'signature_verified_by': signatureVerifiedBy,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

