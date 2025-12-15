import 'event_type.dart';

class Event {
  final String id;
  final String schoolId;
  final String title;
  final String? description;
  final EventType eventType;
  final DateTime startDate;
  final DateTime? endDate;
  final String? startTime;
  final String? endTime;
  final String? location;
  final String? organizerId;
  final String targetAudience;
  final int? classId;
  final int? sectionId;
  final bool isAllDay;
  final bool isRecurring;
  final String? recurrencePattern;
  final DateTime? recurrenceEndDate;
  final bool requiresRegistration;
  final int? maxParticipants;
  final DateTime? registrationDeadline;
  final EventStatus status;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  Event({
    required this.id,
    required this.schoolId,
    required this.title,
    this.description,
    this.eventType = EventType.other,
    required this.startDate,
    this.endDate,
    this.startTime,
    this.endTime,
    this.location,
    this.organizerId,
    this.targetAudience = 'all',
    this.classId,
    this.sectionId,
    this.isAllDay = false,
    this.isRecurring = false,
    this.recurrencePattern,
    this.recurrenceEndDate,
    this.requiresRegistration = false,
    this.maxParticipants,
    this.registrationDeadline,
      this.status = EventStatus.draft,
      required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['id'] as String,
      schoolId: json['school_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      eventType: EventTypeX.fromDb(json['event_type'] as String? ?? 'other'),
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: json['end_date'] != null
          ? DateTime.parse(json['end_date'] as String)
          : null,
      startTime: json['start_time'] as String?,
      endTime: json['end_time'] as String?,
      location: json['location'] as String?,
      organizerId: json['organizer_id'] as String?,
      targetAudience: json['target_audience'] as String? ?? 'all',
      classId: json['class_id'] as int?,
      sectionId: json['section_id'] as int?,
      isAllDay: json['is_all_day'] as bool? ?? false,
      isRecurring: json['is_recurring'] as bool? ?? false,
      recurrencePattern: json['recurrence_pattern'] as String?,
      recurrenceEndDate: json['recurrence_end_date'] != null
          ? DateTime.parse(json['recurrence_end_date'] as String)
          : null,
      requiresRegistration: json['requires_registration'] as bool? ?? false,
      maxParticipants: json['max_participants'] as int?,
      registrationDeadline: json['registration_deadline'] != null
          ? DateTime.parse(json['registration_deadline'] as String)
          : null,
      status: EventStatusX.fromDb(json['status'] as String? ?? 'draft'),
      createdBy: json['created_by'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'school_id': schoolId,
      'title': title,
      'description': description,
      'event_type': eventType.dbValue,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'start_time': startTime,
      'end_time': endTime,
      'location': location,
      'organizer_id': organizerId,
      'target_audience': targetAudience,
      'class_id': classId,
      'section_id': sectionId,
      'is_all_day': isAllDay,
      'is_recurring': isRecurring,
      'recurrence_pattern': recurrencePattern,
      'recurrence_end_date': recurrenceEndDate?.toIso8601String(),
      'requires_registration': requiresRegistration,
      'max_participants': maxParticipants,
      'registration_deadline': registrationDeadline?.toIso8601String(),
      'status': status.dbValue,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

