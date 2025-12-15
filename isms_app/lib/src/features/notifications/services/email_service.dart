import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/network/supabase_client.dart';

/// Email service for sending emails
/// Uses Supabase Edge Functions or external email service
class EmailService {
  SupabaseClient get _client => SupabaseManager.client;

  /// Send an email
  ///
  /// This uses Supabase Edge Functions or can be integrated with:
  /// - SendGrid
  /// - Mailgun
  /// - AWS SES
  /// - Resend
  /// - etc.
  Future<bool> sendEmail({
    required String to,
    required String subject,
    required String body,
    String? from,
    bool isHtml = false,
  }) async {
    try {
      // Option 1: Use Supabase Edge Function for email
      // This requires setting up an Edge Function that handles email sending
      final response = await _client.functions.invoke(
        'send-email',
        body: {
          'to': to,
          'subject': subject,
          'body': body,
          'from': from,
          'is_html': isHtml,
        },
      );

      // Check if function exists and succeeded
      if (response.status == 200) {
        return true;
      }

      // Option 2: If Edge Function doesn't exist, log and return false
      // In production, you should set up the Edge Function or use a direct API
      print('Email Edge Function not configured. Email would be sent to: $to');
      print('Subject: $subject');
      print('Body: $body');

      // For now, we'll create the notification record but mark it as pending
      // The actual sending will be handled by a background job or Edge Function
      return false;
    } catch (e) {
      print('Error sending email: $e');
      // In development, we might want to simulate success
      // In production, this should be handled properly
      return false;
    }
  }

  /// Send email using template
  Future<bool> sendTemplatedEmail({
    required String to,
    required String templateKey,
    required Map<String, String> variables,
    String? from,
  }) async {
    // This would typically call the template rendering service
    // and then send the email
    // For now, we'll use a simple approach
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
      final subject = template['email_subject'] as String? ?? '';
      final body = template['email_body'] as String? ?? '';

      return await sendEmail(
        to: to,
        subject: subject,
        body: body,
        from: from,
        isHtml: true,
      );
    } catch (e) {
      print('Error sending templated email: $e');
      return false;
    }
  }
}
