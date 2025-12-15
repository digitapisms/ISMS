import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/network/supabase_client.dart';
import '../domain/academic_structure.dart';

/// Repository for managing academic structure data
class AcademicStructureRepository {
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

  /// Fetch academic year configurations for the current institution
  Future<List<AcademicYearConfig>> fetchAcademicYearConfigs({
    bool? isCurrent,
    String? academicStructureType,
  }) async {
    final schoolId = _requireSchoolId();

    var query = _client
        .from('academic_year_configs')
        .select()
        .eq('school_id', schoolId);

    if (isCurrent != null) {
      query = query.eq('is_current', isCurrent);
    }

    if (academicStructureType != null) {
      query = query.eq('academic_structure_type', academicStructureType);
    }

    final response = await query.order('start_date', ascending: false);

    return (response as List)
        .map((row) => AcademicYearConfig.fromMap(row as Map<String, dynamic>))
        .toList();
  }

  /// Create a new academic year configuration
  Future<AcademicYearConfig> createAcademicYearConfig(
    AcademicYearConfig config,
  ) async {
    final schoolId = _requireSchoolId();

    final response = await _client
        .from('academic_year_configs')
        .insert({
          'school_id': schoolId,
          'name': config.name,
          'start_date': config.startDate.toIso8601String(),
          'end_date': config.endDate.toIso8601String(),
          'academic_structure_type': config.academicStructureType.dbValue,
          'description': config.description,
          'is_current': config.isCurrent,
          'periods': config.periods.map((p) => p.toMap()).toList(),
          'holidays': config.holidays.map((h) => h.toIso8601String()).toList(),
          'metadata': config.metadata,
        })
        .select()
        .single();

    return AcademicYearConfig.fromMap(response);
  }

  /// Update an existing academic year configuration
  Future<AcademicYearConfig> updateAcademicYearConfig(
    AcademicYearConfig config,
  ) async {
    final schoolId = _requireSchoolId();

    final response = await _client
        .from('academic_year_configs')
        .update({
          'name': config.name,
          'start_date': config.startDate.toIso8601String(),
          'end_date': config.endDate.toIso8601String(),
          'academic_structure_type': config.academicStructureType.dbValue,
          'description': config.description,
          'is_current': config.isCurrent,
          'periods': config.periods.map((p) => p.toMap()).toList(),
          'holidays': config.holidays.map((h) => h.toIso8601String()).toList(),
          'metadata': config.metadata,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', config.id)
        .eq('school_id', schoolId)
        .select()
        .single();

    return AcademicYearConfig.fromMap(response);
  }

  /// Delete an academic year configuration
  Future<void> deleteAcademicYearConfig(String configId) async {
    final schoolId = _requireSchoolId();

    await _client
        .from('academic_year_configs')
        .delete()
        .eq('id', configId)
        .eq('school_id', schoolId);
  }

  /// Fetch academic periods for a specific academic year
  Future<List<AcademicPeriod>> fetchAcademicPeriods(
    String academicYearId,
  ) async {
    final schoolId = _requireSchoolId();

    final response = await _client
        .from('academic_periods')
        .select()
        .eq('academic_year_id', academicYearId)
        .eq('school_id', schoolId)
        .order('order', ascending: true);

    return (response as List)
        .map((row) => AcademicPeriod.fromMap(row as Map<String, dynamic>))
        .toList();
  }

  /// Create a new academic period
  Future<AcademicPeriod> createAcademicPeriod(AcademicPeriod period) async {
    final schoolId = _requireSchoolId();

    final response = await _client
        .from('academic_periods')
        .insert({
          'school_id': schoolId,
          'academic_year_id': period.id,
          'name': period.name,
          'code': period.code,
          'start_date': period.startDate.toIso8601String(),
          'end_date': period.endDate.toIso8601String(),
          'academic_structure_type': period.academicStructureType.dbValue,
          'description': period.description,
          'is_active': period.isActive,
          'order': period.order,
          'metadata': period.metadata,
        })
        .select()
        .single();

    return AcademicPeriod.fromMap(response);
  }

  /// Update an existing academic period
  Future<AcademicPeriod> updateAcademicPeriod(AcademicPeriod period) async {
    final schoolId = _requireSchoolId();

    final response = await _client
        .from('academic_periods')
        .update({
          'name': period.name,
          'code': period.code,
          'start_date': period.startDate.toIso8601String(),
          'end_date': period.endDate.toIso8601String(),
          'academic_structure_type': period.academicStructureType.dbValue,
          'description': period.description,
          'is_active': period.isActive,
          'order': period.order,
          'metadata': period.metadata,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', period.id)
        .eq('school_id', schoolId)
        .select()
        .single();

    return AcademicPeriod.fromMap(response);
  }

  /// Delete an academic period
  Future<void> deleteAcademicPeriod(String periodId) async {
    final schoolId = _requireSchoolId();

    await _client
        .from('academic_periods')
        .delete()
        .eq('id', periodId)
        .eq('school_id', schoolId);
  }

  /// Get the current academic year configuration
  Future<AcademicYearConfig?> getCurrentAcademicYear() async {
    final schoolId = _requireSchoolId();

    final response = await _client
        .from('academic_year_configs')
        .select()
        .eq('school_id', schoolId)
        .eq('is_current', true)
        .maybeSingle();

    if (response == null) return null;

    return AcademicYearConfig.fromMap(response);
  }

  Future<InstitutionAcademicConfig?> getInstitutionAcademicConfig(
    String institutionTypeId,
  ) async {
    // TODO: Implement Supabase fetch once the table is available.
    // For now, return null so loader falls back to defaults.
    return null;
  }

  /// Set an academic year as current
  Future<void> setCurrentAcademicYear(String academicYearId) async {
    final schoolId = _requireSchoolId();

    // First, set all academic years as not current
    await _client
        .from('academic_year_configs')
        .update({'is_current': false})
        .eq('school_id', schoolId);

    // Then set the specified academic year as current
    await _client
        .from('academic_year_configs')
        .update({'is_current': true})
        .eq('id', academicYearId)
        .eq('school_id', schoolId);
  }

  /// Get academic periods for the current academic year
  Future<List<AcademicPeriod>> getCurrentAcademicPeriods() async {
    final currentYear = await getCurrentAcademicYear();
    if (currentYear == null) return [];

    return fetchAcademicPeriods(currentYear.id);
  }
}
