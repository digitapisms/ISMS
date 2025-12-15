import 'package:isms_app/src/features/messaging/domain/messaging_type.dart';

class Message {
  final String id;
  final String schoolId;
  final String conversationId;
  final String senderId;
  final MessageType messageType;
  final String? content;
  final bool isEdited;
  final DateTime? editedAt;
  final bool isDeleted;
  final DateTime? deletedAt;
  final String? replyToMessageId;
  final bool isForwarded;
  final String? forwardedFromMessageId;
  final DateTime createdAt;
  final DateTime updatedAt;

  Message({
    required this.id,
    required this.schoolId,
    required this.conversationId,
    required this.senderId,
    this.messageType = MessageType.text,
    this.content,
    this.isEdited = false,
    this.editedAt,
    this.isDeleted = false,
    this.deletedAt,
    this.replyToMessageId,
    this.isForwarded = false,
    this.forwardedFromMessageId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'] as String,
      schoolId: json['school_id'] as String,
      conversationId: json['conversation_id'] as String,
      senderId: json['sender_id'] as String,
      messageType: MessageTypeX.fromDb(json['message_type'] as String? ?? 'text'),
      content: json['content'] as String?,
      isEdited: json['is_edited'] as bool? ?? false,
      editedAt: json['edited_at'] != null
          ? DateTime.parse(json['edited_at'] as String)
          : null,
      isDeleted: json['is_deleted'] as bool? ?? false,
      deletedAt: json['deleted_at'] != null
          ? DateTime.parse(json['deleted_at'] as String)
          : null,
      replyToMessageId: json['reply_to_message_id'] as String?,
      isForwarded: json['is_forwarded'] as bool? ?? false,
      forwardedFromMessageId: json['forwarded_from_message_id'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'school_id': schoolId,
      'conversation_id': conversationId,
      'sender_id': senderId,
      'message_type': messageType.dbValue,
      'content': content,
      'is_edited': isEdited,
      'edited_at': editedAt?.toIso8601String(),
      'is_deleted': isDeleted,
      'deleted_at': deletedAt?.toIso8601String(),
      'reply_to_message_id': replyToMessageId,
      'is_forwarded': isForwarded,
      'forwarded_from_message_id': forwardedFromMessageId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

