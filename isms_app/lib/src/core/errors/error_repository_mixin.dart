/// Mixin for repository error handling
/// 
/// Provides standardized error handling for all repositories.
library;

import '../errors/app_error.dart';
import '../errors/error_handler.dart';

mixin ErrorRepositoryMixin {
  /// Validate school ID
  String validateSchoolId(String? schoolId, {String? correlationId}) {
    if (schoolId == null || schoolId.trim().isEmpty) {
      final error = ValidationError.missingField('school_id');
      ErrorHandler.logError(error, context: runtimeType.toString());
      throw error;
    }
    return schoolId;
  }

  /// Execute database operation with error handling
  Future<T> safeDbOperation<T>({
    required Future<T> Function() operation,
    String? context,
    String? correlationId,
    Duration timeout = const Duration(seconds: 10),
  }) async {
    return ErrorHandler.executeWithTimeout(
      operation: () async {
        try {
          return await operation();
        } catch (e, stackTrace) {
          final error = ErrorHandler.handleException(
            e,
            stackTrace: stackTrace,
            correlationId: correlationId,
            context: context ?? runtimeType.toString(),
          );
          ErrorHandler.logError(error, context: context);
          rethrow;
        }
      },
      timeout: timeout,
      correlationId: correlationId,
      context: context ?? runtimeType.toString(),
    );
  }

  /// Execute with retry for network operations
  Future<T> safeDbOperationWithRetry<T>({
    required Future<T> Function() operation,
    String? context,
    String? correlationId,
    int maxRetries = 3,
    Duration timeout = const Duration(seconds: 10),
  }) async {
    return ErrorHandler.executeWithRetry(
      operation: () => safeDbOperation(
        operation: operation,
        context: context,
        correlationId: correlationId,
        timeout: timeout,
      ),
      maxRetries: maxRetries,
      correlationId: correlationId,
    );
  }
}
