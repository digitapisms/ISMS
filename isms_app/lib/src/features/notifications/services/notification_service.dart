import '../data/notification_repository.dart';
import '../domain/notification.dart';
import 'email_service.dart';
import 'sms_service.dart';

/// Main notification service that coordinates email and SMS sending
class NotificationService {
  final NotificationRepository _repository;
  final EmailService _emailService;
  final SMSService _smsService;

  NotificationService({
    required NotificationRepository repository,
    EmailService? emailService,
    SMSService? smsService,
  }) : _repository = repository,
       _emailService = emailService ?? EmailService(),
       _smsService = smsService ?? SMSService();

  /// Send a notification using a template
  Future<NotificationResult> sendTemplatedNotification({
    required String templateKey,
    required String recipientEmail,
    String? recipientPhone,
    String? userId,
    required Map<String, String> variables,
  }) async {
    try {
      // Get template
      final template = await _repository.getTemplateByKey(templateKey);
      if (template == null) {
        return NotificationResult(
          success: false,
          error: 'Template not found: $templateKey',
        );
      }

      // Render template
      final rendered = await _repository.renderTemplate(
        templateKey: templateKey,
        variables: variables,
      );

      final results = <NotificationType, bool>{};

      // Send email if template has email content
      if (rendered['email_body']?.isNotEmpty == true &&
          recipientEmail.isNotEmpty) {
        // Check user preference if userId provided
        bool shouldSendEmail = true;
        if (userId != null) {
          shouldSendEmail = await _repository.isPreferenceEnabled(
            userId: userId,
            templateKey: templateKey,
            type: NotificationType.email,
          );
        }

        if (shouldSendEmail) {
          // Create notification record
          final notification = await _repository.createNotification(
            type: NotificationType.email,
            recipient: recipientEmail,
            body: rendered['email_body']!,
            userId: userId,
            templateId: template.id,
            subject: rendered['email_subject'],
            metadata: {'template_key': templateKey, 'variables': variables},
          );

          // Send email
          final emailSent = await _emailService.sendEmail(
            to: recipientEmail,
            subject: rendered['email_subject'] ?? '',
            body: rendered['email_body']!,
            isHtml: true,
          );

          // Update notification status
          await _repository.updateNotificationStatus(
            notificationId: notification.id,
            status: emailSent
                ? NotificationStatus.sent
                : NotificationStatus.failed,
            sentAt: emailSent ? DateTime.now() : null,
            errorMessage: emailSent ? null : 'Email service unavailable',
          );

          results[NotificationType.email] = emailSent;
        }
      }

      // Send SMS if template has SMS content and phone provided
      if (rendered['sms_body']?.isNotEmpty == true &&
          recipientPhone != null &&
          recipientPhone.isNotEmpty) {
        // Check user preference if userId provided
        bool shouldSendSMS = true;
        if (userId != null) {
          shouldSendSMS = await _repository.isPreferenceEnabled(
            userId: userId,
            templateKey: templateKey,
            type: NotificationType.sms,
          );
        }

        if (shouldSendSMS) {
          // Format phone number
          final formattedPhone = SMSService.formatPhoneNumber(recipientPhone);
          if (formattedPhone == null) {
            results[NotificationType.sms] = false;
          } else {
            // Create notification record
            final notification = await _repository.createNotification(
              type: NotificationType.sms,
              recipient: formattedPhone,
              body: rendered['sms_body']!,
              userId: userId,
              templateId: template.id,
              metadata: {'template_key': templateKey, 'variables': variables},
            );

            // Send SMS
            final smsSent = await _smsService.sendSMS(
              to: formattedPhone,
              message: rendered['sms_body']!,
            );

            // Update notification status
            await _repository.updateNotificationStatus(
              notificationId: notification.id,
              status: smsSent
                  ? NotificationStatus.sent
                  : NotificationStatus.failed,
              sentAt: smsSent ? DateTime.now() : null,
              errorMessage: smsSent ? null : 'SMS service unavailable',
            );

            results[NotificationType.sms] = smsSent;
          }
        }
      }

      final allSuccess = results.values.every((success) => success);
      final anySuccess = results.values.any((success) => success);

      return NotificationResult(
        success: anySuccess,
        emailSent: results[NotificationType.email] ?? false,
        smsSent: results[NotificationType.sms] ?? false,
        error: allSuccess
            ? null
            : 'Some notifications failed to send. Check notification logs.',
      );
    } catch (e) {
      return NotificationResult(
        success: false,
        error: 'Error sending notification: $e',
      );
    }
  }

  /// Send a simple notification (without template)
  Future<NotificationResult> sendNotification({
    required NotificationType type,
    required String recipient,
    required String body,
    String? userId,
    String? subject,
  }) async {
    try {
      // Create notification record
      final notification = await _repository.createNotification(
        type: type,
        recipient: recipient,
        body: body,
        userId: userId,
        subject: subject,
      );

      bool sent = false;

      // Send based on type
      switch (type) {
        case NotificationType.email:
          sent = await _emailService.sendEmail(
            to: recipient,
            subject: subject ?? '',
            body: body,
            isHtml: true,
          );
          break;
        case NotificationType.sms:
          final formattedPhone = SMSService.formatPhoneNumber(recipient);
          if (formattedPhone != null) {
            sent = await _smsService.sendSMS(to: formattedPhone, message: body);
          }
          break;
        case NotificationType.push:
        case NotificationType.inApp:
          // Push and in-app notifications handled separately
          sent = true; // Mark as sent for now
          break;
      }

      // Update notification status
      await _repository.updateNotificationStatus(
        notificationId: notification.id,
        status: sent ? NotificationStatus.sent : NotificationStatus.failed,
        sentAt: sent ? DateTime.now() : null,
        errorMessage: sent ? null : 'Notification service unavailable',
      );

      return NotificationResult(
        success: sent,
        emailSent: type == NotificationType.email ? sent : false,
        smsSent: type == NotificationType.sms ? sent : false,
      );
    } catch (e) {
      return NotificationResult(
        success: false,
        error: 'Error sending notification: $e',
      );
    }
  }
}

/// Result of a notification send operation
class NotificationResult {
  const NotificationResult({
    required this.success,
    this.emailSent = false,
    this.smsSent = false,
    this.error,
  });

  final bool success;
  final bool emailSent;
  final bool smsSent;
  final String? error;
}
