/// Helper functions for providers to safely get school ID
///
/// Provides utilities to safely retrieve school ID from various sources
/// with proper error handling and timeouts.
library;

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../errors/app_error.dart';
import '../errors/error_handler.dart';
import '../errors/validation.dart';
import '../../features/authentication/application/auth_providers.dart';
import '../../core/tenant/tenant_context.dart';
import '../../core/tenant/school_context_provider.dart';
import '../../features/school_registration/application/school_providers.dart';

/// Get school ID from tenant context or auth user with timeout
///
/// This function tries multiple sources and waits for school context
/// to be loaded if needed.
Future<String?> getSchoolIdSafely(
  Ref ref, {
  Duration timeout = const Duration(seconds: 3),
  Duration retryDelay = const Duration(milliseconds: 100),
}) async {
  final correlationId = ErrorHandler.generateCorrelationId();
  final startTime = DateTime.now();

  try {
    // Try immediate read from multiple sources
    String? schoolId;

    // Source 1: tenantContextProvider (most reliable)
    final tenantSchool = ref.read(tenantContextProvider);
    schoolId = tenantSchool?.id;

    // Source 2: authUser.schoolId
    if (schoolId == null) {
      final authUser = ref.read(authStateProvider);
      schoolId = authUser?.schoolId;
    }

    // Source 3: currentSchoolProvider
    if (schoolId == null) {
      try {
        final currentSchool = ref.read(currentSchoolProvider);
        schoolId = currentSchool?.id;
      } catch (e) {
        // Ignore
      }
    }

    // If we have a school ID, validate and return
    if (schoolId != null) {
      final validationError = Validation.validateUuid(schoolId, 'school_id');
      if (validationError == null) {
        return schoolId;
      }
    }

    // If no school ID yet, wait for school context loader
    // This ensures we wait for async school loading
    try {
      final schoolLoaderFuture = ref.read(schoolContextLoaderProvider.future);
      final school = await schoolLoaderFuture.timeout(
        Duration(
          seconds:
              timeout.inSeconds -
              DateTime.now()
                  .difference(startTime)
                  .inSeconds
                  .clamp(0, timeout.inSeconds),
        ),
        onTimeout: () => null,
      );

      if (school != null) {
        schoolId = school.id;
        final validationError = Validation.validateUuid(schoolId, 'school_id');
        if (validationError == null) {
          return schoolId;
        }
      }
    } catch (e) {
      // Ignore - continue with other methods
      debugPrint('Error reading school context loader: $e');
    }

    // Retry with delay if still no school ID
    while (schoolId == null &&
        DateTime.now().difference(startTime).inSeconds < timeout.inSeconds) {
      await Future.delayed(retryDelay);

      // Try all sources again
      final tenantSchool2 = ref.read(tenantContextProvider);
      schoolId = tenantSchool2?.id;

      if (schoolId == null) {
        final authUser2 = ref.read(authStateProvider);
        schoolId = authUser2?.schoolId;
      }

      if (schoolId == null) {
        try {
          final currentSchool2 = ref.read(currentSchoolProvider);
          schoolId = currentSchool2?.id;
        } catch (e) {
          // Ignore
        }
      }

      if (schoolId != null) {
        final validationError = Validation.validateUuid(schoolId, 'school_id');
        if (validationError == null) {
          return schoolId;
        }
        schoolId = null; // Invalid UUID, continue trying
      }
    }

    // Final validation if we got a school ID
    if (schoolId != null) {
      final validationError = Validation.validateUuid(schoolId, 'school_id');
      if (validationError == null) {
        return schoolId;
      }
    }

    return null;
  } catch (e, stackTrace) {
    final error = ErrorHandler.handleException(
      e,
      stackTrace: stackTrace,
      correlationId: correlationId,
      context: 'getSchoolIdSafely',
    );
    ErrorHandler.logError(error);
    return null;
  }
}

/// Execute provider operation with school ID check and error handling
/// Returns immediately if school ID is not available - no waiting
Future<T> safeProviderOperation<T>({
  required Ref ref,
  required Future<T> Function(String schoolId) operation,
  T Function()? onError,
  String? context,
  Duration timeout = const Duration(seconds: 10),
}) async {
  final correlationId = ErrorHandler.generateCorrelationId();
  final ctx = context ?? 'Provider';

  // Get school ID IMMEDIATELY - don't wait at all
  String? schoolId;
  try {
    // Try immediate read only - no async waiting
    final tenantSchool = ref.read(tenantContextProvider);
    schoolId = tenantSchool?.id;
    
    if (schoolId == null) {
      final authUser = ref.read(authStateProvider);
      schoolId = authUser?.schoolId;
    }
    
    if (schoolId == null) {
      try {
        final currentSchool = ref.read(currentSchoolProvider);
        schoolId = currentSchool?.id;
      } catch (e) {
        // Ignore
      }
    }
  } catch (e) {
    debugPrint('$ctx: Error reading school ID: $e');
    schoolId = null;
  }

  // If no school ID, return immediately - don't wait
  if (schoolId == null) {
    debugPrint('$ctx: No valid school ID available, returning empty/default immediately');
    if (onError != null) {
      return onError();
    }
    // Return empty list for list types, null for nullable types
    if (T == List || T.toString().startsWith('List<')) {
      return <dynamic>[] as T;
    }
    return null as T;
  }

  // Execute operation with timeout
  try {
    return await operation(schoolId).timeout(
      timeout,
      onTimeout: () {
        debugPrint('$ctx: Operation timeout after ${timeout.inSeconds}s');
        if (onError != null) {
          return onError();
        }
        // Return empty/default instead of throwing
        if (T == List || T.toString().startsWith('List<')) {
          return <dynamic>[] as T;
        }
        return null as T;
      },
    );
  } catch (e) {
    final error = ErrorHandler.handleException(
      e,
      correlationId: correlationId,
      context: ctx,
    );
    ErrorHandler.logError(error, context: ctx);

    if (onError != null) {
      return onError();
    }

    // Return empty/default instead of rethrowing
    if (T == List || T.toString().startsWith('List<')) {
      return <dynamic>[] as T;
    }
    return null as T;
  }
}
