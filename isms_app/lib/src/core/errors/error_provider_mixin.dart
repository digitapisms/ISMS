/// Mixin for provider error handling
/// 
/// Provides standardized error handling for all Riverpod providers.
library;

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_error.dart';
import 'error_handler.dart';
import 'validation.dart';

/// Helper function to get school ID from providers
Future<String?> getSchoolIdFromProviders(
  Ref ref, {
  Duration waitDuration = const Duration(milliseconds: 200),
}) async {
  try {
    // Import providers dynamically to avoid circular dependencies
    // These will be passed as parameters in actual usage
    return null; // Placeholder - will be implemented in actual providers
  } catch (e) {
    debugPrint('Error getting school ID: $e');
    return null;
  }
}
