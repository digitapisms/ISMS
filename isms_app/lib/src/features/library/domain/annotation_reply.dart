import 'package:equatable/equatable.dart';

class AnnotationReply extends Equatable {
  const AnnotationReply({
    required this.id,
    required this.schoolId,
    required this.annotationId,
    required this.userId,
    required this.content,
    this.parentReplyId,
    this.likesCount = 0,
    this.isEdited = false,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String schoolId;
  final String annotationId;
  final String userId;
  final String content;
  final String? parentReplyId;
  final int likesCount;
  final bool isEdited;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory AnnotationReply.fromMap(Map<String, dynamic> map) {
    return AnnotationReply(
      id: map['id'] as String,
      schoolId: map['school_id'] as String,
      annotationId: map['annotation_id'] as String,
      userId: map['user_id'] as String,
      content: map['content'] as String,
      parentReplyId: map['parent_reply_id'] as String?,
      likesCount: (map['likes_count'] as int?) ?? 0,
      isEdited: (map['is_edited'] as bool?) ?? false,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'school_id': schoolId,
      'annotation_id': annotationId,
      'user_id': userId,
      'content': content,
      'parent_reply_id': parentReplyId,
      'likes_count': likesCount,
      'is_edited': isEdited,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
        id,
        schoolId,
        annotationId,
        userId,
        content,
        parentReplyId,
        likesCount,
        isEdited,
        createdAt,
        updatedAt,
      ];
}