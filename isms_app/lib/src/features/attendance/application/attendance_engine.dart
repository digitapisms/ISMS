import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../institution/application/institution_config_loader.dart';
import '../../institution/domain/academic_structure.dart';
import '../domain/attendance_record.dart';
import '../domain/attendance_status.dart';

part 'attendance_engine.g.dart';

/// Service for managing institution-specific attendance modes and rules
class AttendanceEngine {
  final InstitutionConfigLoader _configLoader;

  AttendanceEngine(this._configLoader);

  /// Get supported attendance modes for a specific institution type
  Future<List<AttendanceMode>> getSupportedAttendanceModes(String institutionTypeId) async {
    final academicConfig = await _configLoader.loadAcademicConfig(institutionTypeId);
    return academicConfig.supportedAttendanceModes;
  }

  /// Validate attendance record against institution-specific rules
  Future<List<String>> validateAttendanceRecord({
    required String institutionTypeId,
    required AttendanceRecord record,
    required List<AttendanceRecord> existingRecords, // For same student/date
  }) async {
    final errors = <String>[];
    
    // Load institution-specific attendance configuration
    final academicConfig = await _configLoader.loadAcademicConfig(institutionTypeId);
    
    // Check if attendance mode is supported for this institution
    final supportedModes = academicConfig.supportedAttendanceModes;
    
    // For period-based attendance, validate period number
    if (record.periodNumber != null) {
      final periodBasedMode = supportedModes.firstWhere(
        (mode) => mode.isPeriodBased,
        orElse: () => AttendanceMode.daily(),
      );
      
      if (!periodBasedMode.isPeriodBased) {
        errors.add('Period-based attendance is not supported for ${academicConfig.institutionType}');
      } else if (record.periodNumber! < 1 || record.periodNumber! > periodBasedMode.maxPeriods) {
        errors.add('Period number ${record.periodNumber} is invalid. Valid range: 1-${periodBasedMode.maxPeriods}');
      }
    }
    
    // Check for duplicate period attendance (if period-based)
    if (record.periodNumber != null) {
      final duplicate = existingRecords.firstWhere(
        (r) => r.periodNumber == record.periodNumber,
        orElse: () => AttendanceRecord(
          id: '',
          schoolId: '',
          studentId: '',
          attendanceDate: DateTime.now(),
          status: AttendanceStatus.present,
        ),
      );
      
      if (duplicate.id.isNotEmpty) {
        errors.add('Attendance already marked for period ${record.periodNumber}');
      }
    }
    
    // Check institution-specific status validation
    if (!_isStatusSupportedForInstitution(record.status, academicConfig)) {
      errors.add('Attendance status "${record.status.displayName}" is not supported for ${academicConfig.institutionType}');
    }
    
    return errors;
  }

  /// Get default attendance status based on institution type and time
  Future<AttendanceStatus> getDefaultAttendanceStatus({
    required String institutionTypeId,
    required DateTime currentTime,
    DateTime? expectedArrivalTime,
  }) async {
    final academicConfig = await _configLoader.loadAcademicConfig(institutionTypeId);
    
    // For coaching centers and tuition centers, late arrival is more common
    if (academicConfig.institutionType == InstitutionType.coachingCenter ||
        academicConfig.institutionType == InstitutionType.tuitionCenter) {
      
      if (expectedArrivalTime != null && currentTime.isAfter(expectedArrivalTime)) {
        return AttendanceStatus.late;
      }
      return AttendanceStatus.present;
    }
    
    // For madrasas, stricter attendance with excused absences
    if (academicConfig.institutionType == InstitutionType.madrasa) {
      return AttendanceStatus.present; // Default to present, excused requires manual entry
    }
    
    // For regular schools, use standard present status
    return AttendanceStatus.present;
  }

  /// Check if institution requires period-based attendance
  Future<bool> requiresPeriodBasedAttendance(String institutionTypeId) async {
    final academicConfig = await _configLoader.loadAcademicConfig(institutionTypeId);
    
    return academicConfig.supportedAttendanceModes.any((mode) => mode.isPeriodBased);
  }

  /// Get attendance summary rules for reporting
  Future<Map<String, dynamic>> getAttendanceSummaryRules(String institutionTypeId) async {
    final academicConfig = await _configLoader.loadAcademicConfig(institutionTypeId);
    
    return {
      'calculationMethod': academicConfig.attendanceCalculationMethod,
      'minAttendancePercentage': academicConfig.minAttendancePercentage,
      'gracePeriodDays': academicConfig.attendanceGracePeriodDays,
      'supportedModes': academicConfig.supportedAttendanceModes,
      'institutionType': academicConfig.institutionType,
    };
  }

  /// Check if a student's attendance meets institution requirements
  Future<bool> meetsAttendanceRequirements({
    required String institutionTypeId,
    required int totalDays,
    required int presentDays,
    required int excusedDays,
  }) async {
    final academicConfig = await _configLoader.loadAcademicConfig(institutionTypeId);
    
    if (totalDays == 0) return false;
    
    final effectiveDays = totalDays - excusedDays;
    if (effectiveDays <= 0) return true; // All days excused
    
    final attendancePercentage = (presentDays / effectiveDays) * 100;
    
    return attendancePercentage >= academicConfig.minAttendancePercentage;
  }

  bool _isStatusSupportedForInstitution(
    AttendanceStatus status,
    InstitutionAcademicConfig config,
  ) {
    // Different institutions support different statuses
    switch (config.institutionType) {
      case InstitutionType.school:
        return true; // Schools support all statuses
      case InstitutionType.madrasa:
        return status != AttendanceStatus.halfDay; // Madrasas don't typically use half-day
      case InstitutionType.coachingCenter:
        return status == AttendanceStatus.present || 
               status == AttendanceStatus.absent ||
               status == AttendanceStatus.late;
      case InstitutionType.tuitionCenter:
        return status == AttendanceStatus.present || 
               status == AttendanceStatus.absent;
    }
  }
}

/// Riverpod provider for the attendance engine
@riverpod
AttendanceEngine attendanceEngine(AttendanceEngineRef ref) {
  final configLoader = ref.watch(institutionConfigLoaderProvider);
  return AttendanceEngine(configLoader);
}