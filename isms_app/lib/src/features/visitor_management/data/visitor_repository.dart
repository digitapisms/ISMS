import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/network/supabase_client.dart';
import '../domain/security_entry.dart';
import '../domain/visit.dart';
import '../domain/visitor.dart';
import '../domain/visitor_log.dart';
import '../domain/visitor_type.dart';

class VisitorRepository {
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

  // ============================================================
  // VISITORS
  // ============================================================

  Future<Visitor> createVisitor(Visitor visitor) async {
    _requireSchoolId();
    final response = await _client
        .from('visitors')
        .insert(_withSchoolId(visitor.toJson()))
        .select()
        .single();
    return Visitor.fromJson(response);
  }

  Future<List<Visitor>> fetchVisitors({
    VisitorType? visitorType,
    bool? isBlacklisted,
    String? searchQuery,
  }) async {
    _requireSchoolId();
    var query = _client
        .from('visitors')
        .select()
        .eq('school_id', _requireSchoolId());

    if (visitorType != null) {
      query = query.eq('visitor_type', visitorType.dbValue);
    }
    if (isBlacklisted != null) {
      query = query.eq('is_blacklisted', isBlacklisted);
    }
    if (searchQuery != null && searchQuery.isNotEmpty) {
      query = query.or('full_name.ilike.%$searchQuery%,phone_number.ilike.%$searchQuery%,visitor_id_number.ilike.%$searchQuery%');
    }

    final response = await query.order('created_at', ascending: false);
    return (response as List)
        .map((json) => Visitor.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<Visitor?> findVisitorByPhone(String phoneNumber) async {
    _requireSchoolId();
    final response = await _client
        .from('visitors')
        .select()
        .eq('school_id', _requireSchoolId())
        .eq('phone_number', phoneNumber)
        .maybeSingle();
    
    if (response == null) return null;
    return Visitor.fromJson(response);
  }

  Future<Visitor> updateVisitor(Visitor visitor) async {
    _requireSchoolId();
    final response = await _client
        .from('visitors')
        .update(visitor.toJson())
        .eq('id', visitor.id)
        .eq('school_id', _requireSchoolId())
        .select()
        .single();
    return Visitor.fromJson(response);
  }

  // ============================================================
  // VISITS
  // ============================================================

  Future<Visit> createVisit(Visit visit) async {
    _requireSchoolId();
    final response = await _client
        .from('visits')
        .insert(_withSchoolId(visit.toJson()))
        .select()
        .single();
    return Visit.fromJson(response);
  }

  Future<List<Visit>> fetchVisits({
    VisitStatus? status,
    String? visitorId,
    String? hostId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    _requireSchoolId();
    var query = _client
        .from('visits')
        .select()
        .eq('school_id', _requireSchoolId());

    if (status != null) {
      query = query.eq('visit_status', status.dbValue);
    }
    if (visitorId != null) {
      query = query.eq('visitor_id', visitorId);
    }
    if (hostId != null) {
      query = query.eq('host_id', hostId);
    }
    if (startDate != null) {
      query = query.gte('check_in_time', startDate.toIso8601String());
    }
    if (endDate != null) {
      query = query.lte('check_in_time', endDate.toIso8601String());
    }

    final response = await query.order('created_at', ascending: false);
    return (response as List)
        .map((json) => Visit.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<List<Visit>> fetchActiveVisits() async {
    _requireSchoolId();
    final response = await _client
        .from('visits')
        .select()
        .eq('school_id', _requireSchoolId())
        .eq('visit_status', 'checked_in')
        .order('check_in_time', ascending: false);
    
    return (response as List)
        .map((json) => Visit.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<Visit> checkIn(String visitId, {String? badgeNumber, String? entryGate}) async {
    _requireSchoolId();
    final now = DateTime.now();
    final response = await _client
        .from('visits')
        .update({
          'check_in_time': now.toIso8601String(),
          'visit_status': 'checked_in',
          'badge_number': badgeNumber,
          'entry_gate': entryGate,
        })
        .eq('id', visitId)
        .eq('school_id', _requireSchoolId())
        .select()
        .single();
    
    // Create log entry
    final visit = Visit.fromJson(response);
    await createLog(VisitorLog(
      id: '',
      schoolId: _requireSchoolId(),
      visitId: visitId,
      visitorId: visit.visitorId,
      actionType: ActionType.checkIn,
      actionTime: now,
      location: entryGate,
    ));
    
    return visit;
  }

  Future<Visit> checkOut(String visitId, {String? exitGate}) async {
    _requireSchoolId();
    final now = DateTime.now();
    final response = await _client
        .from('visits')
        .update({
          'check_out_time': now.toIso8601String(),
          'visit_status': 'checked_out',
          'exit_gate': exitGate,
        })
        .eq('id', visitId)
        .eq('school_id', _requireSchoolId())
        .select()
        .single();
    
    // Create log entry
    final visit = Visit.fromJson(response);
    await createLog(VisitorLog(
      id: '',
      schoolId: _requireSchoolId(),
      visitId: visitId,
      visitorId: visit.visitorId,
      actionType: ActionType.checkOut,
      actionTime: now,
      location: exitGate,
    ));
    
    return visit;
  }

  // ============================================================
  // VISITOR LOGS
  // ============================================================

  Future<VisitorLog> createLog(VisitorLog log) async {
    _requireSchoolId();
    final response = await _client
        .from('visitor_logs')
        .insert(_withSchoolId(log.toJson()))
        .select()
        .single();
    return VisitorLog.fromJson(response);
  }

  Future<List<VisitorLog>> fetchLogs({
    String? visitId,
    String? visitorId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    _requireSchoolId();
    var query = _client
        .from('visitor_logs')
        .select()
        .eq('school_id', _requireSchoolId());

    if (visitId != null) {
      query = query.eq('visit_id', visitId);
    }
    if (visitorId != null) {
      query = query.eq('visitor_id', visitorId);
    }
    if (startDate != null) {
      query = query.gte('action_time', startDate.toIso8601String());
    }
    if (endDate != null) {
      query = query.lte('action_time', endDate.toIso8601String());
    }

    final response = await query.order('action_time', ascending: false);
    return (response as List)
        .map((json) => VisitorLog.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  // ============================================================
  // SECURITY ENTRIES
  // ============================================================

  Future<SecurityEntry> createSecurityEntry(SecurityEntry entry) async {
    _requireSchoolId();
    final response = await _client
        .from('security_entries')
        .insert(_withSchoolId(entry.toJson()))
        .select()
        .single();
    return SecurityEntry.fromJson(response);
  }

  Future<List<SecurityEntry>> fetchSecurityEntries({
    DateTime? startDate,
    DateTime? endDate,
    String? gateName,
    EntryType? entryType,
    AlertLevel? alertLevel,
  }) async {
    _requireSchoolId();
    var query = _client
        .from('security_entries')
        .select()
        .eq('school_id', _requireSchoolId());

    if (startDate != null) {
      query = query.gte('entry_time', startDate.toIso8601String());
    }
    if (endDate != null) {
      query = query.lte('entry_time', endDate.toIso8601String());
    }
    if (gateName != null) {
      query = query.eq('gate_name', gateName);
    }
    if (entryType != null) {
      query = query.eq('entry_type', entryType.dbValue);
    }
    if (alertLevel != null) {
      query = query.eq('security_alert_level', alertLevel.dbValue);
    }

    final response = await query.order('entry_time', ascending: false);
    return (response as List)
        .map((json) => SecurityEntry.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<List<SecurityEntry>> fetchActiveEntries() async {
    _requireSchoolId();
    final response = await _client
        .from('security_entries')
        .select()
        .eq('school_id', _requireSchoolId())
        .isFilter('exit_time', null)
        .order('entry_time', ascending: false);
    
    return (response as List)
        .map((json) => SecurityEntry.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<void> recordExit(String entryId, {String? exitGate}) async {
    _requireSchoolId();
    await _client
        .from('security_entries')
        .update({
          'exit_time': DateTime.now().toIso8601String(),
        })
        .eq('id', entryId)
        .eq('school_id', _requireSchoolId());
  }

  // ============================================================
  // BADGES
  // ============================================================

  Future<String> generateBadgeNumber() async {
    _requireSchoolId();
    final response = await _client.rpc(
      'generate_badge_number',
      params: {'p_school_id': _requireSchoolId()},
    );
    return response as String;
  }

  Future<void> issueBadge(String visitId, String badgeNumber, String issuedBy) async {
    _requireSchoolId();
    await _client
        .from('visitor_badges')
        .insert({
          'school_id': _requireSchoolId(),
          'badge_number': badgeNumber,
          'visit_id': visitId,
          'issued_by': issuedBy,
          'is_active': true,
        });
  }

  Future<void> returnBadge(String badgeNumber, String returnedBy) async {
    _requireSchoolId();
    await _client
        .from('visitor_badges')
        .update({
          'returned_at': DateTime.now().toIso8601String(),
          'returned_by': returnedBy,
          'is_active': false,
        })
        .eq('badge_number', badgeNumber)
        .eq('school_id', _requireSchoolId());
  }

  // ============================================================
  // BLACKLIST
  // ============================================================

  Future<void> blacklistVisitor(String visitorId, String reason, String blacklistedBy) async {
    _requireSchoolId();
    await _client
        .from('visitors')
        .update({
          'is_blacklisted': true,
          'blacklist_reason': reason,
          'blacklisted_at': DateTime.now().toIso8601String(),
        })
        .eq('id', visitorId)
        .eq('school_id', _requireSchoolId());
    
    await _client
        .from('visitor_blacklist')
        .insert({
          'school_id': _requireSchoolId(),
          'visitor_id': visitorId,
          'reason': reason,
          'blacklisted_by': blacklistedBy,
          'is_active': true,
        });
  }
}

