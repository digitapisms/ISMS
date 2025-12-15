import 'package:equatable/equatable.dart';

class DigitalResourceAnnotation extends Equatable {
  const DigitalResourceAnnotation({
    required this.id,
    required this.schoolId,
    required this.resourceId,
    required this.userId,
    required this.annotationType,
    required this.content,
    this.pageNumber,
    this.positionX,
    this.positionY,
    this.highlightColor,
    this.isPublic = false,
    this.repliesCount = 0,
    this.likesCount = 0,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String schoolId;
  final String resourceId;
  final String userId;
  final AnnotationType annotationType;
  final String content;
  final int? pageNumber;
  final double? positionX;
  final double? positionY;
  final String? highlightColor;
  final bool isPublic;
  final int repliesCount;
  final int likesCount;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory DigitalResourceAnnotation.fromMap(Map<String, dynamic> map) {
    return DigitalResourceAnnotation(
      id: map['id'] as String,
      schoolId: map['school_id'] as String,
      resourceId: map['resource_id'] as String,
      userId: map['user_id'] as String,
      annotationType: AnnotationTypeX.fromDb(
        map['annotation_type'] as String? ?? 'note',
      ),
      content: map['content'] as String,
      pageNumber: map['page_number'] as int?,
      positionX: (map['position_x'] as num?)?.toDouble(),
      positionY: (map['position_y'] as num?)?.toDouble(),
      highlightColor: map['highlight_color'] as String?,
      isPublic: (map['is_public'] as bool?) ?? false,
      repliesCount: (map['replies_count'] as int?) ?? 0,
      likesCount: (map['likes_count'] as int?) ?? 0,
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
      'resource_id': resourceId,
      'user_id': userId,
      'annotation_type': annotationType.dbValue,
      'content': content,
      'page_number': pageNumber,
      'position_x': positionX,
      'position_y': positionY,
      'highlight_color': highlightColor,
      'is_public': isPublic,
      'replies_count': repliesCount,
      'likes_count': likesCount,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
        id,
        schoolId,
        resourceId,
        userId,
        annotationType,
        content,
        pageNumber,
        positionX,
        positionY,
        highlightColor,
        isPublic,
        repliesCount,
        likesCount,
        createdAt,
        updatedAt,
      ];
}

enum AnnotationType {
  note,
  highlight,
  comment,
  question,
  answer,
}

extension AnnotationTypeX on AnnotationType {
  String get dbValue {
    switch (this) {
      case AnnotationType.note:
        return 'note';
      case AnnotationType.highlight:
        return 'highlight';
      case AnnotationType.comment:
        return 'comment';
      case AnnotationType.question:
        return 'question';
      case AnnotationType.answer:
        return 'answer';
    }
  }

  String get displayName {
    switch (this) {
      case AnnotationType.note:
        return 'Note';
      case AnnotationType.highlight:
        return 'Highlight';
      case AnnotationType.comment:
        return 'Comment';
      case AnnotationType.question:
        return 'Question';
      case AnnotationType.answer:
        return 'Answer';
    }
  }

  static AnnotationType fromDb(String value) {
    switch (value) {
      case 'note':
        return AnnotationType.note;
      case 'highlight':
        return AnnotationType.highlight;
      case 'comment':
        return AnnotationType.comment;
      case 'question':
        return AnnotationType.question;
      case 'answer':
        return AnnotationType.answer;
      default:
        return AnnotationType.note;
    }
  }
}