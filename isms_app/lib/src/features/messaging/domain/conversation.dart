import 'package:isms_app/src/features/messaging/domain/messaging_type.dart';

class Conversation {
  final String id;
  final String schoolId;
  final ConversationType conversationType;
  final String? title;
  final String createdBy;
  final bool isActive;
  final DateTime? lastMessageAt;
  final String? lastMessagePreview;
  final DateTime createdAt;
  final DateTime updatedAt;

  Conversation({
    required this.id,
    required this.schoolId,
    required this.conversationType,
    this.title,
    required this.createdBy,
    this.isActive = true,
    this.lastMessageAt,
    this.lastMessagePreview,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: json['id'] as String,
      schoolId: json['school_id'] as String,
      conversationType: ConversationTypeX.fromDb(json['conversation_type'] as String),
      title: json['title'] as String?,
      createdBy: json['created_by'] as String,
      isActive: json['is_active'] as bool? ?? true,
      lastMessageAt: json['last_message_at'] != null
          ? DateTime.parse(json['last_message_at'] as String)
          : null,
      lastMessagePreview: json['last_message_preview'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'school_id': schoolId,
      'conversation_type': conversationType.dbValue,
      'title': title,
      'created_by': createdBy,
      'is_active': isActive,
      'last_message_at': lastMessageAt?.toIso8601String(),
      'last_message_preview': lastMessagePreview,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

