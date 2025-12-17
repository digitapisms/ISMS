import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/network/supabase_client.dart';

/// SMS service for sending SMS messages
/// Can be integrated with:
/// - AWS SNS
/// - MessageBird
/// - Vonage (Nexmo)
/// - etc.
class SMSService {
  SupabaseClient get _client => SupabaseManager.client;

  /// Send an SMS
  ///
  /// Phone number should be in E.164 format (e.g., +1234567890)
  Future<bool> sendSMS({
    required String to,
    required String message,
    String? from,
  }) async {
    try {
      // Option 1: Use Supabase Edge Function for SMS
      // This requires setting up an Edge Function that handles SMS sending
      final response = await _client.functions.invoke(
        'send-sms',
        body: {'to': to, 'message': message, 'from': from},
      );

      // Check if function exists and succeeded
      if (response.status == 200) {
        return true;
      }

      // Option 2: If Edge Function doesn't exist, log and return false
      // In production, you should set up the Edge Function or use a direct API
      print('SMS Edge Function not configured. SMS would be sent to: $to');
      print('Message: $message');

      // For now, we'll create the notification record but mark it as pending
      // The actual sending will be handled by a background job or Edge Function
      return false;
    } catch (e) {
      print('Error sending SMS: $e');
      // In development, we might want to simulate success
      // In production, this should be handled properly
      return false;
    }
  }

  /// Send SMS using template
  Future<bool> sendTemplatedSMS({
    required String to,
    required String templateKey,
    required Map<String, String> variables,
    String? from,
  }) async {
    try {
      // Get template and render it
      final templateResult = await _client.rpc(
        'render_notification_template',
        params: {'p_template_key': templateKey, 'p_variables': variables},
      );

      if (templateResult == null) {
        throw Exception('Template not found or rendering failed');
      }

      final template = templateResult as Map<String, dynamic>;
      final message = template['sms_body'] as String? ?? '';

      return await sendSMS(to: to, message: message, from: from);
    } catch (e) {
      print('Error sending templated SMS: $e');
      return false;
    }
  }

  /// Validate phone number format
  /// Returns true if valid E.164 format
  static bool isValidPhoneNumber(String phone) {
    // Basic E.164 format validation
    // Should start with + and contain only digits after that
    final regex = RegExp(r'^\+[1-9]\d{1,14}$');
    return regex.hasMatch(phone);
  }

  /// Format phone number to E.164
  /// Attempts to convert various formats to E.164
  static String? formatPhoneNumber(String phone) {
    // Remove all non-digit characters except +
    String cleaned = phone.replaceAll(RegExp(r'[^\d+]'), '');

    // If doesn't start with +, assume it needs country code
    // For Pakistan, default to +92
    if (!cleaned.startsWith('+')) {
      // Remove leading zeros
      cleaned = cleaned.replaceFirst(RegExp(r'^0+'), '');
      cleaned = '+92$cleaned'; // Default to Pakistan
    }

    // Validate
    if (isValidPhoneNumber(cleaned)) {
      return cleaned;
    }

    return null;
  }
}
