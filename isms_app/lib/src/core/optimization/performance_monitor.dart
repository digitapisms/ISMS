import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Performance metrics for monitoring app performance
class PerformanceMetrics {
  final String operation;
  final Duration duration;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;

  PerformanceMetrics({
    required this.operation,
    required this.duration,
    required this.timestamp,
    this.metadata,
  });
}

/// Monitors and tracks app performance
class PerformanceMonitor {
  static final List<PerformanceMetrics> _metrics = [];
  static const int _maxMetrics = 1000;

  /// Track operation performance
  static Future<T> trackOperation<T>(
    String operation,
    Future<T> Function() operationFn, {
    Map<String, dynamic>? metadata,
  }) async {
    final stopwatch = Stopwatch()..start();
    try {
      final result = await operationFn();
      stopwatch.stop();
      _addMetric(PerformanceMetrics(
        operation: operation,
        duration: stopwatch.elapsed,
        timestamp: DateTime.now(),
        metadata: metadata,
      ));
      return result;
    } catch (e) {
      stopwatch.stop();
      _addMetric(PerformanceMetrics(
        operation: operation,
        duration: stopwatch.elapsed,
        timestamp: DateTime.now(),
        metadata: {...?metadata, 'error': e.toString()},
      ));
      rethrow;
    }
  }

  /// Track synchronous operation
  static T trackSyncOperation<T>(
    String operation,
    T Function() operationFn, {
    Map<String, dynamic>? metadata,
  }) {
    final stopwatch = Stopwatch()..start();
    try {
      final result = operationFn();
      stopwatch.stop();
      _addMetric(PerformanceMetrics(
        operation: operation,
        duration: stopwatch.elapsed,
        timestamp: DateTime.now(),
        metadata: metadata,
      ));
      return result;
    } catch (e) {
      stopwatch.stop();
      _addMetric(PerformanceMetrics(
        operation: operation,
        duration: stopwatch.elapsed,
        timestamp: DateTime.now(),
        metadata: {...?metadata, 'error': e.toString()},
      ));
      rethrow;
    }
  }

  static void _addMetric(PerformanceMetrics metric) {
    _metrics.add(metric);
    if (_metrics.length > _maxMetrics) {
      _metrics.removeAt(0);
    }
  }

  /// Get performance metrics
  static List<PerformanceMetrics> getMetrics() => List.unmodifiable(_metrics);

  /// Get average duration for an operation
  static Duration? getAverageDuration(String operation) {
    final operationMetrics = _metrics
        .where((m) => m.operation == operation)
        .map((m) => m.duration)
        .toList();
    if (operationMetrics.isEmpty) return null;
    final total = operationMetrics.fold<Duration>(
      Duration.zero,
      (sum, duration) => sum + duration,
    );
    return Duration(
      microseconds: total.inMicroseconds ~/ operationMetrics.length,
    );
  }

  /// Clear metrics
  static void clearMetrics() {
    _metrics.clear();
  }

  /// Get slow operations (above threshold)
  static List<PerformanceMetrics> getSlowOperations(Duration threshold) {
    return _metrics.where((m) => m.duration > threshold).toList();
  }
}

/// Provider for performance metrics
final performanceMetricsProvider = Provider<List<PerformanceMetrics>>((ref) {
  return PerformanceMonitor.getMetrics();
});

