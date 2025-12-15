import 'package:isms_app/src/features/messaging/domain/messaging_type.dart';

class ConversationParticipant {
  final String id;
  final String schoolId;
  final String conversationId;
  final String userId;
  final ParticipantRole role;
  final DateTime joinedAt;
  final DateTime? lastReadAt;
  final bool isMuted;
  final bool isArchived;

  ConversationParticipant({
    required this.id,
    required this.schoolId,
    required this.conversationId,
    required this.userId,
    this.role = ParticipantRole.participant,
    required this.joinedAt,
    this.lastReadAt,
    this.isMuted = false,
    this.isArchived = false,
  });

  factory ConversationParticipant.fromJson(Map<String, dynamic> json) {
    return ConversationParticipant(
      id: json['id'] as String,
      schoolId: json['school_id'] as String,
      conversationId: json['conversation_id'] as String,
      userId: json['user_id'] as String,
      role: ParticipantRoleX.fromDb(json['role'] as String? ?? 'participant'),
      joinedAt: DateTime.parse(json['joined_at'] as String),
      lastReadAt: json['last_read_at'] != null
          ? DateTime.parse(json['last_read_at'] as String)
          : null,
      isMuted: json['is_muted'] as bool? ?? false,
      isArchived: json['is_archived'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'school_id': schoolId,
      'conversation_id': conversationId,
      'user_id': userId,
      'role': role.dbValue,
      'joined_at': joinedAt.toIso8601String(),
      'last_read_at': lastReadAt?.toIso8601String(),
      'is_muted': isMuted,
      'is_archived': isArchived,
    };
  }
}

