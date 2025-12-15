import 'package:isms_app/src/features/online_classes/domain/online_class_platform.dart';

/// Configuration for online classes specific to institution types
class OnlineClassConfig {
  final int maxParticipants;
  final Duration defaultDuration;
  final Duration minDuration;
  final Duration maxDuration;
  final bool recordingEnabled;
  final bool breakoutRoomsEnabled;
  final bool waitingRoomEnabled;
  final bool chatEnabled;
  final bool screenSharingEnabled;
  final bool handRaiseEnabled;
  final bool pollingEnabled;
  final bool qaEnabled;
  final OnlineClassPlatform defaultPlatform;
  final Set<OnlineClassPlatform> supportedPlatforms;
  final Duration bufferTimeBefore;
  final Duration bufferTimeAfter;
  final int maxConcurrentSessions;
  final bool requireModeratorApproval;
  final bool allowRecordingDownload;
  final int recordingRetentionDays;

  OnlineClassConfig({
    required this.maxParticipants,
    required this.defaultDuration,
    required this.minDuration,
    required this.maxDuration,
    required this.recordingEnabled,
    required this.breakoutRoomsEnabled,
    required this.waitingRoomEnabled,
    required this.chatEnabled,
    required this.screenSharingEnabled,
    required this.handRaiseEnabled,
    required this.pollingEnabled,
    required this.qaEnabled,
    required this.defaultPlatform,
    required this.supportedPlatforms,
    required this.bufferTimeBefore,
    required this.bufferTimeAfter,
    required this.maxConcurrentSessions,
    required this.requireModeratorApproval,
    required this.allowRecordingDownload,
    required this.recordingRetentionDays,
  });

  /// Create a copy with updated values
  OnlineClassConfig copyWith({
    int? maxParticipants,
    Duration? defaultDuration,
    Duration? minDuration,
    Duration? maxDuration,
    bool? recordingEnabled,
    bool? breakoutRoomsEnabled,
    bool? waitingRoomEnabled,
    bool? chatEnabled,
    bool? screenSharingEnabled,
    bool? handRaiseEnabled,
    bool? pollingEnabled,
    bool? qaEnabled,
    OnlineClassPlatform? defaultPlatform,
    Set<OnlineClassPlatform>? supportedPlatforms,
    Duration? bufferTimeBefore,
    Duration? bufferTimeAfter,
    int? maxConcurrentSessions,
    bool? requireModeratorApproval,
    bool? allowRecordingDownload,
    int? recordingRetentionDays,
  }) {
    return OnlineClassConfig(
      maxParticipants: maxParticipants ?? this.maxParticipants,
      defaultDuration: defaultDuration ?? this.defaultDuration,
      minDuration: minDuration ?? this.minDuration,
      maxDuration: maxDuration ?? this.maxDuration,
      recordingEnabled: recordingEnabled ?? this.recordingEnabled,
      breakoutRoomsEnabled: breakoutRoomsEnabled ?? this.breakoutRoomsEnabled,
      waitingRoomEnabled: waitingRoomEnabled ?? this.waitingRoomEnabled,
      chatEnabled: chatEnabled ?? this.chatEnabled,
      screenSharingEnabled: screenSharingEnabled ?? this.screenSharingEnabled,
      handRaiseEnabled: handRaiseEnabled ?? this.handRaiseEnabled,
      pollingEnabled: pollingEnabled ?? this.pollingEnabled,
      qaEnabled: qaEnabled ?? this.qaEnabled,
      defaultPlatform: defaultPlatform ?? this.defaultPlatform,
      supportedPlatforms: supportedPlatforms ?? this.supportedPlatforms,
      bufferTimeBefore: bufferTimeBefore ?? this.bufferTimeBefore,
      bufferTimeAfter: bufferTimeAfter ?? this.bufferTimeAfter,
      maxConcurrentSessions: maxConcurrentSessions ?? this.maxConcurrentSessions,
      requireModeratorApproval: requireModeratorApproval ?? this.requireModeratorApproval,
      allowRecordingDownload: allowRecordingDownload ?? this.allowRecordingDownload,
      recordingRetentionDays: recordingRetentionDays ?? this.recordingRetentionDays,
    );
  }

  /// Convert to map for storage
  Map<String, dynamic> toMap() {
    return {
      'max_participants': maxParticipants,
      'default_duration_minutes': defaultDuration.inMinutes,
      'min_duration_minutes': minDuration.inMinutes,
      'max_duration_minutes': maxDuration.inMinutes,
      'recording_enabled': recordingEnabled,
      'breakout_rooms_enabled': breakoutRoomsEnabled,
      'waiting_room_enabled': waitingRoomEnabled,
      'chat_enabled': chatEnabled,
      'screen_sharing_enabled': screenSharingEnabled,
      'hand_raise_enabled': handRaiseEnabled,
      'polling_enabled': pollingEnabled,
      'qa_enabled': qaEnabled,
      'default_platform': defaultPlatform.name,
      'supported_platforms': supportedPlatforms.map((e) => e.name).toList(),
      'buffer_time_before_minutes': bufferTimeBefore.inMinutes,
      'buffer_time_after_minutes': bufferTimeAfter.inMinutes,
      'max_concurrent_sessions': maxConcurrentSessions,
      'require_moderator_approval': requireModeratorApproval,
      'allow_recording_download': allowRecordingDownload,
      'recording_retention_days': recordingRetentionDays,
    };
  }

  /// Create from map
  factory OnlineClassConfig.fromMap(Map<String, dynamic> map) {
    return OnlineClassConfig(
      maxParticipants: map['max_participants'] as int,
      defaultDuration: Duration(minutes: map['default_duration_minutes'] as int),
      minDuration: Duration(minutes: map['min_duration_minutes'] as int),
      maxDuration: Duration(minutes: map['max_duration_minutes'] as int),
      recordingEnabled: map['recording_enabled'] as bool,
      breakoutRoomsEnabled: map['breakout_rooms_enabled'] as bool,
      waitingRoomEnabled: map['waiting_room_enabled'] as bool,
      chatEnabled: map['chat_enabled'] as bool,
      screenSharingEnabled: map['screen_sharing_enabled'] as bool,
      handRaiseEnabled: map['hand_raise_enabled'] as bool,
      pollingEnabled: map['polling_enabled'] as bool,
      qaEnabled: map['qa_enabled'] as bool,
      defaultPlatform: OnlineClassPlatform.values.firstWhere(
        (e) => e.name == map['default_platform'],
        orElse: () => OnlineClassPlatform.zoom,
      ),
      supportedPlatforms: (map['supported_platforms'] as List)
          .map((e) => OnlineClassPlatform.values.firstWhere(
                (p) => p.name == e,
                orElse: () => OnlineClassPlatform.zoom,
              ))
          .toSet(),
      bufferTimeBefore: Duration(minutes: map['buffer_time_before_minutes'] as int),
      bufferTimeAfter: Duration(minutes: map['buffer_time_after_minutes'] as int),
      maxConcurrentSessions: map['max_concurrent_sessions'] as int,
      requireModeratorApproval: map['require_moderator_approval'] as bool,
      allowRecordingDownload: map['allow_recording_download'] as bool,
      recordingRetentionDays: map['recording_retention_days'] as int,
    );
  }

  @override
  String toString() {
    return 'OnlineClassConfig(maxParticipants: $maxParticipants, defaultDuration: $defaultDuration)';
  }
}