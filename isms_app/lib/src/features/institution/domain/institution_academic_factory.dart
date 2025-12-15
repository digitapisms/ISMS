import 'package:isms_app/src/features/institution/domain/academic_structure.dart';

/// Factory class that provides default academic configurations for each institution type
class InstitutionAcademicFactory {
  /// Get default academic configuration for a specific institution type
  static InstitutionAcademicConfig getDefaultConfig(String institutionTypeId) {
    switch (institutionTypeId) {
      case 'school':
        return _createSchoolConfig();
      case 'madarsa':
        return _createMadarsaConfig();
      case 'coaching_center':
        return _createCoachingCenterConfig();
      case 'tuition_center':
        return _createTuitionCenterConfig();
      case 'online_institute':
        return _createOnlineInstituteConfig();
      default:
        return _createSchoolConfig(); // Default to school config
    }
  }

  /// Academic configuration for traditional schools
  static InstitutionAcademicConfig _createSchoolConfig() {
    return InstitutionAcademicConfig(
      institutionTypeId: 'school',
      defaultAcademicStructure: AcademicStructureType.term,
      supportedStructures: [
        AcademicStructureType.term,
        AcademicStructureType.semester,
        AcademicStructureType.trimester,
      ],
      minPeriodDuration: 45, // 6-7 weeks per term
      maxPeriodDuration: 90, // 12-13 weeks per term
      defaultPeriodCount: 3, // 3 terms per year
      requiresExamSystem: true,
      supportsContinuousAssessment: true,
      supportsHifzProgram: false,
      supportsOnlineClasses: true,
      defaultHolidays: [
        DateTime(DateTime.now().year, 1, 1), // New Year
        DateTime(DateTime.now().year, 3, 23), // Pakistan Day
        DateTime(DateTime.now().year, 5, 1), // Labour Day
        DateTime(DateTime.now().year, 8, 14), // Independence Day
        DateTime(DateTime.now().year, 9, 6), // Defence Day
        DateTime(DateTime.now().year, 12, 25), // Quaid-e-Azam Day
      ],
      metadata: {
        'grading_system': 'percentage',
        'attendance_required': true,
        'minimum_attendance_percentage': 75.0,
        'promotion_criteria': 'exam_based',
        'supports_extracurricular': true,
        'supports_sports': true,
        'supports_laboratories': true,
        'supports_library': true,
      },
    );
  }

  /// Academic configuration for Madarsas (Islamic educational institutions)
  static InstitutionAcademicConfig _createMadarsaConfig() {
    return InstitutionAcademicConfig(
      institutionTypeId: 'madarsa',
      defaultAcademicStructure: AcademicStructureType.continuous,
      supportedStructures: [
        AcademicStructureType.continuous,
        AcademicStructureType.hifz,
        AcademicStructureType.term,
      ],
      minPeriodDuration: 30, // Flexible duration for religious studies
      maxPeriodDuration: 365, // Year-round continuous learning
      defaultPeriodCount: 1, // Continuous learning
      requiresExamSystem: false,
      supportsContinuousAssessment: true,
      supportsHifzProgram: true,
      supportsOnlineClasses: true,
      defaultHolidays: [
        DateTime(DateTime.now().year, 1, 1), // New Year
        DateTime(DateTime.now().year, 3, 23), // Pakistan Day
        DateTime(DateTime.now().year, 8, 14), // Independence Day
        // Islamic holidays (calculated dynamically)
      ],
      metadata: {
        'grading_system': 'continuous_assessment',
        'attendance_required': true,
        'minimum_attendance_percentage': 80.0,
        'promotion_criteria': 'completion_based',
        'supports_quran_studies': true,
        'supports_islamic_subjects': true,
        'prayer_times_integration': true,
        'religious_events_support': true,
        'hifz_program_support': true,
        'arabic_language_support': true,
      },
    );
  }

  /// Academic configuration for Coaching Centers
  static InstitutionAcademicConfig _createCoachingCenterConfig() {
    return InstitutionAcademicConfig(
      institutionTypeId: 'coaching_center',
      defaultAcademicStructure: AcademicStructureType.quarter,
      supportedStructures: [
        AcademicStructureType.quarter,
        AcademicStructureType.semester,
        AcademicStructureType.continuous,
      ],
      minPeriodDuration: 30, // 4-week intensive courses
      maxPeriodDuration: 90, // 12-week comprehensive courses
      defaultPeriodCount: 4, // 4 quarters per year
      requiresExamSystem: true,
      supportsContinuousAssessment: true,
      supportsHifzProgram: false,
      supportsOnlineClasses: true,
      defaultHolidays: [
        DateTime(DateTime.now().year, 1, 1), // New Year
        DateTime(DateTime.now().year, 3, 23), // Pakistan Day
        DateTime(DateTime.now().year, 8, 14), // Independence Day
      ],
      metadata: {
        'grading_system': 'percentage',
        'attendance_required': false,
        'minimum_attendance_percentage': 0.0,
        'promotion_criteria': 'exam_based',
        'intensive_courses': true,
        'crash_courses_support': true,
        'test_preparation_focus': true,
        'competitive_exam_support': true,
        'flexible_timing': true,
        'batch_based_learning': true,
      },
    );
  }

  /// Academic configuration for Tuition Centers
  static InstitutionAcademicConfig _createTuitionCenterConfig() {
    return InstitutionAcademicConfig(
      institutionTypeId: 'tuition_center',
      defaultAcademicStructure: AcademicStructureType.continuous,
      supportedStructures: [
        AcademicStructureType.continuous,
        AcademicStructureType.term,
        AcademicStructureType.custom,
      ],
      minPeriodDuration: 15, // 2-week remedial courses
      maxPeriodDuration: 60, // 8-week comprehensive support
      defaultPeriodCount: 1, // Continuous support
      requiresExamSystem: false,
      supportsContinuousAssessment: true,
      supportsHifzProgram: false,
      supportsOnlineClasses: true,
      defaultHolidays: [
        DateTime(DateTime.now().year, 1, 1), // New Year
        DateTime(DateTime.now().year, 8, 14), // Independence Day
      ],
      metadata: {
        'grading_system': 'continuous_feedback',
        'attendance_required': false,
        'minimum_attendance_percentage': 0.0,
        'promotion_criteria': 'improvement_based',
        'remedial_education_focus': true,
        'subject_specific_support': true,
        'individual_attention': true,
        'small_group_learning': true,
        'homework_support': true,
        'exam_preparation': true,
        'flexible_scheduling': true,
      },
    );
  }

  /// Academic configuration for Online-Only Institutes
  static InstitutionAcademicConfig _createOnlineInstituteConfig() {
    return InstitutionAcademicConfig(
      institutionTypeId: 'online_institute',
      defaultAcademicStructure: AcademicStructureType.continuous,
      supportedStructures: [
        AcademicStructureType.continuous,
        AcademicStructureType.quarter,
        AcademicStructureType.semester,
        AcademicStructureType.custom,
      ],
      minPeriodDuration: 7, // 1-week micro-courses
      maxPeriodDuration: 365, // Year-round access
      defaultPeriodCount: 1, // Continuous access
      requiresExamSystem: false,
      supportsContinuousAssessment: true,
      supportsHifzProgram: false,
      supportsOnlineClasses: true,
      defaultHolidays: [], // 24/7 availability
      metadata: {
        'grading_system': 'automated_assessment',
        'attendance_required': false,
        'minimum_attendance_percentage': 0.0,
        'promotion_criteria': 'completion_based',
        'self_paced_learning': true,
        'on_demand_courses': true,
        'microlearning_support': true,
        'certification_focus': true,
        'global_access': true,
        'multilingual_support': true,
        'mobile_learning': true,
        'gamification': true,
        'social_learning': true,
      },
    );
  }

  /// Get default academic year configuration for a specific institution type
  static AcademicYearConfig getDefaultAcademicYearConfig(
      String institutionTypeId, int year) {
    final config = getDefaultConfig(institutionTypeId);
    final startDate = DateTime(year, 4, 1); // April 1st start
    final endDate = DateTime(year + 1, 3, 31); // March 31st end

    return AcademicYearConfig(
      id: '${institutionTypeId}_${year}_${year + 1}',
      institutionTypeId: institutionTypeId,
      name: 'Academic Year $year-${year + 1}',
      startDate: startDate,
      endDate: endDate,
      academicStructureType: config.defaultAcademicStructure,
      description: 'Default academic year for ${institutionTypeId.replaceAll('_', ' ')}',
      isCurrent: year == DateTime.now().year,
      periods: _createDefaultPeriods(config, startDate, endDate),
      holidays: config.defaultHolidays,
      metadata: config.metadata,
    );
  }

  /// Create default academic periods based on configuration
  static List<AcademicPeriod> _createDefaultPeriods(
      InstitutionAcademicConfig config, DateTime startDate, DateTime endDate) {
    final periods = <AcademicPeriod>[];
    final totalDays = endDate.difference(startDate).inDays;
    final periodDuration = totalDays ~/ config.defaultPeriodCount;

    for (var i = 0; i < config.defaultPeriodCount; i++) {
      final periodStart = startDate.add(Duration(days: i * periodDuration));
      final periodEnd = i == config.defaultPeriodCount - 1
          ? endDate
          : periodStart.add(Duration(days: periodDuration - 1));

      periods.add(AcademicPeriod(
        id: '${config.institutionTypeId}_period_${i + 1}',
        name: _getPeriodName(config.defaultAcademicStructure, i + 1),
        code: 'P${i + 1}',
        startDate: periodStart,
        endDate: periodEnd,
        academicStructureType: config.defaultAcademicStructure,
        description: _getPeriodDescription(config.defaultAcademicStructure, i + 1),
        order: i + 1,
        metadata: {},
      ));
    }

    return periods;
  }

  /// Get appropriate period name based on academic structure type
  static String _getPeriodName(AcademicStructureType type, int index) {
    switch (type) {
      case AcademicStructureType.semester:
        return index == 1 ? 'First Semester' : 'Second Semester';
      case AcademicStructureType.trimester:
        return 'Trimester $index';
      case AcademicStructureType.quarter:
        return 'Quarter $index';
      case AcademicStructureType.term:
        return 'Term $index';
      case AcademicStructureType.continuous:
        return 'Continuous Learning Period';
      case AcademicStructureType.hifz:
        return 'Hifz Program Phase $index';
      case AcademicStructureType.custom:
        return 'Custom Period $index';
    }
  }

  /// Get appropriate period description based on academic structure type
  static String _getPeriodDescription(AcademicStructureType type, int index) {
    switch (type) {
      case AcademicStructureType.semester:
        return index == 1
            ? 'First semester of the academic year'
            : 'Second semester of the academic year';
      case AcademicStructureType.trimester:
        return 'Trimester $index of the academic year';
      case AcademicStructureType.quarter:
        return 'Quarter $index of the academic year';
      case AcademicStructureType.term:
        return 'Term $index of the academic year';
      case AcademicStructureType.continuous:
        return 'Continuous learning period for ongoing education';
      case AcademicStructureType.hifz:
        return 'Phase $index of the Quran memorization program';
      case AcademicStructureType.custom:
        return 'Custom defined academic period $index';
    }
  }
}
