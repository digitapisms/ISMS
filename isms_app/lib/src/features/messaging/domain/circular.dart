import 'package:isms_app/src/features/messaging/domain/messaging_type.dart';

class Circular {
  final String id;
  final String schoolId;
  final String circularNumber;
  final String title;
  final String content;
  final CircularType circularType;
  final TargetAudience targetAudience;
  final int? classId;
  final int? sectionId;
  final String issuedBy;
  final DateTime issuedDate;
  final DateTime? effectiveDate;
  final DateTime? expiryDate;
  final bool isActive;
  final bool requiresAcknowledgment;
  final DateTime createdAt;
  final DateTime updatedAt;

  Circular({
    required this.id,
    required this.schoolId,
    required this.circularNumber,
    required this.title,
    required this.content,
    this.circularType = CircularType.general,
    this.targetAudience = TargetAudience.all,
    this.classId,
    this.sectionId,
    required this.issuedBy,
    required this.issuedDate,
    this.effectiveDate,
    this.expiryDate,
    this.isActive = true,
    this.requiresAcknowledgment = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Circular.fromJson(Map<String, dynamic> json) {
    return Circular(
      id: json['id'] as String,
      schoolId: json['school_id'] as String,
      circularNumber: json['circular_number'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      circularType: CircularTypeX.fromDb(json['circular_type'] as String? ?? 'general'),
      targetAudience: TargetAudienceX.fromDb(json['target_audience'] as String? ?? 'all'),
      classId: json['class_id'] as int?,
      sectionId: json['section_id'] as int?,
      issuedBy: json['issued_by'] as String,
      issuedDate: DateTime.parse(json['issued_date'] as String),
      effectiveDate: json['effective_date'] != null
          ? DateTime.parse(json['effective_date'] as String)
          : null,
      expiryDate: json['expiry_date'] != null
          ? DateTime.parse(json['expiry_date'] as String)
          : null,
      isActive: json['is_active'] as bool? ?? true,
      requiresAcknowledgment: json['requires_acknowledgment'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'school_id': schoolId,
      'circular_number': circularNumber,
      'title': title,
      'content': content,
      'circular_type': circularType.dbValue,
      'target_audience': targetAudience.dbValue,
      'class_id': classId,
      'section_id': sectionId,
      'issued_by': issuedBy,
      'issued_date': issuedDate.toIso8601String(),
      'effective_date': effectiveDate?.toIso8601String(),
      'expiry_date': expiryDate?.toIso8601String(),
      'is_active': isActive,
      'requires_acknowledgment': requiresAcknowledgment,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

