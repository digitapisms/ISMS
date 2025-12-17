import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isms_app/src/features/institution/application/institution_config_loader.dart';
import 'package:isms_app/src/features/institution/domain/institution_academic_factory.dart';
import 'package:isms_app/src/features/online_classes/domain/online_class.dart';
import 'package:isms_app/src/features/online_classes/domain/online_class_config.dart';
import 'package:isms_app/src/features/online_classes/domain/online_class_platform.dart';
import 'package:isms_app/src/features/online_classes/domain/online_class_session.dart';
import 'package:isms_app/src/features/online_classes/services/zoom_service.dart';
import 'package:isms_app/src/features/online_classes/services/google_meet_service.dart';

/// Online class engine for handling institution-specific online class logic
class OnlineClassEngine {
  final InstitutionConfigLoader _configLoader;

  OnlineClassEngine(this._configLoader);

  /// Get online class configuration for a specific institution type
  Future<OnlineClassConfig> getOnlineClassConfig(
    String institutionTypeId,
  ) async {
    final academicConfig = await _configLoader.loadAcademicConfig(
      institutionTypeId,
    );

    // Default configuration that can be overridden by institution type
    var config = OnlineClassConfig(
      maxParticipants: 100,
      defaultDuration: Duration(minutes: 45),
      recordingEnabled: true,
      breakoutRoomsEnabled: false,
      waitingRoomEnabled: true,
      chatEnabled: true,
      screenSharingEnabled: true,
      handRaiseEnabled: true,
      pollingEnabled: false,
      qaEnabled: true,
      defaultPlatform: OnlineClassPlatform.zoom,
      supportedPlatforms: {
        OnlineClassPlatform.zoom,
        OnlineClassPlatform.googleMeet,
      },
      minDuration: Duration(minutes: 15),
      maxDuration: Duration(hours: 4),
      bufferTimeBefore: Duration(minutes: 5),
      bufferTimeAfter: Duration(minutes: 10),
      maxConcurrentSessions: 10,
      requireModeratorApproval: false,
      allowRecordingDownload: true,
      recordingRetentionDays: 30,
    );

    // Apply institution-specific overrides
    switch (academicConfig.institutionType) {
      case InstitutionType.madrasa:
        config = config.copyWith(
          maxParticipants: 50,
          defaultDuration: Duration(minutes: 60),
          recordingEnabled: false, // Madrasas may prefer no recording
          breakoutRoomsEnabled: false,
          pollingEnabled: false,
          requireModeratorApproval: true,
        );
        break;
      case InstitutionType.coachingCenter:
        config = config.copyWith(
          maxParticipants: 25,
          defaultDuration: Duration(minutes: 90),
          recordingEnabled: true,
          breakoutRoomsEnabled: true,
          pollingEnabled: true,
          qaEnabled: true,
          requireModeratorApproval: false,
        );
        break;
      case InstitutionType.tuitionCenter:
        config = config.copyWith(
          maxParticipants: 15,
          defaultDuration: Duration(minutes: 120),
          recordingEnabled: true,
          breakoutRoomsEnabled: false,
          pollingEnabled: false,
          qaEnabled: true,
          requireModeratorApproval: false,
        );
        break;
      case InstitutionType.school:
        config = config.copyWith(
          maxParticipants: 100,
          defaultDuration: Duration(minutes: 45),
          recordingEnabled: true,
          breakoutRoomsEnabled: true,
          pollingEnabled: true,
          qaEnabled: true,
          requireModeratorApproval: true,
        );
        break;
    }

    return config;
  }

  /// Validate if an online class session can be created
  Future<List<String>> validateOnlineClass(OnlineClass onlineClass) async {
    final config = await getOnlineClassConfig(onlineClass.institutionTypeId);
    final errors = <String>[];

    // Validate duration
    if (onlineClass.duration.inMinutes < config.minDuration.inMinutes) {
      errors.add(
        'Duration must be at least ${config.minDuration.inMinutes} minutes',
      );
    }
    if (onlineClass.duration.inMinutes > config.maxDuration.inMinutes) {
      errors.add(
        'Duration cannot exceed ${config.maxDuration.inMinutes} minutes',
      );
    }

    // Validate platform support
    if (!config.supportedPlatforms.contains(onlineClass.platform)) {
      errors.add(
        'Selected platform is not supported for this institution type',
      );
    }

    // Validate participant limit
    if (onlineClass.expectedParticipants > config.maxParticipants) {
      errors.add(
        'Maximum participants exceeded. Limit: ${config.maxParticipants}',
      );
    }

    // Validate recording settings
    if (onlineClass.recordSession && !config.recordingEnabled) {
      errors.add('Recording is not enabled for this institution type');
    }

    // Validate breakout rooms
    if (onlineClass.breakoutRoomsEnabled && !config.breakoutRoomsEnabled) {
      errors.add('Breakout rooms are not enabled for this institution type');
    }

    return errors;
  }

  /// Generate meeting join URL based on platform
  /// For Zoom, this will create an actual meeting via API
  Future<String> generateMeetingUrl(OnlineClass onlineClass) async {
    final config = await getOnlineClassConfig(onlineClass.institutionTypeId);

    switch (onlineClass.platform) {
      case OnlineClassPlatform.zoom:
        return await _generateZoomMeetingUrl(onlineClass, config);
      case OnlineClassPlatform.googleMeet:
        return await _generateGoogleMeetUrl(onlineClass, config);
      case OnlineClassPlatform.custom:
        return onlineClass.customMeetingUrl ?? '';
    }
  }

  /// Generate meeting credentials/password
  Future<String> generateMeetingCredentials(OnlineClass onlineClass) async {
    final config = await getOnlineClassConfig(onlineClass.institutionTypeId);

    // Simple password generation - in production, use more secure methods
    final random = DateTime.now().millisecondsSinceEpoch.toString();
    return '${onlineClass.id.substring(0, 4)}${random.substring(random.length - 4)}';
  }

  /// Check if a session can be started (considering buffer times)
  Future<bool> canStartSession(OnlineClassSession session) async {
    final now = DateTime.now();
    final config = await getOnlineClassConfig(
      session.onlineClass.institutionTypeId,
    );

    final bufferStart = session.scheduledStart.subtract(
      config.bufferTimeBefore,
    );
    final bufferEnd = session.scheduledEnd.add(config.bufferTimeAfter);

    return now.isAfter(bufferStart) && now.isBefore(bufferEnd);
  }

  /// Get recommended platform for institution type
  Future<OnlineClassPlatform> getRecommendedPlatform(
    String institutionTypeId,
  ) async {
    final config = await getOnlineClassConfig(institutionTypeId);
    return config.defaultPlatform;
  }

  // Private methods for platform-specific URL generation
  Future<String> _generateZoomMeetingUrl(
    OnlineClass onlineClass,
    OnlineClassConfig config,
  ) async {
    try {
      final zoomService = ZoomService();

      // Create Zoom meeting with settings from config
      final meeting = await zoomService.createMeeting(
        title: onlineClass.title,
        startTime: onlineClass.scheduledStart,
        duration: onlineClass.duration.inMinutes,
        description: onlineClass.description,
        password: onlineClass.meetingPassword.isNotEmpty
            ? onlineClass.meetingPassword
            : ZoomService.generatePassword(),
        settings: ZoomMeetingSettings(
          waitingRoom: onlineClass.waitingRoomEnabled,
          joinBeforeHost: false,
          muteUponEntry: false,
          watermark: false,
          usePmi: false,
          approvalType: 0, // Automatically approve
          audio: 'both',
          autoRecording: onlineClass.recordSession ? 'cloud' : 'none',
          enforceLogin: false,
          showShareButton: true,
          allowMultipleDevices: true,
        ),
      );

      return meeting.joinUrl;
    } catch (e) {
      // Fallback to placeholder URL if API call fails
      print('Error creating Zoom meeting: $e');
      return 'https://zoom.us/j/${onlineClass.id}?pwd=${onlineClass.meetingPassword}';
    }
  }

  Future<String> _generateGoogleMeetUrl(
    OnlineClass onlineClass,
    OnlineClassConfig config,
  ) async {
    try {
      final googleMeetService = GoogleMeetService();

      // Create Google Meet with settings from config
      final meeting = await googleMeetService.createMeeting(
        title: onlineClass.title,
        startTime: onlineClass.scheduledStart,
        duration: onlineClass.duration.inMinutes,
        description: onlineClass.description,
      );

      return meeting.joinUrl;
    } catch (e) {
      // Fallback to placeholder URL if API call fails
      print('Error creating Google Meet: $e');
      return 'https://meet.google.com/${onlineClass.id.substring(0, 12)}';
    }
  }
}

/// Riverpod provider for OnlineClassEngine
final onlineClassEngineProvider = Provider<OnlineClassEngine>((ref) {
  final configLoader = ref.read(institutionConfigLoaderProvider);
  return OnlineClassEngine(configLoader);
});
