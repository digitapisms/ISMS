import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../school_registration/application/school_providers.dart';
import '../data/academic_structure_repository.dart';
import '../domain/academic_structure.dart';
import '../domain/institution_academic_factory.dart';

/// Repository provider for academic structure operations
final academicStructureRepositoryProvider = Provider<AcademicStructureRepository>((ref) {
  final repo = AcademicStructureRepository();
  final school = ref.watch(currentSchoolProvider);
  if (school != null) {
    repo.setSchoolId(school.id);
  }
  return repo;
});

/// Provider for current academic year configuration
final currentAcademicYearProvider = FutureProvider<AcademicYearConfig?>((ref) async {
  final school = ref.watch(currentSchoolProvider);
  if (school == null) return null;
  
  final repo = ref.read(academicStructureRepositoryProvider);
  return repo.getCurrentAcademicYear();
});

/// Provider for all academic year configurations
final academicYearConfigsProvider = FutureProvider<List<AcademicYearConfig>>((ref) async {
  final school = ref.watch(currentSchoolProvider);
  if (school == null) return [];
  
  final repo = ref.read(academicStructureRepositoryProvider);
  return repo.fetchAcademicYearConfigs();
});

/// Provider for current academic periods
final currentAcademicPeriodsProvider = FutureProvider<List<AcademicPeriod>>((ref) async {
  final school = ref.watch(currentSchoolProvider);
  if (school == null) return [];
  
  final repo = ref.read(academicStructureRepositoryProvider);
  return repo.getCurrentAcademicPeriods();
});

/// Provider for institution-specific academic configuration
final institutionAcademicConfigProvider = FutureProvider<InstitutionAcademicConfig>((ref) async {
  final school = ref.watch(currentSchoolProvider);
  if (school == null) {
    return InstitutionAcademicFactory.getDefaultConfig('school');
  }
  
  // TODO: Fetch from institution_config table once implemented
  // For now, return default config based on school type
  final institutionType = school.schoolType?.toLowerCase() ?? 'school';
  return InstitutionAcademicFactory.getDefaultConfig(institutionType);
});

/// Provider family for academic periods of a specific academic year
final academicPeriodsProvider = FutureProvider.family<List<AcademicPeriod>, String>((ref, academicYearId) async {
  final school = ref.watch(currentSchoolProvider);
  if (school == null) return [];
  
  final repo = ref.read(academicStructureRepositoryProvider);
  return repo.fetchAcademicPeriods(academicYearId);
});

/// Provider for supported academic structure types
final supportedAcademicStructuresProvider = FutureProvider<List<AcademicStructureType>>((ref) async {
  final config = await ref.watch(institutionAcademicConfigProvider.future);
  return config.supportedStructures;
});

/// Provider for default academic structure type
final defaultAcademicStructureProvider = FutureProvider<AcademicStructureType>((ref) async {
  final config = await ref.watch(institutionAcademicConfigProvider.future);
  return config.defaultAcademicStructure;
});

/// Notifier for managing academic year configurations
class AcademicYearConfigNotifier extends StateNotifier<AsyncValue<List<AcademicYearConfig>>> {
  AcademicYearConfigNotifier(this.ref) : super(const AsyncValue.loading()) {
    loadAcademicYearConfigs();
  }

  final Ref ref;

  Future<void> loadAcademicYearConfigs() async {
    state = const AsyncValue.loading();
    try {
      final repo = ref.read(academicStructureRepositoryProvider);
      final configs = await repo.fetchAcademicYearConfigs();
      state = AsyncValue.data(configs);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> createAcademicYearConfig(AcademicYearConfig config) async {
    try {
      final repo = ref.read(academicStructureRepositoryProvider);
      await repo.createAcademicYearConfig(config);
      await loadAcademicYearConfigs(); // Reload the list
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> updateAcademicYearConfig(AcademicYearConfig config) async {
    try {
      final repo = ref.read(academicStructureRepositoryProvider);
      await repo.updateAcademicYearConfig(config);
      await loadAcademicYearConfigs(); // Reload the list
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> deleteAcademicYearConfig(String configId) async {
    try {
      final repo = ref.read(academicStructureRepositoryProvider);
      await repo.deleteAcademicYearConfig(configId);
      await loadAcademicYearConfigs(); // Reload the list
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> setCurrentAcademicYear(String academicYearId) async {
    try {
      final repo = ref.read(academicStructureRepositoryProvider);
      await repo.setCurrentAcademicYear(academicYearId);
      await loadAcademicYearConfigs(); // Reload the list
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}

/// Provider for academic year config notifier
final academicYearConfigNotifierProvider = 
    StateNotifierProvider<AcademicYearConfigNotifier, AsyncValue<List<AcademicYearConfig>>>(
  (ref) => AcademicYearConfigNotifier(ref),
);

/// Notifier for managing academic periods
class AcademicPeriodNotifier extends StateNotifier<AsyncValue<List<AcademicPeriod>>> {
  AcademicPeriodNotifier(this.ref, this.academicYearId) : super(const AsyncValue.loading()) {
    loadAcademicPeriods();
  }

  final Ref ref;
  final String academicYearId;

  Future<void> loadAcademicPeriods() async {
    state = const AsyncValue.loading();
    try {
      final repo = ref.read(academicStructureRepositoryProvider);
      final periods = await repo.fetchAcademicPeriods(academicYearId);
      state = AsyncValue.data(periods);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> createAcademicPeriod(AcademicPeriod period) async {
    try {
      final repo = ref.read(academicStructureRepositoryProvider);
      await repo.createAcademicPeriod(period);
      await loadAcademicPeriods(); // Reload the list
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> updateAcademicPeriod(AcademicPeriod period) async {
    try {
      final repo = ref.read(academicStructureRepositoryProvider);
      await repo.updateAcademicPeriod(period);
      await loadAcademicPeriods(); // Reload the list
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> deleteAcademicPeriod(String periodId) async {
    try {
      final repo = ref.read(academicStructureRepositoryProvider);
      await repo.deleteAcademicPeriod(periodId);
      await loadAcademicPeriods(); // Reload the list
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}

/// Provider family for academic period notifier
final academicPeriodNotifierProvider = 
    StateNotifierProvider.family<AcademicPeriodNotifier, AsyncValue<List<AcademicPeriod>>, String>(
  (ref, academicYearId) => AcademicPeriodNotifier(ref, academicYearId),
);