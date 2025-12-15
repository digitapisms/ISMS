import 'package:flutter/material.dart';

class PTMMeeting {
  final String id;
  final String schoolId;
  final String studentId;
  final String? parentId;
  final String teacherId;
  final DateTime meetingDate;
  final int durationMinutes;
  final MeetingType meetingType;
  final MeetingStatus status;
  final String? location;
  final String? agenda;
  final String scheduledBy;
  final bool reminderSent;
  final DateTime? reminderSentAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  PTMMeeting({
    required this.id,
    required this.schoolId,
    required this.studentId,
    this.parentId,
    required this.teacherId,
    required this.meetingDate,
    this.durationMinutes = 30,
    this.meetingType = MeetingType.scheduled,
    this.status = MeetingStatus.scheduled,
    this.location,
    this.agenda,
    required this.scheduledBy,
    this.reminderSent = false,
    this.reminderSentAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PTMMeeting.fromJson(Map<String, dynamic> json) {
    return PTMMeeting(
      id: json['id'] as String,
      schoolId: json['school_id'] as String,
      studentId: json['student_id'] as String,
      parentId: json['parent_id'] as String?,
      teacherId: json['teacher_id'] as String,
      meetingDate: DateTime.parse(json['meeting_date'] as String),
      durationMinutes: json['duration_minutes'] as int? ?? 30,
      meetingType: MeetingTypeX.fromDb(json['meeting_type'] as String),
      status: MeetingStatusX.fromDb(json['status'] as String),
      location: json['location'] as String?,
      agenda: json['agenda'] as String?,
      scheduledBy: json['scheduled_by'] as String,
      reminderSent: json['reminder_sent'] as bool? ?? false,
      reminderSentAt: json['reminder_sent_at'] != null
          ? DateTime.parse(json['reminder_sent_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'school_id': schoolId,
      'student_id': studentId,
      'parent_id': parentId,
      'teacher_id': teacherId,
      'meeting_date': meetingDate.toIso8601String(),
      'duration_minutes': durationMinutes,
      'meeting_type': meetingType.dbValue,
      'status': status.dbValue,
      'location': location,
      'agenda': agenda,
      'scheduled_by': scheduledBy,
      'reminder_sent': reminderSent,
      'reminder_sent_at': reminderSentAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

enum MeetingType {
  scheduled,
  walkIn,
  emergency,
}

extension MeetingTypeX on MeetingType {
  String get dbValue {
    switch (this) {
      case MeetingType.scheduled:
        return 'scheduled';
      case MeetingType.walkIn:
        return 'walk_in';
      case MeetingType.emergency:
        return 'emergency';
    }
  }

  String get displayName {
    switch (this) {
      case MeetingType.scheduled:
        return 'Scheduled';
      case MeetingType.walkIn:
        return 'Walk-in';
      case MeetingType.emergency:
        return 'Emergency';
    }
  }

  static MeetingType fromDb(String value) {
    switch (value) {
      case 'scheduled':
        return MeetingType.scheduled;
      case 'walk_in':
        return MeetingType.walkIn;
      case 'emergency':
        return MeetingType.emergency;
      default:
        return MeetingType.scheduled;
    }
  }
}

enum MeetingStatus {
  scheduled,
  confirmed,
  inProgress,
  completed,
  cancelled,
  noShow,
}

extension MeetingStatusX on MeetingStatus {
  String get dbValue {
    switch (this) {
      case MeetingStatus.scheduled:
        return 'scheduled';
      case MeetingStatus.confirmed:
        return 'confirmed';
      case MeetingStatus.inProgress:
        return 'in_progress';
      case MeetingStatus.completed:
        return 'completed';
      case MeetingStatus.cancelled:
        return 'cancelled';
      case MeetingStatus.noShow:
        return 'no_show';
    }
  }

  String get displayName {
    switch (this) {
      case MeetingStatus.scheduled:
        return 'Scheduled';
      case MeetingStatus.confirmed:
        return 'Confirmed';
      case MeetingStatus.inProgress:
        return 'In Progress';
      case MeetingStatus.completed:
        return 'Completed';
      case MeetingStatus.cancelled:
        return 'Cancelled';
      case MeetingStatus.noShow:
        return 'No Show';
    }
  }

  Color get color {
    switch (this) {
      case MeetingStatus.scheduled:
        return Colors.blue;
      case MeetingStatus.confirmed:
        return Colors.green;
      case MeetingStatus.inProgress:
        return Colors.orange;
      case MeetingStatus.completed:
        return Colors.teal;
      case MeetingStatus.cancelled:
        return Colors.red;
      case MeetingStatus.noShow:
        return Colors.grey;
    }
  }

  static MeetingStatus fromDb(String value) {
    switch (value) {
      case 'scheduled':
        return MeetingStatus.scheduled;
      case 'confirmed':
        return MeetingStatus.confirmed;
      case 'in_progress':
        return MeetingStatus.inProgress;
      case 'completed':
        return MeetingStatus.completed;
      case 'cancelled':
        return MeetingStatus.cancelled;
      case 'no_show':
        return MeetingStatus.noShow;
      default:
        return MeetingStatus.scheduled;
    }
  }
}

