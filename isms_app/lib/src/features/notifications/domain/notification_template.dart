import 'package:equatable/equatable.dart';

class NotificationTemplate extends Equatable {
  const NotificationTemplate({
    required this.id,
    required this.templateKey,
    required this.name,
    this.description,
    this.category,
    this.emailSubject,
    this.emailBody,
    this.smsBody,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String templateKey;
  final String name;
  final String? description;
  final String? category;
  final String? emailSubject;
  final String? emailBody;
  final String? smsBody;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory NotificationTemplate.fromMap(Map<String, dynamic> map) {
    return NotificationTemplate(
      id: map['id'] as String,
      templateKey: map['template_key'] as String,
      name: map['name'] as String,
      description: map['description'] as String?,
      category: map['category'] as String?,
      emailSubject: map['email_subject'] as String?,
      emailBody: map['email_body'] as String?,
      smsBody: map['sms_body'] as String?,
      isActive: (map['is_active'] as bool?) ?? true,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'])
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'template_key': templateKey,
      'name': name,
      'description': description,
      'category': category,
      'email_subject': emailSubject,
      'email_body': emailBody,
      'sms_body': smsBody,
      'is_active': isActive,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
    id,
    templateKey,
    name,
    description,
    category,
    emailSubject,
    emailBody,
    smsBody,
    isActive,
    createdAt,
    updatedAt,
  ];
}
