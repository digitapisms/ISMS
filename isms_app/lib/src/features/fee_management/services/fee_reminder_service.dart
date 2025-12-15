import '../../notifications/domain/notification.dart';
import '../../notifications/services/notification_service.dart';
import '../../notifications/data/notification_repository.dart';
import '../../student_management/domain/student.dart';
import '../domain/fee_invoice.dart';
import '../domain/invoice_status.dart';
import '../../../core/network/supabase_client.dart';

class FeeReminderService {
  /// Send fee due reminders for overdue invoices
  static Future<void> sendOverdueReminders({
    required String schoolId,
    required List<FeeInvoice> overdueInvoices,
    required Map<String, Student> studentsMap,
  }) async {
    final notificationRepo = NotificationRepository();
    notificationRepo.setSchoolId(schoolId);
    final notificationService = NotificationService(
      repository: notificationRepo,
    );
    final client = SupabaseManager.client;

    for (final invoice in overdueInvoices) {
      final student = studentsMap[invoice.studentId];
      if (student == null) continue;

      // Get student's parent/guardian email/phone from users table
      // For now, we'll use in-app notifications
      try {
        // Get user ID for student (if exists)
        final userResponse = await client
            .from('users')
            .select('id, email')
            .eq('student_id', student.id)
            .maybeSingle();

        final userId = userResponse?['id'] as String?;
        final email = userResponse?['email'] as String?;

        if (email != null) {
          await notificationService.sendNotification(
            type: NotificationType.email,
            recipient: email,
            body:
                'Dear ${student.fullName},\n\nYour fee invoice ${invoice.invoiceNumber} '
                'for PKR ${invoice.outstandingAmount.toStringAsFixed(2)} is overdue. '
                'Please make the payment at your earliest convenience.\n\n'
                'Due Date: ${invoice.dueDate.toString().split(' ')[0]}\n'
                'Thank you.',
            userId: userId,
            subject: 'Fee Payment Reminder - Overdue',
          );
        }

        // Also send in-app notification
        if (userId != null) {
          await notificationService.sendNotification(
            type: NotificationType.inApp,
            recipient: userId,
            body:
                'Fee invoice ${invoice.invoiceNumber} for PKR ${invoice.outstandingAmount.toStringAsFixed(2)} is overdue.',
            userId: userId,
            subject: 'Fee Payment Reminder',
          );
        }
      } catch (e) {
        // Log error but continue with other reminders
        print('Error sending reminder for invoice ${invoice.id}: $e');
      }
    }
  }

  /// Send upcoming due date reminders (e.g., 3 days before due date)
  static Future<void> sendUpcomingDueReminders({
    required String schoolId,
    required List<FeeInvoice> upcomingInvoices,
    required Map<String, Student> studentsMap,
    int daysBefore = 3,
  }) async {
    final notificationRepo = NotificationRepository();
    notificationRepo.setSchoolId(schoolId);
    final notificationService = NotificationService(
      repository: notificationRepo,
    );
    final client = SupabaseManager.client;
    final today = DateTime.now();
    final reminderDate = today.add(Duration(days: daysBefore));

    for (final invoice in upcomingInvoices) {
      // Check if due date is within reminder window
      if (invoice.dueDate.isAfter(reminderDate) ||
          invoice.dueDate.isBefore(today)) {
        continue;
      }

      final student = studentsMap[invoice.studentId];
      if (student == null) continue;

      try {
        final userResponse = await client
            .from('users')
            .select('id, email')
            .eq('student_id', student.id)
            .maybeSingle();

        final userId = userResponse?['id'] as String?;
        final email = userResponse?['email'] as String?;

        if (email != null) {
          await notificationService.sendNotification(
            type: NotificationType.email,
            recipient: email,
            body:
                'Dear ${student.fullName},\n\nThis is a reminder that your fee invoice '
                '${invoice.invoiceNumber} for PKR ${invoice.outstandingAmount.toStringAsFixed(2)} '
                'is due on ${invoice.dueDate.toString().split(' ')[0]}.\n\n'
                'Please ensure payment is made before the due date.\n\nThank you.',
            userId: userId,
            subject: 'Fee Payment Reminder',
          );
        }

        if (userId != null) {
          await notificationService.sendNotification(
            type: NotificationType.inApp,
            recipient: userId,
            body:
                'Fee invoice ${invoice.invoiceNumber} for PKR ${invoice.outstandingAmount.toStringAsFixed(2)} '
                'is due on ${invoice.dueDate.toString().split(' ')[0]}.',
            userId: userId,
            subject: 'Fee Payment Reminder',
          );
        }
      } catch (e) {
        print('Error sending upcoming reminder for invoice ${invoice.id}: $e');
      }
    }
  }

  /// Get invoices that need reminders
  static List<FeeInvoice> getOverdueInvoices(List<FeeInvoice> invoices) {
    final today = DateTime.now();
    return invoices.where((invoice) {
      return invoice.dueDate.isBefore(today) &&
          invoice.status != InvoiceStatus.paid &&
          invoice.status != InvoiceStatus.cancelled;
    }).toList();
  }

  static List<FeeInvoice> getUpcomingDueInvoices(
    List<FeeInvoice> invoices, {
    int daysBefore = 3,
  }) {
    final today = DateTime.now();
    final reminderDate = today.add(Duration(days: daysBefore));
    return invoices.where((invoice) {
      return invoice.dueDate.isAfter(today) &&
          invoice.dueDate.isBefore(reminderDate) &&
          invoice.status != InvoiceStatus.paid &&
          invoice.status != InvoiceStatus.cancelled;
    }).toList();
  }
}
