import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/network/supabase_client.dart';

/// Google Meet meeting details
class GoogleMeetMeeting {
  final String id;
  final String conferenceId;
  final String joinUrl;
  final String startUrl;
  final String? entryPointAccessCode;
  final Map<String, dynamic> conferenceData;

  GoogleMeetMeeting({
    required this.id,
    required this.conferenceId,
    required this.joinUrl,
    required this.startUrl,
    this.entryPointAccessCode,
    required this.conferenceData,
  });

  factory GoogleMeetMeeting.fromMap(Map<String, dynamic> map) {
    return GoogleMeetMeeting(
      id: map['id'] as String,
      conferenceId: map['conferenceId'] as String,
      joinUrl: map['joinUrl'] as String,
      startUrl: map['startUrl'] as String,
      entryPointAccessCode: map['entryPointAccessCode'] as String?,
      conferenceData: map['conferenceData'] as Map<String, dynamic>,
    );
  }
}

/// Service for interacting with Google Meet API via Supabase Edge Function
class GoogleMeetService {
  final SupabaseClient _client = SupabaseManager.client;

  /// Create a Google Meet meeting
  ///
  /// [title] - Meeting title
  /// [startTime] - Meeting start time (ISO 8601 format)
  /// [duration] - Meeting duration in minutes
  /// [description] - Optional meeting description/agenda
  ///
  /// Returns a [GoogleMeetMeeting] object with meeting details
  Future<GoogleMeetMeeting> createMeeting({
    required String title,
    required DateTime startTime,
    required int duration,
    String? description,
  }) async {
    try {
      // Call Supabase Edge Function
      final response = await _client.functions.invoke(
        'create-google-meet',
        body: {
          'title': title,
          'description': description,
          'startTime': startTime.toUtc().toIso8601String(),
          'duration': duration,
        },
      );

      if (response.status != 200) {
        final errorData = response.data;
        throw Exception(
          errorData?['error'] ??
              'Failed to create Google Meet: ${response.status}',
        );
      }

      final data = response.data as Map<String, dynamic>;
      final meetingData = data['meeting'] as Map<String, dynamic>;

      return GoogleMeetMeeting.fromMap(meetingData);
    } catch (e) {
      throw Exception('Failed to create Google Meet: $e');
    }
  }
}
