import 'package:isms_app/src/features/messaging/domain/messaging_type.dart';

class MessageTemplate {
  final String id;
  final String schoolId;
  final String templateName;
  final TemplateCategory? templateCategory;
  final String? subject;
  final String content;
  final List<String>? variables;
  final bool isActive;
  final String? createdBy;
  final int usageCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  MessageTemplate({
    required this.id,
    required this.schoolId,
    required this.templateName,
    this.templateCategory,
    this.subject,
    required this.content,
    this.variables,
    this.isActive = true,
    this.createdBy,
    this.usageCount = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory MessageTemplate.fromJson(Map<String, dynamic> json) {
    return MessageTemplate(
      id: json['id'] as String,
      schoolId: json['school_id'] as String,
      templateName: json['template_name'] as String,
      templateCategory: json['template_category'] != null
          ? TemplateCategoryX.fromDb(json['template_category'] as String)
          : null,
      subject: json['subject'] as String?,
      content: json['content'] as String,
      variables: json['variables'] != null
          ? List<String>.from(json['variables'] as List)
          : null,
      isActive: json['is_active'] as bool? ?? true,
      createdBy: json['created_by'] as String?,
      usageCount: json['usage_count'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'school_id': schoolId,
      'template_name': templateName,
      'template_category': templateCategory?.dbValue,
      'subject': subject,
      'content': content,
      'variables': variables,
      'is_active': isActive,
      'created_by': createdBy,
      'usage_count': usageCount,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

