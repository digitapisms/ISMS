import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/network/supabase_client.dart';
import '../domain/ptm_meeting.dart';
import '../domain/ptm_note.dart';

class PTMRepository {
  SupabaseClient get _client => SupabaseManager.client;
  String? _schoolId;

  void setSchoolId(String? schoolId) {
    _schoolId = schoolId;
  }

  String? get schoolId => _schoolId;

  String _requireSchoolId() {
    final id = _schoolId;
    if (id == null) {
      throw Exception('School context is required');
    }
    return id;
  }

  Map<String, dynamic> _withSchoolId(Map<String, dynamic> data) {
    final id = _schoolId;
    if (id == null) return data;
    return {...data, 'school_id': id};
  }

  Future<PTMMeeting> createMeeting(PTMMeeting meeting) async {
    _requireSchoolId();
    final response = await _client
        .from('ptm_meetings')
        .insert(_withSchoolId(meeting.toJson()))
        .select()
        .single();
    return PTMMeeting.fromJson(response);
  }

  Future<List<PTMMeeting>> fetchMeetings({
    String? studentId,
    String? teacherId,
    String? parentId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    _requireSchoolId();
    var query = _client
        .from('ptm_meetings')
        .select()
        .eq('school_id', _requireSchoolId());

    if (studentId != null) {
      query = query.eq('student_id', studentId);
    }
    if (teacherId != null) {
      query = query.eq('teacher_id', teacherId);
    }
    if (parentId != null) {
      query = query.eq('parent_id', parentId);
    }
    if (startDate != null) {
      query = query.gte('meeting_date', startDate.toIso8601String());
    }
    if (endDate != null) {
      query = query.lte('meeting_date', endDate.toIso8601String());
    }

    final response = await query.order('meeting_date', ascending: false);
    return (response as List)
        .map((json) => PTMMeeting.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<PTMMeeting> updateMeeting(PTMMeeting meeting) async {
    _requireSchoolId();
    final response = await _client
        .from('ptm_meetings')
        .update(meeting.toJson())
        .eq('id', meeting.id)
        .eq('school_id', _requireSchoolId())
        .select()
        .single();
    return PTMMeeting.fromJson(response);
  }

  Future<void> deleteMeeting(String meetingId) async {
    _requireSchoolId();
    await _client
        .from('ptm_meetings')
        .delete()
        .eq('id', meetingId)
        .eq('school_id', _requireSchoolId());
  }

  Future<PTMNote> createNote(PTMNote note) async {
    _requireSchoolId();
    // Check if table uses appointment_id or meeting_id
    final noteJson = note.toJson();
    // If table uses appointment_id, map meeting_id to appointment_id
    if (noteJson.containsKey('meeting_id')) {
      noteJson['appointment_id'] = noteJson.remove('meeting_id');
    }
    final response = await _client
        .from('ptm_notes')
        .insert(noteJson)
        .select()
        .single();
    final responseMap = response as Map<String, dynamic>;
    // Map appointment_id back to meeting_id if needed
    if (responseMap.containsKey('appointment_id') && !responseMap.containsKey('meeting_id')) {
      responseMap['meeting_id'] = responseMap['appointment_id'];
    }
    return PTMNote.fromJson(responseMap);
  }

  Future<List<PTMNote>> fetchNotes(String meetingId) async {
    _requireSchoolId();
    final response = await _client
        .from('ptm_notes')
        .select()
        .eq('appointment_id', meetingId) // Use appointment_id if that's the column name
        .order('created_at', ascending: false);
    final notes = (response as List)
        .map((json) {
          final jsonMap = json as Map<String, dynamic>;
          // Map appointment_id to meeting_id if needed
          if (jsonMap.containsKey('appointment_id') && !jsonMap.containsKey('meeting_id')) {
            jsonMap['meeting_id'] = jsonMap['appointment_id'];
          }
          return PTMNote.fromJson(jsonMap);
        })
        .toList();
    return notes;
  }
}

