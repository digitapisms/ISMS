import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/network/supabase_client.dart';

/// Zoom meeting settings
class ZoomMeetingSettings {
  final bool waitingRoom;
  final bool joinBeforeHost;
  final bool muteUponEntry;
  final bool watermark;
  final bool usePmi;
  final int approvalType; // 0 = Automatically approve, 1 = Manually approve, 2 = No registration required
  final String audio; // 'both', 'telephony', 'voip'
  final String autoRecording; // 'local', 'cloud', 'none'
  final bool enforceLogin;
  final String? enforceLoginDomains;
  final String? alternativeHosts;
  final bool alternativeHostsEmailNotification;
  final bool closeRegistration;
  final bool showShareButton;
  final bool allowMultipleDevices;
  final bool registrantsConfirmationEmail;
  final bool meetingAuthentication;

  const ZoomMeetingSettings({
    this.waitingRoom = false,
    this.joinBeforeHost = false,
    this.muteUponEntry = false,
    this.watermark = false,
    this.usePmi = false,
    this.approvalType = 0,
    this.audio = 'both',
    this.autoRecording = 'none',
    this.enforceLogin = false,
    this.enforceLoginDomains,
    this.alternativeHosts,
    this.alternativeHostsEmailNotification = false,
    this.closeRegistration = false,
    this.showShareButton = true,
    this.allowMultipleDevices = false,
    this.registrantsConfirmationEmail = true,
    this.meetingAuthentication = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'waitingRoom': waitingRoom,
      'joinBeforeHost': joinBeforeHost,
      'muteUponEntry': muteUponEntry,
      'watermark': watermark,
      'usePmi': usePmi,
      'approvalType': approvalType,
      'audio': audio,
      'autoRecording': autoRecording,
      'enforceLogin': enforceLogin,
      if (enforceLoginDomains != null) 'enforceLoginDomains': enforceLoginDomains,
      if (alternativeHosts != null) 'alternativeHosts': alternativeHosts,
      'alternativeHostsEmailNotification': alternativeHostsEmailNotification,
      'closeRegistration': closeRegistration,
      'showShareButton': showShareButton,
      'allowMultipleDevices': allowMultipleDevices,
      'registrantsConfirmationEmail': registrantsConfirmationEmail,
      'meetingAuthentication': meetingAuthentication,
    };
  }
}

/// Zoom meeting details
class ZoomMeeting {
  final int id;
  final String uuid;
  final String topic;
  final String startTime;
  final int duration;
  final String joinUrl;
  final String startUrl;
  final String? password;
  final Map<String, dynamic> settings;

  ZoomMeeting({
    required this.id,
    required this.uuid,
    required this.topic,
    required this.startTime,
    required this.duration,
    required this.joinUrl,
    required this.startUrl,
    this.password,
    required this.settings,
  });

  factory ZoomMeeting.fromMap(Map<String, dynamic> map) {
    return ZoomMeeting(
      id: map['id'] as int,
      uuid: map['uuid'] as String,
      topic: map['topic'] as String,
      startTime: map['startTime'] as String,
      duration: map['duration'] as int,
      joinUrl: map['joinUrl'] as String,
      startUrl: map['startUrl'] as String,
      password: map['password'] as String?,
      settings: map['settings'] as Map<String, dynamic>,
    );
  }
}

/// Service for interacting with Zoom API via Supabase Edge Function
class ZoomService {
  final SupabaseClient _client = SupabaseManager.client;

  /// Create a Zoom meeting
  ///
  /// [title] - Meeting title
  /// [startTime] - Meeting start time (ISO 8601 format)
  /// [duration] - Meeting duration in minutes
  /// [description] - Optional meeting description/agenda
  /// [password] - Optional meeting password
  /// [settings] - Optional meeting settings
  ///
  /// Returns a [ZoomMeeting] object with meeting details
  Future<ZoomMeeting> createMeeting({
    required String title,
    required DateTime startTime,
    required int duration,
    String? description,
    String? password,
    ZoomMeetingSettings? settings,
  }) async {
    try {
      // Call Supabase Edge Function
      final response = await _client.functions.invoke(
        'create-zoom-meeting',
        body: {
          'title': title,
          'description': description,
          'startTime': startTime.toUtc().toIso8601String(),
          'duration': duration,
          if (password != null) 'password': password,
          if (settings != null) 'settings': settings.toMap(),
        },
      );

      if (response.status != 200) {
        final errorData = response.data;
        throw Exception(
          errorData?['error'] ?? 'Failed to create Zoom meeting: ${response.status}',
        );
      }

      final data = response.data as Map<String, dynamic>;
      final meetingData = data['meeting'] as Map<String, dynamic>;

      return ZoomMeeting.fromMap(meetingData);
    } catch (e) {
      throw Exception('Failed to create Zoom meeting: $e');
    }
  }

  /// Generate a secure meeting password
  static String generatePassword() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // Excluding confusing characters
    final random = DateTime.now().millisecondsSinceEpoch;
    final password = StringBuffer();
    
    for (int i = 0; i < 6; i++) {
      password.write(chars[(random + i) % chars.length]);
    }
    
    return password.toString();
  }
}

