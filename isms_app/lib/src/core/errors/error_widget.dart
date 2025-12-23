/// UI error handling widgets
/// 
/// Provides user-friendly error display widgets that map backend
/// error codes to user-friendly messages.
library;

import 'package:flutter/material.dart';
import 'app_error.dart';
import 'error_handler.dart';

/// Error display widget
class ErrorDisplay extends StatelessWidget {
  const ErrorDisplay({
    super.key,
    required this.error,
    this.onRetry,
    this.title,
    this.showDetails = false,
  });

  final AppError error;
  final VoidCallback? onRetry;
  final String? title;
  final bool showDetails;

  @override
  Widget build(BuildContext context) {
    final userMessage = ErrorHandler.getUserMessage(error);
    final isRetryable = ErrorHandler.isRetryable(error);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _getErrorIcon(error),
              size: 64,
              color: _getErrorColor(context, error),
            ),
            const SizedBox(height: 16),
            Text(
              title ?? 'Error',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              userMessage,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            if (showDetails && error.details != null) ...[
              const SizedBox(height: 16),
              ExpansionTile(
                title: const Text('Technical Details'),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Error Code: ${error.code}\n'
                      'Correlation ID: ${error.correlationId ?? 'N/A'}\n'
                      'Details: ${error.details}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ],
            if (isRetryable && onRetry != null) ...[
              const SizedBox(height: 24),
              FilledButton.icon(
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                onPressed: onRetry,
              ),
            ],
          ],
        ),
      ),
    );
  }

  IconData _getErrorIcon(AppError error) {
    if (error is NetworkError) {
      return Icons.wifi_off;
    }
    if (error is AuthError) {
      return Icons.lock_outline;
    }
    if (error is ValidationError) {
      return Icons.error_outline;
    }
    if (error is DatabaseError) {
      return Icons.storage;
    }
    return Icons.error_outline;
  }

  Color _getErrorColor(BuildContext context, AppError error) {
    if (error is NetworkError || error is DatabaseError) {
      return Colors.orange;
    }
    if (error is AuthError) {
      return Colors.red;
    }
    if (error is ValidationError) {
      return Colors.amber;
    }
    return Theme.of(context).colorScheme.error;
  }
}

/// Error snackbar helper
class ErrorSnackbar {
  static void show(
    BuildContext context,
    AppError error, {
    Duration duration = const Duration(seconds: 4),
  }) {
    final userMessage = ErrorHandler.getUserMessage(error);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              Icons.error_outline,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                userMessage,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: _getErrorColor(context, error),
        duration: duration,
        action: ErrorHandler.isRetryable(error)
            ? SnackBarAction(
                label: 'Retry',
                textColor: Colors.white,
                onPressed: () {
                  // Retry logic would be passed as callback
                },
              )
            : null,
      ),
    );
  }

  static Color _getErrorColor(BuildContext context, AppError error) {
    if (error is NetworkError) {
      return Colors.orange;
    }
    if (error is AuthError) {
      return Colors.red;
    }
    return Theme.of(context).colorScheme.error;
  }
}

/// Error boundary for async operations
class AsyncErrorHandler {
  /// Handle error in async provider
  static Widget buildErrorWidget(
    Object error,
    StackTrace? stackTrace, {
    VoidCallback? onRetry,
    String? title,
  }) {
    final appError = error is AppError
        ? error
        : ErrorHandler.handleException(
            error,
            stackTrace: stackTrace,
          );

    return ErrorDisplay(
      error: appError,
      onRetry: onRetry,
      title: title,
      showDetails: false, // Don't show details in production
    );
  }
}
