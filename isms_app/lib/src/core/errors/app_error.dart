/// Centralized error handling system for ISMS
/// 
/// This module provides structured error classes, error codes, and
/// consistent error handling patterns across the application.
library;

import 'package:equatable/equatable.dart';

/// Base error class for all application errors
abstract class AppError extends Equatable implements Exception {
  const AppError({
    required this.code,
    required this.message,
    this.userMessage,
    this.details,
    this.stackTrace,
    this.correlationId,
  });

  /// Machine-readable error code
  final String code;
  
  /// Technical error message (for logging)
  final String message;
  
  /// User-friendly error message
  final String? userMessage;
  
  /// Additional error details
  final Map<String, dynamic>? details;
  
  /// Stack trace (only in debug/development)
  final StackTrace? stackTrace;
  
  /// Request correlation ID for tracing
  final String? correlationId;

  @override
  List<Object?> get props => [
        code,
        message,
        userMessage,
        details,
        correlationId,
      ];

  @override
  String toString() => message;
}

/// Network/API related errors
class NetworkError extends AppError {
  const NetworkError({
    required super.message,
    super.userMessage,
    super.details,
    super.stackTrace,
    super.correlationId,
    this.statusCode,
    this.responseBody,
  }) : super(code: 'NETWORK_ERROR');

  final int? statusCode;
  final String? responseBody;

  factory NetworkError.timeout({
    String? userMessage,
    String? correlationId,
  }) {
    return NetworkError(
      message: 'Request timeout',
      userMessage: userMessage ?? 'The request took too long. Please try again.',
      correlationId: correlationId,
    );
  }

  factory NetworkError.connection({
    String? userMessage,
    String? correlationId,
  }) {
    return NetworkError(
      message: 'Connection error',
      userMessage: userMessage ?? 'Unable to connect to server. Please check your internet connection.',
      correlationId: correlationId,
    );
  }

  factory NetworkError.fromStatusCode(
    int statusCode, {
    String? message,
    String? responseBody,
    String? correlationId,
  }) {
    String userMsg;
    String code;
    
    switch (statusCode) {
      case 400:
        code = 'BAD_REQUEST';
        userMsg = 'Invalid request. Please check your input.';
        break;
      case 401:
        code = 'UNAUTHORIZED';
        userMsg = 'You are not authorized. Please log in again.';
        break;
      case 403:
        code = 'FORBIDDEN';
        userMsg = 'You do not have permission to perform this action.';
        break;
      case 404:
        code = 'NOT_FOUND';
        userMsg = 'The requested resource was not found.';
        break;
      case 409:
        code = 'CONFLICT';
        userMsg = 'This action conflicts with existing data.';
        break;
      case 422:
        code = 'VALIDATION_ERROR';
        userMsg = 'Validation failed. Please check your input.';
        break;
      case 429:
        code = 'RATE_LIMIT';
        userMsg = 'Too many requests. Please try again later.';
        break;
      case 500:
      case 502:
      case 503:
      case 504:
        code = 'SERVER_ERROR';
        userMsg = 'Server error. Please try again later.';
        break;
      default:
        code = 'NETWORK_ERROR';
        userMsg = 'An error occurred. Please try again.';
    }
    
    return NetworkError(
      message: message ?? 'HTTP $statusCode: $code',
      userMessage: userMsg,
      statusCode: statusCode,
      responseBody: responseBody,
      correlationId: correlationId,
      details: {'http_status': statusCode},
    );
  }
}

/// Authentication/Authorization errors
class AuthError extends AppError {
  const AuthError({
    required super.message,
    super.userMessage,
    super.details,
    super.stackTrace,
    super.correlationId,
  }) : super(code: 'AUTH_ERROR');

  factory AuthError.unauthorized({
    String? userMessage,
    String? correlationId,
  }) {
    return AuthError(
      message: 'Unauthorized access',
      userMessage: userMessage ?? 'You are not authorized to perform this action.',
      correlationId: correlationId,
    );
  }

  factory AuthError.sessionExpired({
    String? correlationId,
  }) {
    return AuthError(
      message: 'Session expired',
      userMessage: 'Your session has expired. Please log in again.',
      correlationId: correlationId,
    );
  }

  factory AuthError.invalidCredentials({
    String? correlationId,
  }) {
    return AuthError(
      message: 'Invalid credentials',
      userMessage: 'Invalid email or password. Please try again.',
      correlationId: correlationId,
    );
  }
}

/// Validation errors
class ValidationError extends AppError {
  const ValidationError({
    required super.message,
    super.userMessage,
    this.field,
    super.details,
    super.stackTrace,
    super.correlationId,
  }) : super(code: 'VALIDATION_ERROR');

  final String? field;

  factory ValidationError.missingField(String field) {
    return ValidationError(
      message: 'Missing required field: $field',
      userMessage: 'Please fill in all required fields.',
      field: field,
    );
  }

  factory ValidationError.invalidFormat(String field, String format) {
    return ValidationError(
      message: 'Invalid format for field $field: expected $format',
      userMessage: 'Please enter a valid $field.',
      field: field,
    );
  }

  factory ValidationError.outOfRange(String field, {required num min, required num max}) {
    return ValidationError(
      message: 'Field $field out of range: must be between $min and $max',
      userMessage: 'Please enter a valid value for $field.',
      field: field,
    );
  }
}

/// Database errors
class DatabaseError extends AppError {
  const DatabaseError({
    required super.message,
    super.userMessage,
    super.details,
    super.stackTrace,
    super.correlationId,
    this.operation,
    this.table,
  }) : super(code: 'DATABASE_ERROR');

  final String? operation;
  final String? table;

  factory DatabaseError.queryFailed({
    required String operation,
    String? table,
    String? message,
    String? correlationId,
  }) {
    return DatabaseError(
      message: message ?? 'Database query failed: $operation',
      userMessage: 'Unable to retrieve data. Please try again.',
      operation: operation,
      table: table,
      correlationId: correlationId,
    );
  }

  factory DatabaseError.constraintViolation({
    required String constraint,
    String? table,
    String? correlationId,
  }) {
    return DatabaseError(
      message: 'Database constraint violation: $constraint',
      userMessage: 'This action conflicts with existing data.',
      table: table,
      correlationId: correlationId,
      details: {'constraint': constraint},
    );
  }

  factory DatabaseError.notFound({
    required String resource,
    String? correlationId,
  }) {
    return DatabaseError(
      message: 'Resource not found: $resource',
      userMessage: 'The requested item was not found.',
      correlationId: correlationId,
      details: {'resource': resource},
    );
  }
}

/// Business logic errors
class BusinessLogicError extends AppError {
  const BusinessLogicError({
    required super.message,
    super.userMessage,
    super.details,
    super.stackTrace,
    super.correlationId,
  }) : super(code: 'BUSINESS_LOGIC_ERROR');

  factory BusinessLogicError.invalidOperation({
    required String operation,
    String? reason,
    String? correlationId,
  }) {
    return BusinessLogicError(
      message: 'Invalid operation: $operation${reason != null ? '. Reason: $reason' : ''}',
      userMessage: 'This operation cannot be performed.',
      correlationId: correlationId,
      details: {'operation': operation, if (reason != null) 'reason': reason},
    );
  }

  factory BusinessLogicError.stateConflict({
    required String currentState,
    required String requiredState,
    String? correlationId,
  }) {
    return BusinessLogicError(
      message: 'State conflict: current=$currentState, required=$requiredState',
      userMessage: 'This action cannot be performed in the current state.',
      correlationId: correlationId,
      details: {
        'current_state': currentState,
        'required_state': requiredState,
      },
    );
  }
}

/// Configuration/Environment errors
class ConfigurationError extends AppError {
  const ConfigurationError({
    required super.message,
    super.userMessage,
    super.details,
    super.stackTrace,
    super.correlationId,
  }) : super(code: 'CONFIGURATION_ERROR');

  factory ConfigurationError.missingSetting(String setting) {
    return ConfigurationError(
      message: 'Missing configuration: $setting',
      userMessage: 'System configuration error. Please contact support.',
      details: {'setting': setting},
    );
  }
}

/// Unknown/Unexpected errors
class UnknownError extends AppError {
  const UnknownError({
    required super.message,
    super.userMessage,
    super.details,
    super.stackTrace,
    super.correlationId,
  }) : super(code: 'UNKNOWN_ERROR');

  factory UnknownError.fromException(
    Object exception, {
    StackTrace? stackTrace,
    String? correlationId,
  }) {
    return UnknownError(
      message: 'Unexpected error: ${exception.toString()}',
      userMessage: 'An unexpected error occurred. Please try again or contact support.',
      stackTrace: stackTrace,
      correlationId: correlationId,
      details: {'exception_type': exception.runtimeType.toString()},
    );
  }
}

/// Error code constants
class ErrorCodes {
  // Network errors
  static const String networkTimeout = 'NETWORK_TIMEOUT';
  static const String networkConnection = 'NETWORK_CONNECTION';
  static const String networkBadRequest = 'NETWORK_BAD_REQUEST';
  static const String networkUnauthorized = 'NETWORK_UNAUTHORIZED';
  static const String networkForbidden = 'NETWORK_FORBIDDEN';
  static const String networkNotFound = 'NETWORK_NOT_FOUND';
  static const String networkServerError = 'NETWORK_SERVER_ERROR';
  
  // Auth errors
  static const String authUnauthorized = 'AUTH_UNAUTHORIZED';
  static const String authSessionExpired = 'AUTH_SESSION_EXPIRED';
  static const String authInvalidCredentials = 'AUTH_INVALID_CREDENTIALS';
  
  // Validation errors
  static const String validationMissingField = 'VALIDATION_MISSING_FIELD';
  static const String validationInvalidFormat = 'VALIDATION_INVALID_FORMAT';
  static const String validationOutOfRange = 'VALIDATION_OUT_OF_RANGE';
  
  // Database errors
  static const String databaseQueryFailed = 'DATABASE_QUERY_FAILED';
  static const String databaseConstraintViolation = 'DATABASE_CONSTRAINT_VIOLATION';
  static const String databaseNotFound = 'DATABASE_NOT_FOUND';
  
  // Business logic errors
  static const String businessInvalidOperation = 'BUSINESS_INVALID_OPERATION';
  static const String businessStateConflict = 'BUSINESS_STATE_CONFLICT';
  
  // Configuration errors
  static const String configMissingSetting = 'CONFIG_MISSING_SETTING';
  
  // Unknown errors
  static const String unknown = 'UNKNOWN_ERROR';
}
