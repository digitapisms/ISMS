import 'package:isms_app/src/features/messaging/domain/messaging_type.dart';

class Announcement {
  final String id;
  final String schoolId;
  final String title;
  final String content;
  final AnnouncementType announcementType;
  final Priority priority;
  final TargetAudience targetAudience;
  final int? classId;
  final int? sectionId;
  final String publishedBy;
  final DateTime? publishedAt;
  final DateTime? expiresAt;
  final bool isPublished;
  final bool requiresAcknowledgment;
  final DateTime createdAt;
  final DateTime updatedAt;

  Announcement({
    required this.id,
    required this.schoolId,
    required this.title,
    required this.content,
    this.announcementType = AnnouncementType.general,
    this.priority = Priority.normal,
    this.targetAudience = TargetAudience.all,
    this.classId,
    this.sectionId,
    required this.publishedBy,
    this.publishedAt,
    this.expiresAt,
    this.isPublished = false,
    this.requiresAcknowledgment = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Announcement.fromJson(Map<String, dynamic> json) {
    return Announcement(
      id: json['id'] as String,
      schoolId: json['school_id'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      announcementType: AnnouncementTypeX.fromDb(json['announcement_type'] as String? ?? 'general'),
      priority: PriorityX.fromDb(json['priority'] as String? ?? 'normal'),
      targetAudience: TargetAudienceX.fromDb(json['target_audience'] as String? ?? 'all'),
      classId: json['class_id'] as int?,
      sectionId: json['section_id'] as int?,
      publishedBy: json['published_by'] as String,
      publishedAt: json['published_at'] != null
          ? DateTime.parse(json['published_at'] as String)
          : null,
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'] as String)
          : null,
      isPublished: json['is_published'] as bool? ?? false,
      requiresAcknowledgment: json['requires_acknowledgment'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'school_id': schoolId,
      'title': title,
      'content': content,
      'announcement_type': announcementType.dbValue,
      'priority': priority.dbValue,
      'target_audience': targetAudience.dbValue,
      'class_id': classId,
      'section_id': sectionId,
      'published_by': publishedBy,
      'published_at': publishedAt?.toIso8601String(),
      'expires_at': expiresAt?.toIso8601String(),
      'is_published': isPublished,
      'requires_acknowledgment': requiresAcknowledgment,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

