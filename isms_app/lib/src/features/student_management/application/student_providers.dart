import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/supabase_providers.dart';
import '../../../core/tenant/tenant_context.dart';
import '../../authentication/application/auth_providers.dart';
import '../data/student_repository.dart';
import '../domain/student.dart';

final studentRepositoryProvider = Provider<StudentRepository>((ref) {
  final client = ref.read(databaseClientProvider);
  final repo = StudentRepository(client: client);
  final tenantSchool = ref.watch(tenantContextProvider);
  final authUser = ref.watch(authStateProvider);
  repo.setSchoolId(tenantSchool?.id ?? authUser?.schoolId);
  return repo;
});

/// Provider for current authenticated student
final currentStudentProvider = FutureProvider<Student?>((ref) async {
  final repo = ref.watch(studentRepositoryProvider);
  return repo.fetchCurrentStudent();
});

final studentsProvider = FutureProvider<List<Student>>((ref) async {
  final repo = ref.read(studentRepositoryProvider);
  return repo.fetchStudents();
});

final studentDetailProvider = FutureProvider.family<Student?, String>((
  ref,
  studentId,
) async {
  final repo = ref.read(studentRepositoryProvider);
  return repo.fetchStudentById(studentId);
});

final studentDocumentsProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>((
      ref,
      studentId,
    ) async {
      final repo = ref.read(studentRepositoryProvider);
      return repo.fetchStudentDocuments(studentId);
    });

final studentFamilyProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>((
      ref,
      studentId,
    ) async {
      final repo = ref.read(studentRepositoryProvider);
      return repo.fetchStudentFamily(studentId);
    });

final studentEmergencyContactsProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>((
      ref,
      studentId,
    ) async {
      final repo = ref.read(studentRepositoryProvider);
      return repo.fetchStudentEmergencyContacts(studentId);
    });

final applicationStatusProvider =
    FutureProvider.family<Map<String, dynamic>?, String>((ref, userId) async {
      final repo = ref.read(studentRepositoryProvider);
      return repo.fetchApplicationStatus(userId);
    });

final pendingApplicationsProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  final repo = ref.read(studentRepositoryProvider);
  return repo.fetchPendingApplications();
});

final applicationDetailProvider =
    FutureProvider.family<Map<String, dynamic>?, String>((
      ref,
      applicationId,
    ) async {
      final repo = ref.read(studentRepositoryProvider);
      return repo.fetchApplicationDetails(applicationId);
    });
