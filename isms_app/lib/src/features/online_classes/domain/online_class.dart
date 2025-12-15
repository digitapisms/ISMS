import 'package:isms_app/src/features/online_classes/domain/online_class_platform.dart';

/// Represents an online class with scheduling and configuration
class OnlineClass {
  final String id;
  final String institutionTypeId;
  final String title;
  final String description;
  final OnlineClassPlatform platform;
  final Duration duration;
  final DateTime scheduledStart;
  final DateTime scheduledEnd;
  final String meetingUrl;
  final String meetingPassword;
  final String? customMeetingUrl;
  final int expectedParticipants;
  final bool recordSession;
  final bool breakoutRoomsEnabled;
  final bool waitingRoomEnabled;
  final bool chatEnabled;
  final bool screenSharingEnabled;
  final bool handRaiseEnabled;
  final bool pollingEnabled;
  final bool qaEnabled;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;

  OnlineClass({
    required this.id,
    required this.institutionTypeId,
    required this.title,
    required this.description,
    required this.platform,
    required this.duration,
    required this.scheduledStart,
    required this.scheduledEnd,
    required this.meetingUrl,
    required this.meetingPassword,
    this.customMeetingUrl,
    required this.expectedParticipants,
    required this.recordSession,
    required this.breakoutRoomsEnabled,
    required this.waitingRoomEnabled,
    required this.chatEnabled,
    required this.screenSharingEnabled,
    required this.handRaiseEnabled,
    required this.pollingEnabled,
    required this.qaEnabled,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    required this.isActive,
  });

  /// Create a copy of the online class with updated values
  OnlineClass copyWith({
    String? id,
    String? institutionTypeId,
    String? title,
    String? description,
    OnlineClassPlatform? platform,
    Duration? duration,
    DateTime? scheduledStart,
    DateTime? scheduledEnd,
    String? meetingUrl,
    String? meetingPassword,
    String? customMeetingUrl,
    int? expectedParticipants,
    bool? recordSession,
    bool? breakoutRoomsEnabled,
    bool? waitingRoomEnabled,
    bool? chatEnabled,
    bool? screenSharingEnabled,
    bool? handRaiseEnabled,
    bool? pollingEnabled,
    bool? qaEnabled,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
  }) {
    return OnlineClass(
      id: id ?? this.id,
      institutionTypeId: institutionTypeId ?? this.institutionTypeId,
      title: title ?? this.title,
      description: description ?? this.description,
      platform: platform ?? this.platform,
      duration: duration ?? this.duration,
      scheduledStart: scheduledStart ?? this.scheduledStart,
      scheduledEnd: scheduledEnd ?? this.scheduledEnd,
      meetingUrl: meetingUrl ?? this.meetingUrl,
      meetingPassword: meetingPassword ?? this.meetingPassword,
      customMeetingUrl: customMeetingUrl ?? this.customMeetingUrl,
      expectedParticipants: expectedParticipants ?? this.expectedParticipants,
      recordSession: recordSession ?? this.recordSession,
      breakoutRoomsEnabled: breakoutRoomsEnabled ?? this.breakoutRoomsEnabled,
      waitingRoomEnabled: waitingRoomEnabled ?? this.waitingRoomEnabled,
      chatEnabled: chatEnabled ?? this.chatEnabled,
      screenSharingEnabled: screenSharingEnabled ?? this.screenSharingEnabled,
      handRaiseEnabled: handRaiseEnabled ?? this.handRaiseEnabled,
      pollingEnabled: pollingEnabled ?? this.pollingEnabled,
      qaEnabled: qaEnabled ?? this.qaEnabled,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
    );
  }

  /// Convert to map for database storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'institution_type_id': institutionTypeId,
      'title': title,
      'description': description,
      'platform': platform.name,
      'duration_minutes': duration.inMinutes,
      'scheduled_start': scheduledStart.toIso8601String(),
      'scheduled_end': scheduledEnd.toIso8601String(),
      'meeting_url': meetingUrl,
      'meeting_password': meetingPassword,
      'custom_meeting_url': customMeetingUrl,
      'expected_participants': expectedParticipants,
      'record_session': recordSession,
      'breakout_rooms_enabled': breakoutRoomsEnabled,
      'waiting_room_enabled': waitingRoomEnabled,
      'chat_enabled': chatEnabled,
      'screen_sharing_enabled': screenSharingEnabled,
      'hand_raise_enabled': handRaiseEnabled,
      'polling_enabled': pollingEnabled,
      'qa_enabled': qaEnabled,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_active': isActive,
    };
  }

  /// Create from map (database retrieval)
  factory OnlineClass.fromMap(Map<String, dynamic> map) {
    return OnlineClass(
      id: map['id'] as String,
      institutionTypeId: map['institution_type_id'] as String,
      title: map['title'] as String,
      description: map['description'] as String,
      platform: OnlineClassPlatform.values.firstWhere(
        (e) => e.name == map['platform'],
        orElse: () => OnlineClassPlatform.zoom,
      ),
      duration: Duration(minutes: map['duration_minutes'] as int),
      scheduledStart: DateTime.parse(map['scheduled_start'] as String),
      scheduledEnd: DateTime.parse(map['scheduled_end'] as String),
      meetingUrl: map['meeting_url'] as String,
      meetingPassword: map['meeting_password'] as String,
      customMeetingUrl: map['custom_meeting_url'] as String?,
      expectedParticipants: map['expected_participants'] as int,
      recordSession: map['record_session'] as bool,
      breakoutRoomsEnabled: map['breakout_rooms_enabled'] as bool,
      waitingRoomEnabled: map['waiting_room_enabled'] as bool,
      chatEnabled: map['chat_enabled'] as bool,
      screenSharingEnabled: map['screen_sharing_enabled'] as bool,
      handRaiseEnabled: map['hand_raise_enabled'] as bool,
      pollingEnabled: map['polling_enabled'] as bool,
      qaEnabled: map['qa_enabled'] as bool,
      createdBy: map['created_by'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      isActive: map['is_active'] as bool,
    );
  }

  @override
  String toString() {
    return 'OnlineClass(id: $id, title: $title, platform: $platform, scheduled: $scheduledStart)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is OnlineClass && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}