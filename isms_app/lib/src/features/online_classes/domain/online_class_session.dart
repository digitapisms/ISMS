import 'package:isms_app/src/features/online_classes/domain/online_class.dart';

/// Represents a specific session/instance of an online class
class OnlineClassSession {
  final String id;
  final String onlineClassId;
  final OnlineClass onlineClass;
  final DateTime scheduledStart;
  final DateTime scheduledEnd;
  final DateTime? actualStart;
  final DateTime? actualEnd;
  final int expectedParticipants;
  final int actualParticipants;
  final String joinUrl;
  final String? recordingUrl;
  final String? chatTranscriptUrl;
  final String? moderatorNotes;
  final SessionStatus status;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  OnlineClassSession({
    required this.id,
    required this.onlineClassId,
    required this.onlineClass,
    required this.scheduledStart,
    required this.scheduledEnd,
    this.actualStart,
    this.actualEnd,
    required this.expectedParticipants,
    required this.actualParticipants,
    required this.joinUrl,
    this.recordingUrl,
    this.chatTranscriptUrl,
    this.moderatorNotes,
    required this.status,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create a copy with updated values
  OnlineClassSession copyWith({
    String? id,
    String? onlineClassId,
    OnlineClass? onlineClass,
    DateTime? scheduledStart,
    DateTime? scheduledEnd,
    DateTime? actualStart,
    DateTime? actualEnd,
    int? expectedParticipants,
    int? actualParticipants,
    String? joinUrl,
    String? recordingUrl,
    String? chatTranscriptUrl,
    String? moderatorNotes,
    SessionStatus? status,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return OnlineClassSession(
      id: id ?? this.id,
      onlineClassId: onlineClassId ?? this.onlineClassId,
      onlineClass: onlineClass ?? this.onlineClass,
      scheduledStart: scheduledStart ?? this.scheduledStart,
      scheduledEnd: scheduledEnd ?? this.scheduledEnd,
      actualStart: actualStart ?? this.actualStart,
      actualEnd: actualEnd ?? this.actualEnd,
      expectedParticipants: expectedParticipants ?? this.expectedParticipants,
      actualParticipants: actualParticipants ?? this.actualParticipants,
      joinUrl: joinUrl ?? this.joinUrl,
      recordingUrl: recordingUrl ?? this.recordingUrl,
      chatTranscriptUrl: chatTranscriptUrl ?? this.chatTranscriptUrl,
      moderatorNotes: moderatorNotes ?? this.moderatorNotes,
      status: status ?? this.status,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Convert to map for database storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'online_class_id': onlineClassId,
      'scheduled_start': scheduledStart.toIso8601String(),
      'scheduled_end': scheduledEnd.toIso8601String(),
      'actual_start': actualStart?.toIso8601String(),
      'actual_end': actualEnd?.toIso8601String(),
      'expected_participants': expectedParticipants,
      'actual_participants': actualParticipants,
      'join_url': joinUrl,
      'recording_url': recordingUrl,
      'chat_transcript_url': chatTranscriptUrl,
      'moderator_notes': moderatorNotes,
      'status': status.name,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Create from map (database retrieval)
  factory OnlineClassSession.fromMap(
    Map<String, dynamic> map,
    OnlineClass onlineClass,
  ) {
    return OnlineClassSession(
      id: map['id'] as String,
      onlineClassId: map['online_class_id'] as String,
      onlineClass: onlineClass,
      scheduledStart: DateTime.parse(map['scheduled_start'] as String),
      scheduledEnd: DateTime.parse(map['scheduled_end'] as String),
      actualStart: map['actual_start'] != null
          ? DateTime.parse(map['actual_start'] as String)
          : null,
      actualEnd: map['actual_end'] != null
          ? DateTime.parse(map['actual_end'] as String)
          : null,
      expectedParticipants: map['expected_participants'] as int,
      actualParticipants: map['actual_participants'] as int,
      joinUrl: map['join_url'] as String,
      recordingUrl: map['recording_url'] as String?,
      chatTranscriptUrl: map['chat_transcript_url'] as String?,
      moderatorNotes: map['moderator_notes'] as String?,
      status: SessionStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => SessionStatus.scheduled,
      ),
      createdBy: map['created_by'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  /// Check if session is currently active
  bool get isActive {
    final now = DateTime.now();
    return status == SessionStatus.inProgress ||
        (actualStart != null && actualEnd == null && now.isAfter(actualStart!));
  }

  /// Check if session is upcoming
  bool get isUpcoming {
    final now = DateTime.now();
    return status == SessionStatus.scheduled && scheduledStart.isAfter(now);
  }

  /// Check if session is completed
  bool get isCompleted {
    return status == SessionStatus.completed ||
        status == SessionStatus.ended ||
        (actualEnd != null && DateTime.now().isAfter(actualEnd!));
  }

  /// Get session duration
  Duration get duration {
    if (actualStart != null && actualEnd != null) {
      return actualEnd!.difference(actualStart!);
    }
    return scheduledEnd.difference(scheduledStart);
  }

  @override
  String toString() {
    return 'OnlineClassSession(id: $id, class: ${onlineClass.title}, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is OnlineClassSession && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Session status enum
enum SessionStatus {
  scheduled,
  inProgress,
  completed,
  cancelled,
  ended,
}

/// Extension methods for SessionStatus
extension SessionStatusX on SessionStatus {
  /// Get display name for the status
  String get displayName {
    switch (this) {
      case SessionStatus.scheduled:
        return 'Scheduled';
      case SessionStatus.inProgress:
        return 'In Progress';
      case SessionStatus.completed:
        return 'Completed';
      case SessionStatus.cancelled:
        return 'Cancelled';
      case SessionStatus.ended:
        return 'Ended';
    }
  }

  /// Get color for the status
  String get color {
    switch (this) {
      case SessionStatus.scheduled:
        return 'blue';
      case SessionStatus.inProgress:
        return 'green';
      case SessionStatus.completed:
        return 'purple';
      case SessionStatus.cancelled:
        return 'red';
      case SessionStatus.ended:
        return 'gray';
    }
  }

  /// Check if session can be started
  bool get canStart {
    return this == SessionStatus.scheduled;
  }

  /// Check if session can be ended
  bool get canEnd {
    return this == SessionStatus.inProgress || this == SessionStatus.scheduled;
  }

  /// Check if session can be cancelled
  bool get canCancel {
    return this == SessionStatus.scheduled || this == SessionStatus.inProgress;
  }
}