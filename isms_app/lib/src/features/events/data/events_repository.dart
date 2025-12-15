import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/network/supabase_client.dart';
import '../domain/event.dart';

class EventsRepository {
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

  Future<Event> createEvent(Event event) async {
    _requireSchoolId();
    final response = await _client
        .from('events')
        .insert(_withSchoolId(event.toJson()))
        .select()
        .single();
    return Event.fromJson(response);
  }

  Future<List<Event>> fetchEvents({
    DateTime? startDate,
    DateTime? endDate,
    String? eventType,
    String? status,
  }) async {
    _requireSchoolId();
    var query = _client
        .from('events')
        .select()
        .eq('school_id', _requireSchoolId());

    if (startDate != null) {
      query = query.gte('start_date', startDate.toIso8601String());
    }
    if (endDate != null) {
      query = query.lte('start_date', endDate.toIso8601String());
    }
    if (eventType != null) {
      query = query.eq('event_type', eventType);
    }
    if (status != null) {
      query = query.eq('status', status);
    }

    final response = await query.order('start_date');
    return (response as List)
        .map((json) => Event.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<List<Map<String, dynamic>>> fetchEventRegistrations(String eventId) async {
    _requireSchoolId();
    final response = await _client
        .from('event_registrations')
        .select('''
          *,
          students:student_id (
            id,
            full_name,
            admission_no,
            class_id,
            section_id
          )
        ''')
        .eq('event_id', eventId)
        .eq('school_id', _requireSchoolId())
        .order('registered_at', ascending: false);
    
    return (response as List).cast<Map<String, dynamic>>();
  }

  Future<void> registerForEvent({
    required String eventId,
    required String studentId,
    String? notes,
  }) async {
    _requireSchoolId();
    await _client
        .from('event_registrations')
        .insert({
          'school_id': _requireSchoolId(),
          'event_id': eventId,
          'student_id': studentId,
          'notes': notes,
          'registered_at': DateTime.now().toIso8601String(),
        });
  }

  Future<void> cancelRegistration(String registrationId) async {
    _requireSchoolId();
    await _client
        .from('event_registrations')
        .update({
          'status': 'cancelled',
          'cancelled_at': DateTime.now().toIso8601String(),
        })
        .eq('id', registrationId)
        .eq('school_id', _requireSchoolId());
  }

  Future<Event> updateEvent(Event event) async {
    _requireSchoolId();
    final response = await _client
        .from('events')
        .update(event.toJson())
        .eq('id', event.id)
        .eq('school_id', _requireSchoolId())
        .select()
        .single();
    return Event.fromJson(response);
  }

  Future<void> deleteEvent(String eventId) async {
    _requireSchoolId();
    await _client
        .from('events')
        .delete()
        .eq('id', eventId)
        .eq('school_id', _requireSchoolId());
  }
}

