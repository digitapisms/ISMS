import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/network/supabase_client.dart';
import '../domain/online_class.dart';
import '../domain/online_class_platform.dart';
import '../domain/online_class_session.dart';
import '../services/zoom_service.dart';

class OnlineClassRepository {
  SupabaseClient get _client => SupabaseManager.client;

  String? _schoolId;

  void setSchoolId(String? schoolId) {
    _schoolId = schoolId;
  }

  String? get schoolId => _schoolId;

  String _requireSchoolId() {
    final id = _schoolId;
    if (id == null) {
      throw Exception(
        'School context is required. Please ensure you are signed in to a school tenant.',
      );
    }
    return id;
  }

  Future<String?> _getCurrentUserId() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;

    final response = await _client
        .from('users')
        .select('id')
        .eq('auth_id', user.id)
        .maybeSingle();

    return response?['id'] as String?;
  }

  // ==================== Online Classes ====================

  /// Fetch all online classes for the current school
  Future<List<OnlineClass>> fetchOnlineClasses({
    bool? activeOnly,
    String? institutionTypeId,
  }) async {
    final schoolId = _requireSchoolId();
    
    var query = _client
        .from('online_classes')
        .select()
        .eq('school_id', schoolId);

    if (activeOnly == true) {
      query = query.eq('is_active', true);
    }

    if (institutionTypeId != null) {
      query = query.eq('institution_type_id', institutionTypeId);
    }

    final response = await query
        .order('scheduled_start', ascending: true)
        .order('created_at', ascending: false);

    final data = response as List;
    return data.map((row) => OnlineClass.fromMap(row)).toList();
  }

  /// Fetch a specific online class by ID
  Future<OnlineClass?> fetchOnlineClass(String id) async {
    final schoolId = _requireSchoolId();
    
    final response = await _client
        .from('online_classes')
        .select()
        .eq('id', id)
        .eq('school_id', schoolId)
        .maybeSingle();

    if (response == null) return null;
    return OnlineClass.fromMap(response);
  }

  /// Create a new online class
  /// For Zoom platform, this will create an actual Zoom meeting via API
  Future<OnlineClass> createOnlineClass(OnlineClass onlineClass) async {
    final schoolId = _requireSchoolId();
    final userId = await _getCurrentUserId();
    
    if (userId == null) {
      throw Exception('User must be authenticated to create online classes');
    }

    // If platform is Zoom, create actual Zoom meeting
    String meetingUrl = onlineClass.meetingUrl;
    String meetingPassword = onlineClass.meetingPassword;

    if (onlineClass.platform == OnlineClassPlatform.zoom) {
      try {
        final zoomService = ZoomService();
        
        // Generate password if not provided
        if (meetingPassword.isEmpty) {
          meetingPassword = ZoomService.generatePassword();
        }

        // Create Zoom meeting
        final zoomMeeting = await zoomService.createMeeting(
          title: onlineClass.title,
          startTime: onlineClass.scheduledStart,
          duration: onlineClass.duration.inMinutes,
          description: onlineClass.description,
          password: meetingPassword,
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

        // Update meeting URL and password from Zoom response
        meetingUrl = zoomMeeting.joinUrl;
        meetingPassword = zoomMeeting.password ?? meetingPassword;
      } catch (e) {
        // Log error but continue with placeholder URL
        print('Warning: Failed to create Zoom meeting: $e');
        // Use fallback URL if Zoom API fails
        if (meetingUrl.isEmpty) {
          meetingUrl = 'https://zoom.us/j/${onlineClass.id}?pwd=$meetingPassword';
        }
      }
    }

    // Create online class with meeting URL and password
    final onlineClassWithMeeting = onlineClass.copyWith(
      meetingUrl: meetingUrl,
      meetingPassword: meetingPassword,
    );

    final onlineClassMap = onlineClassWithMeeting.toMap()..['school_id'] = schoolId;
    onlineClassMap['created_by'] = userId;
    onlineClassMap['updated_at'] = DateTime.now().toIso8601String();

    final response = await _client
        .from('online_classes')
        .insert(onlineClassMap)
        .select()
        .single();

    return OnlineClass.fromMap(response);
  }

  /// Update an existing online class
  Future<OnlineClass> updateOnlineClass(OnlineClass onlineClass) async {
    final schoolId = _requireSchoolId();
    
    final onlineClassMap = onlineClass.toMap()..['updated_at'] = DateTime.now().toIso8601String();

    final response = await _client
        .from('online_classes')
        .update(onlineClassMap)
        .eq('id', onlineClass.id)
        .eq('school_id', schoolId)
        .select()
        .single();

    return OnlineClass.fromMap(response);
  }

  /// Delete an online class
  Future<void> deleteOnlineClass(String id) async {
    final schoolId = _requireSchoolId();
    
    await _client
        .from('online_classes')
        .delete()
        .eq('id', id)
        .eq('school_id', schoolId);
  }

  /// Toggle online class active status
  Future<OnlineClass> toggleOnlineClassStatus(String id, bool isActive) async {
    final schoolId = _requireSchoolId();
    
    final response = await _client
        .from('online_classes')
        .update({
          'is_active': isActive,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', id)
        .eq('school_id', schoolId)
        .select()
        .single();

    return OnlineClass.fromMap(response);
  }

  // ==================== Online Class Sessions ====================

  /// Fetch sessions for a specific online class
  Future<List<OnlineClassSession>> fetchSessions(String onlineClassId) async {
    final schoolId = _requireSchoolId();
    
    // First get the online class
    final onlineClass = await fetchOnlineClass(onlineClassId);
    if (onlineClass == null) {
      throw Exception('Online class not found');
    }

    final response = await _client
        .from('online_class_sessions')
        .select()
        .eq('online_class_id', onlineClassId)
        .eq('school_id', schoolId)
        .order('scheduled_start', ascending: true);

    final data = response as List;
    return data
        .map((row) => OnlineClassSession.fromMap(row, onlineClass))
        .toList();
  }

  /// Create a new session for an online class
  Future<OnlineClassSession> createSession(OnlineClassSession session) async {
    final schoolId = _requireSchoolId();
    final userId = await _getCurrentUserId();
    
    if (userId == null) {
      throw Exception('User must be authenticated to create sessions');
    }

    final sessionMap = session.toMap()..['school_id'] = schoolId;
    sessionMap['created_by'] = userId;
    sessionMap['updated_at'] = DateTime.now().toIso8601String();

    final response = await _client
        .from('online_class_sessions')
        .insert(sessionMap)
        .select()
        .single();

    return OnlineClassSession.fromMap(response, session.onlineClass);
  }

  /// Update a session
  Future<OnlineClassSession> updateSession(OnlineClassSession session) async {
    final schoolId = _requireSchoolId();
    
    final sessionMap = session.toMap()..['updated_at'] = DateTime.now().toIso8601String();

    final response = await _client
        .from('online_class_sessions')
        .update(sessionMap)
        .eq('id', session.id)
        .eq('school_id', schoolId)
        .select()
        .single();

    return OnlineClassSession.fromMap(response, session.onlineClass);
  }

  /// Update session status
  Future<OnlineClassSession> updateSessionStatus(
    String sessionId,
    SessionStatus status,
  ) async {
    final schoolId = _requireSchoolId();
    
    final response = await _client
        .from('online_class_sessions')
        .update({
          'status': status.name,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', sessionId)
        .eq('school_id', schoolId)
        .select()
        .single();

    // Get the session to return with full online class data
    final sessionResponse = await _client
        .from('online_class_sessions')
        .select()
        .eq('id', sessionId)
        .single();

    final onlineClassId = sessionResponse['online_class_id'] as String;
    final onlineClass = await fetchOnlineClass(onlineClassId);
    
    if (onlineClass == null) {
      throw Exception('Online class not found');
    }

    return OnlineClassSession.fromMap(sessionResponse, onlineClass);
  }

  /// Record session start time
  Future<OnlineClassSession> recordSessionStart(String sessionId) async {
    final schoolId = _requireSchoolId();
    final now = DateTime.now();
    
    final response = await _client
        .from('online_class_sessions')
        .update({
          'actual_start': now.toIso8601String(),
          'status': SessionStatus.inProgress.name,
          'updated_at': now.toIso8601String(),
        })
        .eq('id', sessionId)
        .eq('school_id', schoolId)
        .select()
        .single();

    final sessionResponse = await _client
        .from('online_class_sessions')
        .select()
        .eq('id', sessionId)
        .single();

    final onlineClassId = sessionResponse['online_class_id'] as String;
    final onlineClass = await fetchOnlineClass(onlineClassId);
    
    if (onlineClass == null) {
      throw Exception('Online class not found');
    }

    return OnlineClassSession.fromMap(sessionResponse, onlineClass);
  }

  /// Record session end time
  Future<OnlineClassSession> recordSessionEnd(String sessionId) async {
    final schoolId = _requireSchoolId();
    final now = DateTime.now();
    
    final response = await _client
        .from('online_class_sessions')
        .update({
          'actual_end': now.toIso8601String(),
          'status': SessionStatus.completed.name,
          'updated_at': now.toIso8601String(),
        })
        .eq('id', sessionId)
        .eq('school_id', schoolId)
        .select()
        .single();

    final sessionResponse = await _client
        .from('online_class_sessions')
        .select()
        .eq('id', sessionId)
        .single();

    final onlineClassId = sessionResponse['online_class_id'] as String;
    final onlineClass = await fetchOnlineClass(onlineClassId);
    
    if (onlineClass == null) {
      throw Exception('Online class not found');
    }

    return OnlineClassSession.fromMap(sessionResponse, onlineClass);
  }

  /// Update participant count for a session
  Future<OnlineClassSession> updateParticipantCount(
    String sessionId,
    int participantCount,
  ) async {
    final schoolId = _requireSchoolId();
    
    final response = await _client
        .from('online_class_sessions')
        .update({
          'actual_participants': participantCount,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', sessionId)
        .eq('school_id', schoolId)
        .select()
        .single();

    final sessionResponse = await _client
        .from('online_class_sessions')
        .select()
        .eq('id', sessionId)
        .single();

    final onlineClassId = sessionResponse['online_class_id'] as String;
    final onlineClass = await fetchOnlineClass(onlineClassId);
    
    if (onlineClass == null) {
      throw Exception('Online class not found');
    }

    return OnlineClassSession.fromMap(sessionResponse, onlineClass);
  }

  /// Fetch upcoming sessions
  Future<List<OnlineClassSession>> fetchUpcomingSessions({
    int? limit,
    String? institutionTypeId,
  }) async {
    final schoolId = _requireSchoolId();
    final now = DateTime.now().toIso8601String();
    
    var query = _client
        .from('online_class_sessions')
        .select()
        .eq('school_id', schoolId)
        .gte('scheduled_start', now)
        .eq('status', SessionStatus.scheduled.name)
        .order('scheduled_start', ascending: true);

    if (limit != null) {
      query = query.limit(limit);
    }

    if (institutionTypeId != null) {
      // We need to join with online_classes to filter by institution type
      // This is a simplified approach - in production, use a proper join
      final sessions = await query;
      final data = sessions as List;
      
      // Filter sessions by institution type
      final filteredSessions = <OnlineClassSession>[];
      for (final sessionData in data) {
        final onlineClassId = sessionData['online_class_id'] as String;
        final onlineClass = await fetchOnlineClass(onlineClassId);
        
        if (onlineClass != null && onlineClass.institutionTypeId == institutionTypeId) {
          filteredSessions.add(OnlineClassSession.fromMap(sessionData, onlineClass));
        }
      }
      
      return filteredSessions;
    }

    final response = await query;
    final data = response as List;
    
    // We need to fetch the online class for each session
    final sessions = <OnlineClassSession>[];
    for (final sessionData in data) {
      final onlineClassId = sessionData['online_class_id'] as String;
      final onlineClass = await fetchOnlineClass(onlineClassId);
      
      if (onlineClass != null) {
        sessions.add(OnlineClassSession.fromMap(sessionData, onlineClass));
      }
    }
    
    return sessions;
  }
}