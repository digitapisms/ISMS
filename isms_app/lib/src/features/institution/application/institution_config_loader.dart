import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isms_app/src/features/institution/domain/institution_academic_factory.dart';
import 'package:isms_app/src/features/institution/data/academic_structure_repository.dart';
import 'package:isms_app/src/features/institution/application/academic_structure_providers.dart';
import 'package:isms_app/src/features/institution/domain/academic_structure.dart';
import 'package:isms_app/src/features/school_registration/domain/school.dart';
import 'package:isms_app/src/features/school_registration/application/school_providers.dart';
import 'package:isms_app/src/features/timetable/domain/period.dart';

/// Service for loading and managing institution-specific configurations
class InstitutionConfigLoader {
  final AcademicStructureRepository _repository;

  InstitutionConfigLoader(this._repository);

  /// Loads the academic configuration for a specific institution type
  Future<InstitutionAcademicConfig> loadAcademicConfig(
    String institutionTypeId,
  ) async {
    // First try to load from database (custom config)
    final customConfig = await _repository.getInstitutionAcademicConfig(
      institutionTypeId,
    );

    if (customConfig != null) {
      return customConfig;
    }

    // Fall back to factory defaults
    return InstitutionAcademicFactory.getDefaultConfig(institutionTypeId);
  }

  /// Loads the current academic year configuration for a school
  Future<AcademicYearConfig?> loadCurrentAcademicYearConfig(
    School school,
  ) async {
    final institutionConfig = await loadAcademicConfig(
      school.institutionTypeId ?? 'school',
    );

    // Get current academic year from database
    final currentYear = await _repository.getCurrentAcademicYear();

    if (currentYear != null) {
      return currentYear;
    }

    // Create default academic year based on institution type
    return _createDefaultAcademicYear(school, institutionConfig);
  }

  /// Creates a default academic year configuration based on institution type
  AcademicYearConfig _createDefaultAcademicYear(
    School school,
    InstitutionAcademicConfig institutionConfig,
  ) {
    final now = DateTime.now();
    final year = now.year;

    switch (institutionConfig.defaultAcademicStructure) {
      case AcademicStructureType.semester:
        return AcademicYearConfig(
          id: 'default',
          institutionTypeId: school.institutionTypeId ?? 'school',
          name: '$year-${year + 1}',
          startDate: DateTime(year, 1, 1),
          endDate: DateTime(year, 12, 31),
          academicStructureType: AcademicStructureType.semester,
          isCurrent: true,
          periods: [
            AcademicPeriod(
              id: 'sem1',
              name: 'First Semester',
              code: 'SEM1',
              startDate: DateTime(year, 1, 1),
              endDate: DateTime(year, 6, 30),
              academicStructureType: AcademicStructureType.semester,
              order: 1,
            ),
            AcademicPeriod(
              id: 'sem2',
              name: 'Second Semester',
              code: 'SEM2',
              startDate: DateTime(year, 7, 1),
              endDate: DateTime(year, 12, 31),
              academicStructureType: AcademicStructureType.semester,
              order: 2,
            ),
          ],
        );

      case AcademicStructureType.trimester:
        return AcademicYearConfig(
          id: 'default',
          institutionTypeId: school.institutionTypeId ?? 'school',
          name: '$year-${year + 1}',
          startDate: DateTime(year, 1, 1),
          endDate: DateTime(year, 12, 31),
          academicStructureType: AcademicStructureType.trimester,
          isCurrent: true,
          periods: [
            AcademicPeriod(
              id: 'tri1',
              name: 'First Trimester',
              code: 'TRI1',
              startDate: DateTime(year, 1, 1),
              endDate: DateTime(year, 4, 30),
              academicStructureType: AcademicStructureType.trimester,
              order: 1,
            ),
            AcademicPeriod(
              id: 'tri2',
              name: 'Second Trimester',
              code: 'TRI2',
              startDate: DateTime(year, 5, 1),
              endDate: DateTime(year, 8, 31),
              academicStructureType: AcademicStructureType.trimester,
              order: 2,
            ),
            AcademicPeriod(
              id: 'tri3',
              name: 'Third Trimester',
              code: 'TRI3',
              startDate: DateTime(year, 9, 1),
              endDate: DateTime(year, 12, 31),
              academicStructureType: AcademicStructureType.trimester,
              order: 3,
            ),
          ],
        );

      case AcademicStructureType.quarter:
        return AcademicYearConfig(
          id: 'default',
          institutionTypeId: school.institutionTypeId ?? 'school',
          name: '$year-${year + 1}',
          startDate: DateTime(year, 1, 1),
          endDate: DateTime(year, 12, 31),
          academicStructureType: AcademicStructureType.quarter,
          isCurrent: true,
          periods: [
            AcademicPeriod(
              id: 'q1',
              name: 'First Quarter',
              code: 'Q1',
              startDate: DateTime(year, 1, 1),
              endDate: DateTime(year, 3, 31),
              academicStructureType: AcademicStructureType.quarter,
              order: 1,
            ),
            AcademicPeriod(
              id: 'q2',
              name: 'Second Quarter',
              code: 'Q2',
              startDate: DateTime(year, 4, 1),
              endDate: DateTime(year, 6, 30),
              academicStructureType: AcademicStructureType.quarter,
              order: 2,
            ),
            AcademicPeriod(
              id: 'q3',
              name: 'Third Quarter',
              code: 'Q3',
              startDate: DateTime(year, 7, 1),
              endDate: DateTime(year, 9, 30),
              academicStructureType: AcademicStructureType.quarter,
              order: 3,
            ),
            AcademicPeriod(
              id: 'q4',
              name: 'Fourth Quarter',
              code: 'Q4',
              startDate: DateTime(year, 10, 1),
              endDate: DateTime(year, 12, 31),
              academicStructureType: AcademicStructureType.quarter,
              order: 4,
            ),
          ],
        );

      case AcademicStructureType.term:
        return AcademicYearConfig(
          id: 'default',
          institutionTypeId: school.institutionTypeId ?? 'school',
          name: '$year-${year + 1}',
          startDate: DateTime(year, 1, 1),
          endDate: DateTime(year, 12, 31),
          academicStructureType: AcademicStructureType.term,
          isCurrent: true,
          periods: [
            AcademicPeriod(
              id: 'term1',
              name: 'First Term',
              code: 'TERM1',
              startDate: DateTime(year, 1, 1),
              endDate: DateTime(year, 4, 30),
              academicStructureType: AcademicStructureType.term,
              order: 1,
            ),
            AcademicPeriod(
              id: 'term2',
              name: 'Second Term',
              code: 'TERM2',
              startDate: DateTime(year, 5, 1),
              endDate: DateTime(year, 8, 31),
              academicStructureType: AcademicStructureType.term,
              order: 2,
            ),
            AcademicPeriod(
              id: 'term3',
              name: 'Third Term',
              code: 'TERM3',
              startDate: DateTime(year, 9, 1),
              endDate: DateTime(year, 12, 31),
              academicStructureType: AcademicStructureType.term,
              order: 3,
            ),
          ],
        );

      case AcademicStructureType.continuous:
        return AcademicYearConfig(
          id: 'default',
          institutionTypeId: school.institutionTypeId ?? 'school',
          name: '$year-${year + 1}',
          startDate: DateTime(year, 1, 1),
          endDate: DateTime(year, 12, 31),
          academicStructureType: AcademicStructureType.continuous,
          isCurrent: true,
          periods: [
            AcademicPeriod(
              id: 'continuous',
              name: 'Continuous Learning',
              code: 'CONT',
              startDate: DateTime(year, 1, 1),
              endDate: DateTime(year, 12, 31),
              academicStructureType: AcademicStructureType.continuous,
              order: 1,
            ),
          ],
        );

      case AcademicStructureType.hifz:
        return AcademicYearConfig(
          id: 'default',
          institutionTypeId: school.institutionTypeId ?? 'school',
          name: '$year-${year + 1}',
          startDate: DateTime(year, 1, 1),
          endDate: DateTime(year, 12, 31),
          academicStructureType: AcademicStructureType.hifz,
          isCurrent: true,
          periods: [
            AcademicPeriod(
              id: 'hifz',
              name: 'Hifz Program',
              code: 'HIFZ',
              startDate: DateTime(year, 1, 1),
              endDate: DateTime(year, 12, 31),
              academicStructureType: AcademicStructureType.hifz,
              order: 1,
            ),
          ],
        );

      case AcademicStructureType.custom:
        return AcademicYearConfig(
          id: 'default',
          institutionTypeId: school.institutionTypeId ?? 'school',
          name: '$year-${year + 1}',
          startDate: DateTime(year, 1, 1),
          endDate: DateTime(year, 12, 31),
          academicStructureType: AcademicStructureType.custom,
          isCurrent: true,
          periods: [
            AcademicPeriod(
              id: 'custom',
              name: 'Custom Period',
              code: 'CUST',
              startDate: DateTime(year, 1, 1),
              endDate: DateTime(year, 12, 31),
              academicStructureType: AcademicStructureType.custom,
              order: 1,
            ),
          ],
        );
    }
  }

  /// Gets the supported timetable period types for an institution
  List<PeriodType> getSupportedPeriodTypes(String institutionTypeId) {
    final config = InstitutionAcademicFactory.getDefaultConfig(
      institutionTypeId,
    );

    // Base period types for all institutions
    final baseTypes = [
      PeriodType.regular,
      PeriodType.breakPeriod,
      PeriodType.lunch,
    ];

    // Add institution-specific period types
    if (config.supportsContinuousAssessment || config.supportsHifzProgram) {
      baseTypes.add(PeriodType.assembly);
    }

    return baseTypes;
  }

  /// Gets the default period duration for an institution type
  int getDefaultPeriodDuration(String institutionTypeId) {
    final config = InstitutionAcademicFactory.getDefaultConfig(
      institutionTypeId,
    );
    return config.defaultPeriodDuration;
  }

  /// Gets the maximum number of periods per day for an institution type
  int getMaxPeriodsPerDay(String institutionTypeId) {
    final config = InstitutionAcademicFactory.getDefaultConfig(
      institutionTypeId,
    );
    return config.maxPeriodsPerDay;
  }
}

/// Riverpod provider for the institution config loader
final institutionConfigLoaderProvider = Provider<InstitutionConfigLoader>((
  ref,
) {
  final repository = ref.watch(academicStructureRepositoryProvider);
  return InstitutionConfigLoader(repository);
});

/// Provider for loading current academic year configuration
final currentAcademicYearConfigProvider =
    FutureProvider.autoDispose<AcademicYearConfig?>((ref) async {
      final school = ref.watch(currentSchoolProvider);
      final loader = ref.watch(institutionConfigLoaderProvider);

      if (school == null) return null;

      return loader.loadCurrentAcademicYearConfig(school);
    });

/// Provider for loading institution academic configuration
final institutionAcademicConfigProvider = FutureProvider.autoDispose
    .family<InstitutionAcademicConfig, String>((ref, institutionTypeId) async {
      final loader = ref.watch(institutionConfigLoaderProvider);
      return loader.loadAcademicConfig(institutionTypeId);
    });
