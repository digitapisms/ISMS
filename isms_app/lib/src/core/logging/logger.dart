/// Structured logging system
/// 
/// Provides structured logging with request IDs, sensitive data masking,
/// and environment-aware logging levels.
library;

import 'package:flutter/foundation.dart';
import '../errors/app_error.dart';

/// Log levels
enum LogLevel {
  debug,
  info,
  warning,
  error,
  critical,
}

/// Structured logger
class Logger {
  final String context;
  final String? correlationId;

  const Logger(this.context, {this.correlationId});

  /// Create logger with correlation ID
  factory Logger.withCorrelation(String context, String correlationId) {
    return Logger(context, correlationId: correlationId);
  }

  /// Log debug message
  void debug(String message, {Map<String, dynamic>? data}) {
    _log(LogLevel.debug, message, data: data);
  }

  /// Log info message
  void info(String message, {Map<String, dynamic>? data}) {
    _log(LogLevel.info, message, data: data);
  }

  /// Log warning message
  void warning(String message, {Map<String, dynamic>? data}) {
    _log(LogLevel.warning, message, data: data);
  }

  /// Log error message
  void error(String message, {Object? error, StackTrace? stackTrace, Map<String, dynamic>? data}) {
    _log(LogLevel.error, message, error: error, stackTrace: stackTrace, data: data);
  }

  /// Log critical error
  void critical(String message, {Object? error, StackTrace? stackTrace, Map<String, dynamic>? data}) {
    _log(LogLevel.critical, message, error: error, stackTrace: stackTrace, data: data);
  }

  /// Log AppError
  void logError(AppError appError) {
    _log(
      LogLevel.error,
      appError.message,
      error: appError,
      stackTrace: appError.stackTrace,
      data: {
        'error_code': appError.code,
        if (appError.details != null) ...appError.details!,
      },
    );
  }

  /// Internal log method
  void _log(
    LogLevel level,
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? data,
  }) {
    final timestamp = DateTime.now().toIso8601String();
    final levelStr = level.name.toUpperCase();
    
    final logEntry = {
      'timestamp': timestamp,
      'level': levelStr,
      'context': context,
      if (correlationId != null) 'correlation_id': correlationId,
      'message': message,
      if (error != null) 'error': error.toString(),
      if (stackTrace != null && kDebugMode) 'stack_trace': stackTrace.toString(),
      if (data != null) ..._maskSensitiveData(data),
    };

    // In debug mode, print to console
    if (kDebugMode) {
      final prefix = '[$levelStr] [$context]';
      if (correlationId != null) {
        debugPrint('$prefix [ID: $correlationId] $message');
      } else {
        debugPrint('$prefix $message');
      }
      
      if (error != null) {
        debugPrint('Error: $error');
      }
      
      if (data != null && data.isNotEmpty) {
        debugPrint('Data: $data');
      }
      
      if (stackTrace != null) {
        debugPrint('Stack trace: $stackTrace');
      }
    }

    // In production, send to logging service
    // TODO: Integrate with logging service (e.g., Sentry, Firebase Crashlytics)
    // _sendToLoggingService(logEntry);
  }

  /// Mask sensitive data in log entries
  Map<String, dynamic> _maskSensitiveData(Map<String, dynamic> data) {
    final sensitiveKeys = [
      'password',
      'token',
      'api_key',
      'secret',
      'auth_id',
      'access_token',
      'refresh_token',
      'credit_card',
      'cnic',
      'bform',
    ];

    final masked = Map<String, dynamic>.from(data);
    
    for (final key in sensitiveKeys) {
      if (masked.containsKey(key) && masked[key] != null) {
        final value = masked[key].toString();
        if (value.isNotEmpty) {
          masked[key] = '***MASKED***';
        }
      }
    }

    return masked;
  }
}

/// Global logger instance
final globalLogger = Logger('Global');
