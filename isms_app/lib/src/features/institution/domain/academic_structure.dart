import 'package:equatable/equatable.dart';

/// Academic structure types supported by different institutions
enum AcademicStructureType {
  semester,
  trimester,
  quarter,
  term,
  continuous,
  hifz,
  custom,
}

extension AcademicStructureTypeX on AcademicStructureType {
  String get dbValue {
    switch (this) {
      case AcademicStructureType.semester:
        return 'semester';
      case AcademicStructureType.trimester:
        return 'trimester';
      case AcademicStructureType.quarter:
        return 'quarter';
      case AcademicStructureType.term:
        return 'term';
      case AcademicStructureType.continuous:
        return 'continuous';
      case AcademicStructureType.hifz:
        return 'hifz';
      case AcademicStructureType.custom:
        return 'custom';
    }
  }

  String get displayName {
    switch (this) {
      case AcademicStructureType.semester:
        return 'Semester System';
      case AcademicStructureType.trimester:
        return 'Trimester System';
      case AcademicStructureType.quarter:
        return 'Quarter System';
      case AcademicStructureType.term:
        return 'Term System';
      case AcademicStructureType.continuous:
        return 'Continuous Learning';
      case AcademicStructureType.hifz:
        return 'Hifz Program';
      case AcademicStructureType.custom:
        return 'Custom Structure';
    }
  }
}

AcademicStructureType academicStructureTypeFromDb(String value) {
  switch (value) {
    case 'semester':
      return AcademicStructureType.semester;
    case 'trimester':
      return AcademicStructureType.trimester;
    case 'quarter':
      return AcademicStructureType.quarter;
    case 'term':
      return AcademicStructureType.term;
    case 'continuous':
      return AcademicStructureType.continuous;
    case 'hifz':
      return AcademicStructureType.hifz;
    case 'custom':
      return AcademicStructureType.custom;
    default:
      return AcademicStructureType.semester;
  }
}

/// Academic period within a structure (semester, term, quarter, etc.)
class AcademicPeriod extends Equatable {
  const AcademicPeriod({
    required this.id,
    required this.name,
    required this.code,
    required this.startDate,
    required this.endDate,
    required this.academicStructureType,
    this.description,
    this.isActive = true,
    this.order = 0,
    this.metadata = const {},
  });

  final String id;
  final String name;
  final String code;
  final DateTime startDate;
  final DateTime endDate;
  final AcademicStructureType academicStructureType;
  final String? description;
  final bool isActive;
  final int order;
  final Map<String, dynamic> metadata;

  factory AcademicPeriod.fromMap(Map<String, dynamic> map) {
    return AcademicPeriod(
      id: map['id'] as String,
      name: map['name'] as String,
      code: map['code'] as String,
      startDate: DateTime.parse(map['start_date'] as String),
      endDate: DateTime.parse(map['end_date'] as String),
      academicStructureType: academicStructureTypeFromDb(
        map['academic_structure_type'] as String,
      ),
      description: map['description'] as String?,
      isActive: (map['is_active'] as bool?) ?? true,
      order: (map['order'] as int?) ?? 0,
      metadata: map['metadata'] != null
          ? Map<String, dynamic>.from(map['metadata'] as Map)
          : const {},
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'code': code,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'academic_structure_type': academicStructureType.dbValue,
      'description': description,
      'is_active': isActive,
      'order': order,
      'metadata': metadata,
    };
  }

  @override
  List<Object?> get props => [
    id,
    name,
    code,
    startDate,
    endDate,
    academicStructureType,
    description,
    isActive,
    order,
    metadata,
  ];
}

/// Academic year configuration for an institution
class AcademicYearConfig extends Equatable {
  const AcademicYearConfig({
    required this.id,
    required this.institutionTypeId,
    required this.name,
    required this.startDate,
    required this.endDate,
    required this.academicStructureType,
    this.description,
    this.isCurrent = false,
    this.periods = const [],
    this.holidays = const [],
    this.metadata = const {},
  });

  final String id;
  final String institutionTypeId;
  final String name;
  final DateTime startDate;
  final DateTime endDate;
  final AcademicStructureType academicStructureType;
  final String? description;
  final bool isCurrent;
  final List<AcademicPeriod> periods;
  final List<DateTime> holidays;
  final Map<String, dynamic> metadata;

  factory AcademicYearConfig.fromMap(Map<String, dynamic> map) {
    return AcademicYearConfig(
      id: map['id'] as String,
      institutionTypeId: map['institution_type_id'] as String,
      name: map['name'] as String,
      startDate: DateTime.parse(map['start_date'] as String),
      endDate: DateTime.parse(map['end_date'] as String),
      academicStructureType: academicStructureTypeFromDb(
        map['academic_structure_type'] as String,
      ),
      description: map['description'] as String?,
      isCurrent: (map['is_current'] as bool?) ?? false,
      periods:
          (map['periods'] as List<dynamic>?)
              ?.map((p) => AcademicPeriod.fromMap(p as Map<String, dynamic>))
              .toList() ??
          [],
      holidays:
          (map['holidays'] as List<dynamic>?)
              ?.map((h) => DateTime.parse(h as String))
              .toList() ??
          [],
      metadata: map['metadata'] != null
          ? Map<String, dynamic>.from(map['metadata'] as Map)
          : const {},
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'institution_type_id': institutionTypeId,
      'name': name,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'academic_structure_type': academicStructureType.dbValue,
      'description': description,
      'is_current': isCurrent,
      'periods': periods.map((p) => p.toMap()).toList(),
      'holidays': holidays.map((h) => h.toIso8601String()).toList(),
      'metadata': metadata,
    };
  }

  @override
  List<Object?> get props => [
    id,
    institutionTypeId,
    name,
    startDate,
    endDate,
    academicStructureType,
    description,
    isCurrent,
    periods,
    holidays,
    metadata,
  ];
}

/// Institution-specific academic configuration
class InstitutionAcademicConfig extends Equatable {
  const InstitutionAcademicConfig({
    required this.institutionTypeId,
    required this.defaultAcademicStructure,
    this.supportedStructures = const [],
    this.minPeriodDuration = 30, // days
    this.maxPeriodDuration = 180, // days
    this.defaultPeriodCount = 2,
    this.defaultPeriodDuration = 40, // minutes
    this.maxPeriodsPerDay = 8,
    this.requiresExamSystem = true,
    this.supportsContinuousAssessment = false,
    this.supportsHifzProgram = false,
    this.supportsOnlineClasses = false,
    this.defaultHolidays = const [],
    this.metadata = const {},
  });

  final String institutionTypeId;
  final AcademicStructureType defaultAcademicStructure;
  final List<AcademicStructureType> supportedStructures;
  final int minPeriodDuration;
  final int maxPeriodDuration;
  final int defaultPeriodCount;
  final int defaultPeriodDuration;
  final int maxPeriodsPerDay;
  final bool requiresExamSystem;
  final bool supportsContinuousAssessment;
  final bool supportsHifzProgram;
  final bool supportsOnlineClasses;
  final List<DateTime> defaultHolidays;
  final Map<String, dynamic> metadata;

  factory InstitutionAcademicConfig.fromMap(Map<String, dynamic> map) {
    return InstitutionAcademicConfig(
      institutionTypeId: map['institution_type_id'] as String,
      defaultAcademicStructure: academicStructureTypeFromDb(
        map['default_academic_structure'] as String,
      ),
      supportedStructures:
          (map['supported_structures'] as List<dynamic>?)
              ?.map((s) => academicStructureTypeFromDb(s as String))
              .toList() ??
          [],
      minPeriodDuration: (map['min_period_duration'] as int?) ?? 30,
      maxPeriodDuration: (map['max_period_duration'] as int?) ?? 180,
      defaultPeriodCount: (map['default_period_count'] as int?) ?? 2,
      defaultPeriodDuration: (map['default_period_duration'] as int?) ?? 40,
      maxPeriodsPerDay: (map['max_periods_per_day'] as int?) ?? 8,
      requiresExamSystem: (map['requires_exam_system'] as bool?) ?? true,
      supportsContinuousAssessment:
          (map['supports_continuous_assessment'] as bool?) ?? false,
      supportsHifzProgram: (map['supports_hifz_program'] as bool?) ?? false,
      supportsOnlineClasses: (map['supports_online_classes'] as bool?) ?? false,
      defaultHolidays:
          (map['default_holidays'] as List<dynamic>?)
              ?.map((h) => DateTime.parse(h as String))
              .toList() ??
          [],
      metadata: map['metadata'] != null
          ? Map<String, dynamic>.from(map['metadata'] as Map)
          : const {},
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'institution_type_id': institutionTypeId,
      'default_academic_structure': defaultAcademicStructure.dbValue,
      'supported_structures': supportedStructures
          .map((s) => s.dbValue)
          .toList(),
      'min_period_duration': minPeriodDuration,
      'max_period_duration': maxPeriodDuration,
      'default_period_count': defaultPeriodCount,
      'default_period_duration': defaultPeriodDuration,
      'max_periods_per_day': maxPeriodsPerDay,
      'requires_exam_system': requiresExamSystem,
      'supports_continuous_assessment': supportsContinuousAssessment,
      'supports_hifz_program': supportsHifzProgram,
      'supports_online_classes': supportsOnlineClasses,
      'default_holidays': defaultHolidays
          .map((h) => h.toIso8601String())
          .toList(),
      'metadata': metadata,
    };
  }

  @override
  List<Object?> get props => [
    institutionTypeId,
    defaultAcademicStructure,
    supportedStructures,
    minPeriodDuration,
    maxPeriodDuration,
    defaultPeriodCount,
    defaultPeriodDuration,
    maxPeriodsPerDay,
    requiresExamSystem,
    supportsContinuousAssessment,
    supportsHifzProgram,
    supportsOnlineClasses,
    defaultHolidays,
    metadata,
  ];
}
