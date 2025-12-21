import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_error.dart';
import '../../../core/errors/error_handler.dart';
import '../../../core/errors/provider_helpers.dart';
import '../../../core/errors/validation.dart';
import '../../../core/tenant/tenant_context.dart';
import '../../authentication/application/auth_providers.dart';
import '../data/class_repository.dart';
import '../domain/class_model.dart';
import '../domain/section_model.dart';

final classRepositoryProvider = Provider<ClassRepository>((ref) {
  final repo = ClassRepository();
  final tenantSchool = ref.read(tenantContextProvider);
  final authUser = ref.read(authStateProvider);
  final schoolId = tenantSchool?.id ?? authUser?.schoolId;
  if (schoolId != null) {
    repo.setSchoolId(schoolId);
  }
  return repo;
});

final classesProvider = FutureProvider<List<ClassModel>>((ref) async {
  try {
    // Get school ID immediately - no waiting
    final tenantSchool = ref.read(tenantContextProvider);
    final authUser = ref.read(authStateProvider);
    final schoolId = tenantSchool?.id ?? authUser?.schoolId;
    
    if (schoolId == null) {
      return <ClassModel>[];
    }
    
    // Set school ID and get classes
    final repo = ref.read(classRepositoryProvider);
    repo.setSchoolId(schoolId);
    
    return await repo.getClasses(activeOnly: true).timeout(
      const Duration(seconds: 10),
      onTimeout: () => <ClassModel>[],
    );
  } catch (e) {
    debugPrint('ClassesProvider error: $e');
    return <ClassModel>[];
  }
});

final classProvider = FutureProvider.family<ClassModel?, int>((
  ref,
  classId,
) async {
  try {
    final repo = ref.read(classRepositoryProvider);
    return await repo
        .getClassById(classId)
        .timeout(const Duration(seconds: 5), onTimeout: () => null);
  } catch (e) {
    debugPrint('Error fetching class: $e');
    return null;
  }
});

final sectionsProvider = FutureProvider.family<List<SectionModel>, int>((
  ref,
  classId,
) async {
  // Validate classId immediately
  if (classId <= 0) {
    return <SectionModel>[];
  }

  try {
    // Get school ID immediately - no waiting
    final tenantSchool = ref.read(tenantContextProvider);
    final authUser = ref.read(authStateProvider);
    final schoolId = tenantSchool?.id ?? authUser?.schoolId;
    
    if (schoolId == null) {
      return <SectionModel>[];
    }
    
    // Set school ID and get sections
    final repo = ref.read(classRepositoryProvider);
    repo.setSchoolId(schoolId);
    
    return await repo.getSections(classId, activeOnly: true).timeout(
      const Duration(seconds: 10),
      onTimeout: () => <SectionModel>[],
    );
  } catch (e) {
    debugPrint('SectionsProvider error: $e');
    return <SectionModel>[];
  }
});

final sectionProvider = FutureProvider.family<SectionModel?, int>((
  ref,
  sectionId,
) async {
  try {
    final repo = ref.read(classRepositoryProvider);
    return await repo
        .getSectionById(sectionId)
        .timeout(const Duration(seconds: 5), onTimeout: () => null);
  } catch (e) {
    debugPrint('Error fetching section: $e');
    return null;
  }
});
