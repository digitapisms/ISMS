/// Global error handler and utilities
/// 
/// Provides error handling, logging, and error transformation utilities.
library;

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app_error.dart';

/// Global error handler
class ErrorHandler {
  /// Generate a correlation ID for request tracing
  static String generateCorrelationId() {
    return '${DateTime.now().millisecondsSinceEpoch}-${(1000 + (9999 - 1000) * (DateTime.now().microsecond / 1000000))
            .round()}';
  }

  /// Handle and transform exceptions to AppError
  static AppError handleException(
    Object exception, {
    StackTrace? stackTrace,
    String? correlationId,
    String? context,
  }) {
    final corrId = correlationId ?? generateCorrelationId();
    final ctx = context != null ? '[$context] ' : '';

    // Handle known error types
    if (exception is AppError) {
      return exception;
    }

    if (exception is PostgrestException) {
      return _handlePostgrestException(exception, corrId, ctx);
    }

    if (exception is AuthException) {
      return _handleAuthException(exception, corrId, ctx);
    }

    if (exception is StorageException) {
      return _handleStorageException(exception, corrId, ctx);
    }

    if (exception is TimeoutException) {
      return NetworkError.timeout(
        userMessage: 'The operation took too long. Please try again.',
        correlationId: corrId,
      );
    }

    // Handle string exceptions
    if (exception is String) {
      return UnknownError(
        message: '$ctx$exception',
        userMessage: 'An error occurred. Please try again.',
        correlationId: corrId,
      );
    }

    // Unknown exception
    return UnknownError.fromException(
      exception,
      stackTrace: stackTrace,
      correlationId: corrId,
    );
  }

  /// Handle PostgrestException (Supabase database errors)
  static AppError _handlePostgrestException(
    PostgrestException exception,
    String correlationId,
    String context,
  ) {
    final code = exception.code ?? 'UNKNOWN';
    final message = exception.message ?? 'Database error';
    final details = exception.details;
    final hint = exception.hint;

    // Map PostgreSQL error codes to our error types
    switch (code) {
      case 'PGRST116': // Not found
        return DatabaseError.notFound(
          resource: message,
          correlationId: correlationId,
        );

      case 'PGRST204': // Not found (RPC)
        return DatabaseError.notFound(
          resource: 'RPC function',
          correlationId: correlationId,
        );

      case '23505': // Unique violation
      case '23503': // Foreign key violation
        return DatabaseError(
          message: 'Database constraint violation: $code',
          userMessage: 'This action conflicts with existing data.',
          table: null,
          correlationId: correlationId,
          details: {
            'constraint': code,
            'code': code,
            'message': message,
            if (details != null) 'details': details,
            if (hint != null) 'hint': hint,
          },
        );

      case '23502': // Not null violation
        return ValidationError(
          message: '${context}Required field is missing',
          userMessage: 'Please fill in all required fields.',
          correlationId: correlationId,
          details: {
            'code': code,
            'message': message,
            if (details != null) 'details': details,
            if (hint != null) 'hint': hint,
          },
        );

      case '42703': // Undefined column
      case '42P01': // Undefined table
        return DatabaseError(
          message: '${context}Database schema error: $message',
          userMessage: 'System configuration error. Please contact support.',
          correlationId: correlationId,
          details: {
            'code': code,
            'message': message,
            if (details != null) 'details': details,
          },
        );

      default:
        return DatabaseError(
          message: '${context}Database error: $message',
          userMessage: 'Unable to process request. Please try again.',
          correlationId: correlationId,
          details: {
            'code': code,
            'message': message,
            if (details != null) 'details': details,
            if (hint != null) 'hint': hint,
          },
        );
    }
  }

  /// Handle AuthException
  static AppError _handleAuthException(
    AuthException exception,
    String correlationId,
    String context,
  ) {
    final message = exception.message;

    if (message.contains('Invalid login credentials') ||
        message.contains('Email not confirmed')) {
      return AuthError.invalidCredentials(correlationId: correlationId);
    }

    if (message.contains('JWT expired') || message.contains('session')) {
      return AuthError.sessionExpired(correlationId: correlationId);
    }

    return AuthError(
      message: '${context}Auth error: $message',
      userMessage: 'Authentication error. Please try again.',
      correlationId: correlationId,
    );
  }

  /// Handle StorageException
  static AppError _handleStorageException(
    StorageException exception,
    String correlationId,
    String context,
  ) {
    final message = exception.message;
    final statusCode = exception.statusCode;

    // StorageException.statusCode is String, convert to int if possible
    if (statusCode != null) {
      final statusCodeInt = int.tryParse(statusCode.toString());
      if (statusCodeInt != null) {
        return NetworkError.fromStatusCode(
          statusCodeInt,
          message: '${context}Storage error: $message',
          correlationId: correlationId,
        );
      }
    }

    return NetworkError(
      message: '${context}Storage error: $message',
      userMessage: 'File operation failed. Please try again.',
      correlationId: correlationId,
    );
  }

  /// Log error with structured logging
  static void logError(
    AppError error, {
    String? context,
    bool includeStackTrace = kDebugMode,
  }) {
    final logData = {
      'error_code': error.code,
      'message': error.message,
      'correlation_id': error.correlationId,
      if (context != null) 'context': context,
      if (error.details != null) 'details': error.details,
      if (includeStackTrace && error.stackTrace != null)
        'stack_trace': error.stackTrace.toString(),
    };

    if (kDebugMode) {
      debugPrint('ERROR: ${error.code} - ${error.message}');
      debugPrint('Correlation ID: ${error.correlationId}');
      if (error.details != null) {
        debugPrint('Details: ${error.details}');
      }
      if (includeStackTrace && error.stackTrace != null) {
        debugPrint('Stack trace: ${error.stackTrace}');
      }
    }

    // In production, send to logging service
    // TODO: Integrate with logging service (e.g., Sentry, Firebase Crashlytics)
  }

  /// Get user-friendly error message
  static String getUserMessage(AppError error) {
    return error.userMessage ?? 'An error occurred. Please try again.';
  }

  /// Check if error is retryable
  static bool isRetryable(AppError error) {
    if (error is NetworkError) {
      // Retry on network errors (except 4xx client errors)
      final statusCode = error.statusCode;
      if (statusCode != null) {
        return statusCode >= 500 || statusCode == 429; // Server errors or rate limit
      }
      return true; // Connection/timeout errors are retryable
    }
    return false;
  }

  /// Execute with retry logic
  static Future<T> executeWithRetry<T>({
    required Future<T> Function() operation,
    int maxRetries = 3,
    Duration delay = const Duration(seconds: 1),
    String? correlationId,
    bool Function(AppError)? shouldRetry,
  }) async {
    final corrId = correlationId ?? generateCorrelationId();
    int attempts = 0;
    AppError? lastError;

    while (attempts < maxRetries) {
      try {
        return await operation();
      } catch (e, stackTrace) {
        lastError = handleException(
          e,
          stackTrace: stackTrace,
          correlationId: corrId,
        );

        // Check if we should retry
        final retry = shouldRetry?.call(lastError) ?? isRetryable(lastError);
        if (!retry || attempts >= maxRetries - 1) {
          break;
        }

        attempts++;
        logError(
          lastError,
          context: 'Retry attempt $attempts/$maxRetries',
        );
        await Future.delayed(delay * attempts); // Exponential backoff
      }
    }

    // All retries exhausted
    if (lastError != null) {
      logError(lastError, context: 'All retries exhausted');
      throw lastError;
    }

    throw UnknownError(
      message: 'Operation failed after $maxRetries attempts',
      correlationId: corrId,
    );
  }

  /// Execute with timeout
  static Future<T> executeWithTimeout<T>({
    required Future<T> Function() operation,
    required Duration timeout,
    String? correlationId,
    String? context,
  }) async {
    try {
      return await operation().timeout(
        timeout,
        onTimeout: () {
          throw TimeoutException(
            'Operation timed out after ${timeout.inSeconds} seconds',
            timeout,
          );
        },
      );
    } catch (e, stackTrace) {
      final error = handleException(
        e,
        stackTrace: stackTrace,
        correlationId: correlationId,
        context: context,
      );
      logError(error, context: context);
      rethrow;
    }
  }
}

/// Extension to safely execute async operations
extension SafeAsync<T> on Future<T> {
  /// Execute with error handling
  Future<T> safeExecute({
    String? correlationId,
    String? context,
    AppError Function(Object, StackTrace)? onError,
  }) async {
    try {
      return await this;
    } catch (e, stackTrace) {
      final error = onError?.call(e, stackTrace) ??
          ErrorHandler.handleException(
            e,
            stackTrace: stackTrace,
            correlationId: correlationId,
            context: context,
          );
      ErrorHandler.logError(error, context: context);
      throw error;
    }
  }

  /// Execute with timeout and error handling
  Future<T> safeExecuteWithTimeout({
    required Duration timeout,
    String? correlationId,
    String? context,
  }) async {
    return ErrorHandler.executeWithTimeout(
      operation: () => this,
      timeout: timeout,
      correlationId: correlationId,
      context: context,
    );
  }
}
