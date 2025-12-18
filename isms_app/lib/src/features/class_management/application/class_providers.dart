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
  repo.setSchoolId(tenantSchool?.id ?? authUser?.schoolId);
  return repo;
});

final classesProvider = FutureProvider<List<ClassModel>>((ref) async {
  final repo = ref.read(classRepositoryProvider);
  return repo.getClasses(activeOnly: true);
});

final classProvider = FutureProvider.family<ClassModel?, String>((
  ref,
  classId,
) async {
  final repo = ref.read(classRepositoryProvider);
  return repo.getClassById(classId);
});

final sectionsProvider = FutureProvider.family<List<SectionModel>, String>((
  ref,
  classId,
) async {
  final repo = ref.read(classRepositoryProvider);
  return repo.getSections(classId, activeOnly: true);
});

final sectionProvider = FutureProvider.family<SectionModel?, String>((
  ref,
  sectionId,
) async {
  final repo = ref.read(classRepositoryProvider);
  return repo.getSectionById(sectionId);
});
