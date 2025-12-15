import 'package:supabase_flutter/supabase_flutter.dart';

import '../network/supabase_client.dart';

class EmailNotificationService {
  SupabaseClient get _client => SupabaseManager.client;

  /// Send email notification when application status changes
  Future<void> notifyApplicationStatusChange({
    required String recipientEmail,
    required String recipientName,
    required String applicationId,
    required String status,
    String? remarks,
  }) async {
    try {
      // In production, you would integrate with an email service like:
      // - SendGrid
      // - AWS SES
      // - Mailgun
      // - Supabase Edge Functions with email service
      
      // For now, we'll use Supabase Edge Functions or create a notification record
      // that can be processed by a background job
      
      await _client.from('notifications').insert({
        'type': 'application_status_change',
        'recipient_email': recipientEmail,
        'recipient_name': recipientName,
        'subject': _getSubjectForStatus(status),
        'body': _getBodyForStatus(recipientName, status, remarks),
        'status': 'pending',
        'metadata': {
          'application_id': applicationId,
          'status': status,
        },
      });

      // In production, trigger an Edge Function or webhook here
      // Example: await _client.functions.invoke('send-email', body: {...});
    } catch (e) {
      // Log error but don't fail the operation
      print('Failed to send email notification: $e');
    }
  }

  /// Send payment confirmation email
  Future<void> notifyPaymentConfirmation({
    required String recipientEmail,
    required String recipientName,
    required String transactionId,
    required double amount,
  }) async {
    try {
      await _client.from('notifications').insert({
        'type': 'payment_confirmation',
        'recipient_email': recipientEmail,
        'recipient_name': recipientName,
        'subject': 'Payment Confirmation - Application Fee',
        'body': _getPaymentConfirmationBody(recipientName, transactionId, amount),
        'status': 'pending',
        'metadata': {
          'transaction_id': transactionId,
          'amount': amount,
        },
      });
    } catch (e) {
      print('Failed to send payment confirmation email: $e');
    }
  }

  String _getSubjectForStatus(String status) {
    switch (status) {
      case 'approved':
        return 'Application Approved - Welcome to ISMS';
      case 'rejected':
        return 'Application Status Update';
      case 'under_review':
        return 'Application Under Review';
      default:
        return 'Application Status Update';
    }
  }

  String _getBodyForStatus(String name, String status, String? remarks) {
    final buffer = StringBuffer();
    buffer.writeln('Dear $name,');
    buffer.writeln();
    
    switch (status) {
      case 'approved':
        buffer.writeln('Congratulations! Your student application has been approved.');
        buffer.writeln();
        buffer.writeln('Please contact the school administration to complete the enrollment process.');
        break;
      case 'rejected':
        buffer.writeln('We regret to inform you that your application has been rejected.');
        if (remarks != null && remarks.isNotEmpty) {
          buffer.writeln();
          buffer.writeln('Remarks: $remarks');
        }
        break;
      case 'under_review':
        buffer.writeln('Your application is currently under review.');
        buffer.writeln('We will notify you once a decision has been made.');
        break;
      default:
        buffer.writeln('Your application status has been updated to: $status');
    }
    
    buffer.writeln();
    buffer.writeln('Thank you for your interest in our school.');
    buffer.writeln();
    buffer.writeln('Best regards,');
    buffer.writeln('ISMS Administration');
    
    return buffer.toString();
  }

  String _getPaymentConfirmationBody(String name, String transactionId, double amount) {
    return '''
Dear $name,

Your payment has been successfully processed.

Transaction ID: $transactionId
Amount: ₹${amount.toStringAsFixed(2)}

Thank you for your payment.

Best regards,
ISMS Administration
''';
  }
}

