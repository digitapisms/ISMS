import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/network/supabase_client.dart';
import '../domain/discipline_action.dart';
import '../domain/discipline_incident.dart';

class DisciplineRepository {
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

  // Incidents
  Future<DisciplineIncident> createIncident(DisciplineIncident incident) async {
    _requireSchoolId();
    final response = await _client
        .from('discipline_incidents')
        .insert(_withSchoolId(incident.toJson()))
        .select()
        .single();
    return DisciplineIncident.fromJson(response);
  }

  Future<List<DisciplineIncident>> fetchIncidents({
    String? studentId,
    DateTime? startDate,
    DateTime? endDate,
    IncidentType? incidentType,
    IncidentStatus? status,
  }) async {
    _requireSchoolId();
    var query = _client
        .from('discipline_incidents')
        .select()
        .eq('school_id', _requireSchoolId());

    if (studentId != null) {
      query = query.eq('student_id', studentId);
    }
    if (startDate != null) {
      query = query.gte('incident_date', startDate.toIso8601String());
    }
    if (endDate != null) {
      query = query.lte('incident_date', endDate.toIso8601String());
    }
    if (incidentType != null) {
      query = query.eq('incident_type', incidentType.dbValue);
    }
    if (status != null) {
      query = query.eq('status', status.dbValue);
    }

    final response = await query.order('incident_date', ascending: false);
    return (response as List)
        .map((json) => DisciplineIncident.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<DisciplineIncident> updateIncident(DisciplineIncident incident) async {
    _requireSchoolId();
    final response = await _client
        .from('discipline_incidents')
        .update(incident.toJson())
        .eq('id', incident.id)
        .eq('school_id', _requireSchoolId())
        .select()
        .single();
    return DisciplineIncident.fromJson(response);
  }

  Future<void> deleteIncident(String incidentId) async {
    _requireSchoolId();
    await _client
        .from('discipline_incidents')
        .delete()
        .eq('id', incidentId)
        .eq('school_id', _requireSchoolId());
  }

  // Actions
  Future<DisciplineAction> createAction(DisciplineAction action) async {
    _requireSchoolId();
    final response = await _client
        .from('discipline_actions')
        .insert(_withSchoolId(action.toJson()))
        .select()
        .single();
    return DisciplineAction.fromJson(response);
  }

  Future<List<DisciplineAction>> fetchActions({
    String? incidentId,
    String? studentId,
  }) async {
    _requireSchoolId();
    var query = _client
        .from('discipline_actions')
        .select()
        .eq('school_id', _requireSchoolId());

    if (incidentId != null) {
      query = query.eq('incident_id', incidentId);
    }
    if (studentId != null) {
      query = query.eq('student_id', studentId);
    }

    final response = await query.order('action_date', ascending: false);
    return (response as List)
        .map((json) => DisciplineAction.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<DisciplineAction> updateAction(DisciplineAction action) async {
    _requireSchoolId();
    final response = await _client
        .from('discipline_actions')
        .update(action.toJson())
        .eq('id', action.id)
        .eq('school_id', _requireSchoolId())
        .select()
        .single();
    return DisciplineAction.fromJson(response);
  }

  Future<void> deleteAction(String actionId) async {
    _requireSchoolId();
    await _client
        .from('discipline_actions')
        .delete()
        .eq('id', actionId)
        .eq('school_id', _requireSchoolId());
  }
}

