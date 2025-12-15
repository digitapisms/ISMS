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
        'metadata': {'application_id': applicationId, 'status': status},
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
        'body': _getPaymentConfirmationBody(
          recipientName,
          transactionId,
          amount,
        ),
        'status': 'pending',
        'metadata': {'transaction_id': transactionId, 'amount': amount},
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
        buffer.writeln(
          'Congratulations! Your student application has been approved.',
        );
        buffer.writeln();
        buffer.writeln(
          'Please contact the school administration to complete the enrollment process.',
        );
        break;
      case 'rejected':
        buffer.writeln(
          'We regret to inform you that your application has been rejected.',
        );
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

  String _getPaymentConfirmationBody(
    String name,
    String transactionId,
    double amount,
  ) {
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

  /// Send subscription invoice notification
  Future<void> notifySubscriptionInvoice({
    required String recipientEmail,
    required String recipientName,
    required String invoiceNumber,
    required double amount,
    required DateTime dueDate,
    required String planName,
    required String billingCycle,
  }) async {
    try {
      await _client.from('notifications').insert({
        'type': 'subscription_invoice',
        'recipient_email': recipientEmail,
        'recipient_name': recipientName,
        'subject': 'New Subscription Invoice - $invoiceNumber',
        'body': _getSubscriptionInvoiceBody(
          recipientName,
          invoiceNumber,
          amount,
          dueDate,
          planName,
          billingCycle,
        ),
        'status': 'pending',
        'metadata': {
          'invoice_number': invoiceNumber,
          'amount': amount,
          'due_date': dueDate.toIso8601String(),
          'plan_name': planName,
          'billing_cycle': billingCycle,
        },
      });
    } catch (e) {
      print('Failed to send subscription invoice notification: $e');
    }
  }

  /// Send subscription renewal reminder
  Future<void> notifySubscriptionRenewal({
    required String recipientEmail,
    required String recipientName,
    required String planName,
    required DateTime expirationDate,
    required bool autoRenew,
  }) async {
    try {
      await _client.from('notifications').insert({
        'type': 'subscription_renewal',
        'recipient_email': recipientEmail,
        'recipient_name': recipientName,
        'subject': 'Subscription Renewal Reminder - $planName',
        'body': _getSubscriptionRenewalBody(
          recipientName,
          planName,
          expirationDate,
          autoRenew,
        ),
        'status': 'pending',
        'metadata': {
          'plan_name': planName,
          'expiration_date': expirationDate.toIso8601String(),
          'auto_renew': autoRenew,
        },
      });
    } catch (e) {
      print('Failed to send subscription renewal notification: $e');
    }
  }

  /// Send payment overdue notification
  Future<void> notifyPaymentOverdue({
    required String recipientEmail,
    required String recipientName,
    required String invoiceNumber,
    required double amount,
    required DateTime dueDate,
  }) async {
    try {
      await _client.from('notifications').insert({
        'type': 'payment_overdue',
        'recipient_email': recipientEmail,
        'recipient_name': recipientName,
        'subject': 'Payment Overdue - Invoice $invoiceNumber',
        'body': _getPaymentOverdueBody(
          recipientName,
          invoiceNumber,
          amount,
          dueDate,
        ),
        'status': 'pending',
        'metadata': {
          'invoice_number': invoiceNumber,
          'amount': amount,
          'due_date': dueDate.toIso8601String(),
        },
      });
    } catch (e) {
      print('Failed to send payment overdue notification: $e');
    }
  }

  /// Send service suspension notification
  Future<void> notifyServiceSuspended({
    required String recipientEmail,
    required String recipientName,
    required String reason,
  }) async {
    try {
      await _client.from('notifications').insert({
        'type': 'service_suspended',
        'recipient_email': recipientEmail,
        'recipient_name': recipientName,
        'subject': 'Service Suspended - $reason',
        'body': _getServiceSuspendedBody(recipientName, reason),
        'status': 'pending',
        'metadata': {'reason': reason},
      });
    } catch (e) {
      print('Failed to send service suspension notification: $e');
    }
  }

  /// Send cash payment required notification
  Future<void> notifyCashPaymentRequired({
    required String recipientEmail,
    required String recipientName,
    required String invoiceNumber,
    required double amount,
    required DateTime dueDate,
    required String planName,
    required String billingCycle,
    required String schoolName,
  }) async {
    try {
      await _client.from('notifications').insert({
        'type': 'cash_payment_required',
        'recipient_email': recipientEmail,
        'recipient_name': recipientName,
        'subject': 'Cash Payment Required - Invoice \$invoiceNumber',
        'body': _getCashPaymentRequiredBody(
          recipientName,
          invoiceNumber,
          amount,
          dueDate,
          planName,
          billingCycle,
          schoolName,
        ),
        'status': 'pending',
        'metadata': {
          'invoice_number': invoiceNumber,
          'amount': amount,
          'due_date': dueDate.toIso8601String(),
          'plan_name': planName,
          'billing_cycle': billingCycle,
          'school_name': schoolName,
        },
      });
    } catch (e) {
      print('Failed to send cash payment required notification: \$e');
    }
  }

  String _getSubscriptionInvoiceBody(
    String name,
    String invoiceNumber,
    double amount,
    DateTime dueDate,
    String planName,
    String billingCycle,
  ) {
    return '''
Dear $name,

A new invoice has been generated for your subscription.

Invoice Number: $invoiceNumber
Plan: $planName ($billingCycle)
Amount Due: ₹${amount.toStringAsFixed(2)}
Due Date: ${dueDate.toString().split(' ')[0]}

Please make the payment by the due date to avoid service interruption.

Best regards,
ISMS Administration
''';
  }

  String _getSubscriptionRenewalBody(
    String name,
    String planName,
    DateTime expirationDate,
    bool autoRenew,
  ) {
    return '''
Dear $name,

Your subscription to $planName will expire on ${expirationDate.toString().split(' ')[0]}.

Auto-renewal: ${autoRenew ? 'Enabled' : 'Disabled'}

${autoRenew ? 'Your subscription will automatically renew unless you cancel it before the expiration date.' : 'Please renew your subscription to continue using our services.'}

Best regards,
ISMS Administration
''';
  }

  String _getPaymentOverdueBody(
    String name,
    String invoiceNumber,
    double amount,
    DateTime dueDate,
  ) {
    return '''
Dear $name,

Your payment for invoice $invoiceNumber is overdue.

Amount Due: ₹${amount.toStringAsFixed(2)}
Original Due Date: ${dueDate.toString().split(' ')[0]}

Please make the payment immediately to avoid service suspension.

Best regards,
ISMS Administration
''';
  }

  String _getServiceSuspendedBody(String name, String reason) {
    return '''
Dear $name,

Your ISMS services have been suspended due to: $reason.

To restore your services, please clear any outstanding payments and contact our support team.

Best regards,
ISMS Administration
''';
  }

  String _getCashPaymentRequiredBody(
    String name,
    String invoiceNumber,
    double amount,
    DateTime dueDate,
    String planName,
    String billingCycle,
    String schoolName,
  ) {
    return '''
Dear \$name,

A cash payment is required for your subscription at \$schoolName.

Invoice Number: \$invoiceNumber
Plan: \$planName (\$billingCycle)
Amount Due: ₹\${amount.toStringAsFixed(2)}
Due Date: \${dueDate.toString().split(' ')[0]}

Please visit your school administration office to make the cash payment by the due date to avoid service interruption.

Best regards,
ISMS Administration
''';
  }
}
