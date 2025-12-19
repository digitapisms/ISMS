import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/tenant/tenant_context.dart';
import '../../authentication/application/auth_providers.dart';
import '../data/class_repository.dart';
import '../domain/class_model.dart';
import '../domain/section_model.dart';

final classRepositoryProvider = Provider<ClassRepository>((ref) {
  final repo = ClassRepository();
  final tenantSchool = ref.watch(tenantContextProvider);
  final authUser = ref.watch(authStateProvider);
  final schoolId = tenantSchool?.id ?? authUser?.schoolId;
  if (schoolId != null) {
    repo.setSchoolId(schoolId);
  }
  return repo;
});

final classesProvider = FutureProvider<List<ClassModel>>((ref) async {
  try {
    // Watch school context to refresh when it changes
    ref.watch(tenantContextProvider);
    ref.watch(authStateProvider);

    final repo = ref.read(classRepositoryProvider);
    return await repo.getClasses(activeOnly: true);
  } catch (e) {
    debugPrint('Error fetching classes: $e');
    return const [];
  }
});

final classProvider = FutureProvider.family<ClassModel?, int>((
  ref,
  classId,
) async {
  try {
    final repo = ref.read(classRepositoryProvider);
    return await repo.getClassById(classId);
  } catch (e) {
    debugPrint('Error fetching class: $e');
    return null;
  }
});

final sectionsProvider = FutureProvider.family<List<SectionModel>, int>((
  ref,
  classId,
) async {
  try {
    final repo = ref.read(classRepositoryProvider);
    return await repo.getSections(classId, activeOnly: true);
  } catch (e) {
    debugPrint('Error fetching sections: $e');
    return const [];
  }
});

final sectionProvider = FutureProvider.family<SectionModel?, int>((
  ref,
  sectionId,
) async {
  try {
    final repo = ref.read(classRepositoryProvider);
    return await repo.getSectionById(sectionId);
  } catch (e) {
    debugPrint('Error fetching section: $e');
    return null;
  }
});
