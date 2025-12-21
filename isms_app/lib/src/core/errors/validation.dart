/// Input validation utilities
/// 
/// Provides validation functions for common input types and patterns.
library;

import 'app_error.dart';

/// Validation utilities
class Validation {
  /// Validate email format
  static ValidationError? validateEmail(String? email) {
    if (email == null || email.trim().isEmpty) {
      return ValidationError.missingField('email');
    }

    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    if (!emailRegex.hasMatch(email.trim())) {
      return ValidationError.invalidFormat('email', 'valid email address');
    }

    return null;
  }

  /// Validate phone number (Pakistani format)
  static ValidationError? validatePhone(String? phone) {
    if (phone == null || phone.trim().isEmpty) {
      return ValidationError.missingField('phone');
    }

    // Remove spaces and dashes
    final cleaned = phone.replaceAll(RegExp(r'[\s-]'), '');

    // Pakistani phone: 03XX-XXXXXXX or +923XXXXXXXXX
    final phoneRegex = RegExp(r'^(\+92|0)?3\d{9}$');

    if (!phoneRegex.hasMatch(cleaned)) {
      return ValidationError.invalidFormat(
        'phone',
        'Pakistani phone number (03XX-XXXXXXX)',
      );
    }

    return null;
  }

  /// Validate required field
  static ValidationError? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return ValidationError.missingField(fieldName);
    }
    return null;
  }

  /// Validate string length
  static ValidationError? validateLength(
    String? value,
    String fieldName, {
    int? min,
    int? max,
  }) {
    if (value == null) {
      return ValidationError.missingField(fieldName);
    }

    final length = value.length;

    if (min != null && length < min) {
      return ValidationError(
        message: 'Field $fieldName must be at least $min characters',
        userMessage: 'Please enter at least $min characters for $fieldName.',
        field: fieldName,
      );
    }

    if (max != null && length > max) {
      return ValidationError(
        message: 'Field $fieldName must be at most $max characters',
        userMessage: 'Please enter at most $max characters for $fieldName.',
        field: fieldName,
      );
    }

    return null;
  }

  /// Validate numeric range
  static ValidationError? validateRange(
    num? value,
    String fieldName, {
    required num min,
    required num max,
  }) {
    if (value == null) {
      return ValidationError.missingField(fieldName);
    }

    if (value < min || value > max) {
      return ValidationError.outOfRange(
        fieldName,
        min: min,
        max: max,
      );
    }

    return null;
  }

  /// Validate date range
  static ValidationError? validateDateRange({
    required DateTime? startDate,
    required DateTime? endDate,
    String? fieldName,
  }) {
    if (startDate == null || endDate == null) {
      return ValidationError.missingField(fieldName ?? 'date range');
    }

    if (endDate.isBefore(startDate)) {
      return ValidationError(
        message: 'End date must be after start date',
        userMessage: 'Please select a valid date range.',
        field: fieldName,
      );
    }

    return null;
  }

  /// Validate UUID format
  static ValidationError? validateUuid(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return ValidationError.missingField(fieldName);
    }

    final uuidRegex = RegExp(
      r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
      caseSensitive: false,
    );

    if (!uuidRegex.hasMatch(value.trim())) {
      return ValidationError.invalidFormat(fieldName, 'valid UUID');
    }

    return null;
  }

  /// Validate CNIC/B-Form (Pakistani format)
  static ValidationError? validateCnic(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return null; // Optional field
    }

    // Remove dashes
    final cleaned = value.replaceAll('-', '');

    // CNIC: 13 digits, B-Form: 13 digits
    if (cleaned.length != 13 || !RegExp(r'^\d+$').hasMatch(cleaned)) {
      return ValidationError.invalidFormat(
        fieldName,
        '13-digit CNIC/B-Form number',
      );
    }

    return null;
  }

  /// Validate password strength
  static ValidationError? validatePassword(String? password) {
    if (password == null || password.isEmpty) {
      return ValidationError.missingField('password');
    }

    if (password.length < 8) {
      return ValidationError(
        message: 'Password must be at least 8 characters',
        userMessage: 'Password must be at least 8 characters long.',
        field: 'password',
      );
    }

    // Check for at least one number
    if (!RegExp(r'\d').hasMatch(password)) {
      return ValidationError(
        message: 'Password must contain at least one number',
        userMessage: 'Password must contain at least one number.',
        field: 'password',
      );
    }

    return null;
  }

  /// Validate non-empty list
  static ValidationError? validateNonEmpty<T>(
    List<T>? list,
    String fieldName,
  ) {
    if (list == null || list.isEmpty) {
      return ValidationError(
        message: 'List $fieldName cannot be empty',
        userMessage: 'Please provide at least one item for $fieldName.',
        field: fieldName,
      );
    }
    return null;
  }

  /// Validate and sanitize string input
  static String? sanitizeString(String? value) {
    if (value == null) return null;
    return value.trim().isEmpty ? null : value.trim();
  }

  /// Validate and sanitize email
  static String? sanitizeEmail(String? value) {
    final sanitized = sanitizeString(value);
    if (sanitized == null) return null;
    return sanitized.toLowerCase();
  }
}
