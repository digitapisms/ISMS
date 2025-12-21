import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/error_handler.dart';
import '../../../core/errors/provider_helpers.dart';
import '../../../core/network/supabase_providers.dart';
import '../../../core/tenant/tenant_context.dart';
import '../../authentication/application/auth_providers.dart';
import '../data/student_repository.dart';
import '../domain/student.dart';

final studentRepositoryProvider = Provider<StudentRepository>((ref) {
  final client = ref.read(databaseClientProvider);
  final repo = StudentRepository(client: client);
  final tenantSchool = ref.read(tenantContextProvider);
  final authUser = ref.read(authStateProvider);
  repo.setSchoolId(tenantSchool?.id ?? authUser?.schoolId);
  return repo;
});

/// Provider for current authenticated student
final currentStudentProvider = FutureProvider<Student?>((ref) async {
  final correlationId = ErrorHandler.generateCorrelationId();

  try {
    final repo = ref.read(studentRepositoryProvider);
    return await repo.fetchCurrentStudent().timeout(
      const Duration(seconds: 10),
      onTimeout: () => null,
    );
  } catch (e) {
    final error = ErrorHandler.handleException(
      e,
      correlationId: correlationId,
      context: 'CurrentStudentProvider',
    );
    ErrorHandler.logError(error);
    return null;
  }
});

final studentsProvider = FutureProvider<List<Student>>((ref) async {
  return safeProviderOperation<List<Student>>(
    ref: ref,
    operation: (schoolId) async {
      final repo = ref.read(studentRepositoryProvider);
      // Ensure repo is configured even if it was created before school context loaded.
      repo.setSchoolId(schoolId);
      return await repo.fetchStudents().timeout(const Duration(seconds: 10));
    },
    onError: () => <Student>[],
    context: 'StudentsProvider',
  );
});

final studentDetailProvider = FutureProvider.family<Student?, String>((
  ref,
  studentId,
) async {
  final correlationId = ErrorHandler.generateCorrelationId();

  try {
    final repo = ref.read(studentRepositoryProvider);
    return await repo
        .fetchStudentById(studentId)
        .timeout(const Duration(seconds: 10), onTimeout: () => null);
  } catch (e) {
    final error = ErrorHandler.handleException(
      e,
      correlationId: correlationId,
      context: 'StudentDetailProvider',
    );
    ErrorHandler.logError(error);
    return null;
  }
});

final studentDocumentsProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>((
      ref,
      studentId,
    ) async {
      final correlationId = ErrorHandler.generateCorrelationId();

      try {
        final repo = ref.read(studentRepositoryProvider);
        return await repo
            .fetchStudentDocuments(studentId)
            .timeout(
              const Duration(seconds: 10),
              onTimeout: () => <Map<String, dynamic>>[],
            );
      } catch (e) {
        final error = ErrorHandler.handleException(
          e,
          correlationId: correlationId,
          context: 'StudentDocumentsProvider',
        );
        ErrorHandler.logError(error);
        return <Map<String, dynamic>>[];
      }
    });

final studentFamilyProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>((
      ref,
      studentId,
    ) async {
      final correlationId = ErrorHandler.generateCorrelationId();

      try {
        final repo = ref.read(studentRepositoryProvider);
        return await repo
            .fetchStudentFamily(studentId)
            .timeout(
              const Duration(seconds: 10),
              onTimeout: () => <Map<String, dynamic>>[],
            );
      } catch (e) {
        final error = ErrorHandler.handleException(
          e,
          correlationId: correlationId,
          context: 'StudentFamilyProvider',
        );
        ErrorHandler.logError(error);
        return <Map<String, dynamic>>[];
      }
    });

final studentEmergencyContactsProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>((
      ref,
      studentId,
    ) async {
      final correlationId = ErrorHandler.generateCorrelationId();

      try {
        final repo = ref.read(studentRepositoryProvider);
        return await repo
            .fetchStudentEmergencyContacts(studentId)
            .timeout(
              const Duration(seconds: 10),
              onTimeout: () => <Map<String, dynamic>>[],
            );
      } catch (e) {
        final error = ErrorHandler.handleException(
          e,
          correlationId: correlationId,
          context: 'StudentEmergencyContactsProvider',
        );
        ErrorHandler.logError(error);
        return <Map<String, dynamic>>[];
      }
    });

final applicationStatusProvider =
    FutureProvider.family<Map<String, dynamic>?, String>((ref, userId) async {
      final correlationId = ErrorHandler.generateCorrelationId();

      try {
        final repo = ref.read(studentRepositoryProvider);
        return await repo
            .fetchApplicationStatus(userId)
            .timeout(const Duration(seconds: 10), onTimeout: () => null);
      } catch (e) {
        final error = ErrorHandler.handleException(
          e,
          correlationId: correlationId,
          context: 'ApplicationStatusProvider',
        );
        ErrorHandler.logError(error);
        return null;
      }
    });

final pendingApplicationsProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  return safeProviderOperation<List<Map<String, dynamic>>>(
    ref: ref,
    operation: (schoolId) async {
      final repo = ref.read(studentRepositoryProvider);
      return await repo.fetchPendingApplications().timeout(
        const Duration(seconds: 10),
      );
    },
    onError: () => <Map<String, dynamic>>[],
    context: 'PendingApplicationsProvider',
  );
});

final applicationDetailProvider =
    FutureProvider.family<Map<String, dynamic>?, String>((
      ref,
      applicationId,
    ) async {
      final correlationId = ErrorHandler.generateCorrelationId();

      try {
        final repo = ref.read(studentRepositoryProvider);
        return await repo
            .fetchApplicationDetails(applicationId)
            .timeout(const Duration(seconds: 10), onTimeout: () => null);
      } catch (e) {
        final error = ErrorHandler.handleException(
          e,
          correlationId: correlationId,
          context: 'ApplicationDetailProvider',
        );
        ErrorHandler.logError(error);
        return null;
      }
    });
