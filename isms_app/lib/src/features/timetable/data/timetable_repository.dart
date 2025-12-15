import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/network/supabase_client.dart';
import '../../examination/domain/exam_type.dart';
import '../domain/period.dart';
import '../domain/room.dart';
import '../domain/teacher_assignment.dart';
import '../domain/timetable.dart';
import '../domain/timetable_entry.dart';

class TimetableRepository {
  SupabaseClient get _client => SupabaseManager.client;
  String? _schoolId;

  void setSchoolId(String? schoolId) {
    _schoolId = schoolId;
  }

  String? get schoolId => _schoolId;

  // ============================================================
  // PERIODS
  // ============================================================

  Future<Period> createPeriod({
    required String schoolId,
    required String name,
    required DateTime startTime,
    required DateTime endTime,
    PeriodType? periodType,
    int? displayOrder,
  }) async {
    final response = await _client
        .from('periods')
        .insert({
          'school_id': schoolId,
          'name': name,
          'start_time': startTime
              .toIso8601String()
              .split('T')[1]
              .substring(0, 8),
          'end_time': endTime.toIso8601String().split('T')[1].substring(0, 8),
          'period_type': periodType?.dbValue ?? 'regular',
          'display_order': displayOrder ?? 0,
        })
        .select()
        .single();

    return Period.fromMap(response);
  }

  Future<List<Period>> fetchPeriods({
    required String schoolId,
    bool? isActive,
  }) async {
    var query = _client.from('periods').select().eq('school_id', schoolId);

    if (isActive != null) {
      query = query.eq('is_active', isActive);
    }

    final response = await query.order('display_order');
    return (response as List)
        .map((row) => Period.fromMap(row as Map<String, dynamic>))
        .toList();
  }

  Future<Period> updatePeriod({
    required int id,
    String? name,
    DateTime? startTime,
    DateTime? endTime,
    PeriodType? periodType,
    int? displayOrder,
    bool? isActive,
  }) async {
    final updates = <String, dynamic>{};
    if (name != null) updates['name'] = name;
    if (startTime != null) {
      updates['start_time'] = startTime
          .toIso8601String()
          .split('T')[1]
          .substring(0, 8);
    }
    if (endTime != null) {
      updates['end_time'] = endTime
          .toIso8601String()
          .split('T')[1]
          .substring(0, 8);
    }
    if (periodType != null) updates['period_type'] = periodType.dbValue;
    if (displayOrder != null) updates['display_order'] = displayOrder;
    if (isActive != null) updates['is_active'] = isActive;

    final response = await _client
        .from('periods')
        .update(updates)
        .eq('id', id)
        .select()
        .single();

    return Period.fromMap(response);
  }

  // ============================================================
  // ROOMS
  // ============================================================

  Future<Room> createRoom({
    required String schoolId,
    required String name,
    String? code,
    RoomType? roomType,
    int? capacity,
    int? floorNumber,
    String? buildingName,
    List<String>? facilities,
  }) async {
    final response = await _client
        .from('rooms')
        .insert({
          'school_id': schoolId,
          'name': name,
          'code': code,
          'room_type': roomType?.dbValue ?? 'classroom',
          'capacity': capacity,
          'floor_number': floorNumber,
          'building_name': buildingName,
          'facilities': facilities ?? [],
        })
        .select()
        .single();

    return Room.fromMap(response);
  }

  Future<List<Room>> fetchRooms({
    required String schoolId,
    RoomType? roomType,
    bool? isActive,
  }) async {
    var query = _client.from('rooms').select().eq('school_id', schoolId);

    if (roomType != null) {
      query = query.eq('room_type', roomType.dbValue);
    }
    if (isActive != null) {
      query = query.eq('is_active', isActive);
    }

    final response = await query.order('name');
    return (response as List)
        .map((row) => Room.fromMap(row as Map<String, dynamic>))
        .toList();
  }

  Future<Room> updateRoom({
    required int id,
    String? name,
    String? code,
    RoomType? roomType,
    int? capacity,
    int? floorNumber,
    String? buildingName,
    List<String>? facilities,
    bool? isActive,
  }) async {
    final updates = <String, dynamic>{};
    if (name != null) updates['name'] = name;
    if (code != null) updates['code'] = code;
    if (roomType != null) updates['room_type'] = roomType.dbValue;
    if (capacity != null) updates['capacity'] = capacity;
    if (floorNumber != null) updates['floor_number'] = floorNumber;
    if (buildingName != null) updates['building_name'] = buildingName;
    if (facilities != null) updates['facilities'] = facilities;
    if (isActive != null) updates['is_active'] = isActive;

    final response = await _client
        .from('rooms')
        .update(updates)
        .eq('id', id)
        .select()
        .single();

    return Room.fromMap(response);
  }

  // ============================================================
  // TIMETABLES
  // ============================================================

  Future<Timetable> createTimetable({
    required String schoolId,
    required String name,
    required int classId,
    required String academicYear,
    int? sectionId,
    Term? term,
    DateTime? effectiveFrom,
    DateTime? effectiveTo,
    String? createdBy,
  }) async {
    final response = await _client
        .from('timetables')
        .insert({
          'school_id': schoolId,
          'name': name,
          'class_id': classId,
          'section_id': sectionId,
          'academic_year': academicYear,
          'term': term?.dbValue,
          'effective_from': effectiveFrom?.toIso8601String().split('T')[0],
          'effective_to': effectiveTo?.toIso8601String().split('T')[0],
          'created_by': createdBy,
        })
        .select()
        .single();

    return Timetable.fromMap(response);
  }

  Future<List<Timetable>> fetchTimetables({
    required String schoolId,
    int? classId,
    int? sectionId,
    String? academicYear,
    Term? term,
    bool? isActive,
  }) async {
    var query = _client.from('timetables').select().eq('school_id', schoolId);

    if (classId != null) {
      query = query.eq('class_id', classId);
    }
    if (sectionId != null) {
      query = query.eq('section_id', sectionId);
    }
    if (academicYear != null) {
      query = query.eq('academic_year', academicYear);
    }
    if (term != null) {
      query = query.eq('term', term.dbValue);
    }
    if (isActive != null) {
      query = query.eq('is_active', isActive);
    }

    final response = await query.order('academic_year', ascending: false);
    return (response as List)
        .map((row) => Timetable.fromMap(row as Map<String, dynamic>))
        .toList();
  }

  Future<Timetable> updateTimetable({
    required String id,
    String? name,
    DateTime? effectiveFrom,
    DateTime? effectiveTo,
    bool? isActive,
  }) async {
    final updates = <String, dynamic>{};
    if (name != null) updates['name'] = name;
    if (effectiveFrom != null) {
      updates['effective_from'] = effectiveFrom.toIso8601String().split('T')[0];
    }
    if (effectiveTo != null) {
      updates['effective_to'] = effectiveTo.toIso8601String().split('T')[0];
    }
    if (isActive != null) updates['is_active'] = isActive;

    final response = await _client
        .from('timetables')
        .update(updates)
        .eq('id', id)
        .select()
        .single();

    return Timetable.fromMap(response);
  }

  // ============================================================
  // TIMETABLE ENTRIES
  // ============================================================

  Future<TimetableEntry> createTimetableEntry({
    required String schoolId,
    required String timetableId,
    required int dayOfWeek,
    required int periodId,
    int? subjectId,
    String? teacherId,
    int? roomId,
    String? notes,
    bool? isSubstitute,
    String? substituteTeacherId,
  }) async {
    final response = await _client
        .from('timetable_entries')
        .insert({
          'school_id': schoolId,
          'timetable_id': timetableId,
          'day_of_week': dayOfWeek,
          'period_id': periodId,
          'subject_id': subjectId,
          'teacher_id': teacherId,
          'room_id': roomId,
          'notes': notes,
          'is_substitute': isSubstitute ?? false,
          'substitute_teacher_id': substituteTeacherId,
        })
        .select()
        .single();

    return TimetableEntry.fromMap(response);
  }

  Future<List<TimetableEntry>> fetchTimetableEntries({
    required String schoolId,
    String? timetableId,
    int? dayOfWeek,
    int? periodId,
    String? teacherId,
    int? roomId,
  }) async {
    var query = _client
        .from('timetable_entries')
        .select()
        .eq('school_id', schoolId);

    if (timetableId != null) {
      query = query.eq('timetable_id', timetableId);
    }
    if (dayOfWeek != null) {
      query = query.eq('day_of_week', dayOfWeek);
    }
    if (periodId != null) {
      query = query.eq('period_id', periodId);
    }
    if (teacherId != null) {
      query = query.eq('teacher_id', teacherId);
    }
    if (roomId != null) {
      query = query.eq('room_id', roomId);
    }

    final response = await query.order('day_of_week').order('period_id');
    return (response as List)
        .map((row) => TimetableEntry.fromMap(row as Map<String, dynamic>))
        .toList();
  }

  Future<TimetableEntry> updateTimetableEntry({
    required String id,
    int? subjectId,
    String? teacherId,
    int? roomId,
    String? notes,
    bool? isSubstitute,
    String? substituteTeacherId,
  }) async {
    final updates = <String, dynamic>{};
    if (subjectId != null) updates['subject_id'] = subjectId;
    if (teacherId != null) updates['teacher_id'] = teacherId;
    if (roomId != null) updates['room_id'] = roomId;
    if (notes != null) updates['notes'] = notes;
    if (isSubstitute != null) updates['is_substitute'] = isSubstitute;
    if (substituteTeacherId != null) {
      updates['substitute_teacher_id'] = substituteTeacherId;
    }

    final response = await _client
        .from('timetable_entries')
        .update(updates)
        .eq('id', id)
        .select()
        .single();

    return TimetableEntry.fromMap(response);
  }

  Future<void> bulkCreateTimetableEntries({
    required String schoolId,
    required List<Map<String, dynamic>> entries,
  }) async {
    await _client
        .from('timetable_entries')
        .insert(
          entries.map((entry) => {...entry, 'school_id': schoolId}).toList(),
        );
  }

  Future<void> deleteTimetableEntry(String id) async {
    await _client.from('timetable_entries').delete().eq('id', id);
  }

  // ============================================================
  // TEACHER ASSIGNMENTS
  // ============================================================

  Future<TeacherAssignment> createTeacherAssignment({
    required String schoolId,
    required String teacherId,
    required String academicYear,
    int? subjectId,
    int? classId,
    int? sectionId,
    Term? term,
    bool? isPrimary,
    double? workloadHours,
  }) async {
    final response = await _client
        .from('teacher_assignments')
        .insert({
          'school_id': schoolId,
          'teacher_id': teacherId,
          'subject_id': subjectId,
          'class_id': classId,
          'section_id': sectionId,
          'academic_year': academicYear,
          'term': term?.dbValue,
          'is_primary': isPrimary ?? true,
          'workload_hours': workloadHours,
        })
        .select()
        .single();

    return TeacherAssignment.fromMap(response);
  }

  Future<List<TeacherAssignment>> fetchTeacherAssignments({
    required String schoolId,
    String? teacherId,
    int? classId,
    int? sectionId,
    String? academicYear,
    Term? term,
  }) async {
    var query = _client
        .from('teacher_assignments')
        .select()
        .eq('school_id', schoolId);

    if (teacherId != null) {
      query = query.eq('teacher_id', teacherId);
    }
    if (classId != null) {
      query = query.eq('class_id', classId);
    }
    if (sectionId != null) {
      query = query.eq('section_id', sectionId);
    }
    if (academicYear != null) {
      query = query.eq('academic_year', academicYear);
    }
    if (term != null) {
      query = query.eq('term', term.dbValue);
    }

    final response = await query.order('academic_year', ascending: false);
    return (response as List)
        .map((row) => TeacherAssignment.fromMap(row as Map<String, dynamic>))
        .toList();
  }

  // ============================================================
  // CONFLICT DETECTION
  // ============================================================

  Future<List<Map<String, dynamic>>> detectConflicts({
    required String schoolId,
    String? timetableId,
  }) async {
    final response = await _client.rpc(
      'detect_schedule_conflicts',
      params: {
        'p_school_id': schoolId,
        if (timetableId != null) 'p_timetable_id': timetableId,
      },
    );

    return (response as List).cast<Map<String, dynamic>>();
  }
}
