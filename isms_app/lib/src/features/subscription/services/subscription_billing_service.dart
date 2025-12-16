import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isms_app/src/core/network/supabase_client.dart';
import 'package:isms_app/src/features/subscription/data/subscription_repository.dart';
import 'package:isms_app/src/features/payments/services/payment_gateway_service.dart';
import 'package:isms_app/src/core/notifications/email_notification_service.dart';

class SubscriptionBillingService {
  final SubscriptionRepository _repository;
  final PaymentGatewayService? _paymentService;
  final EmailNotificationService? _emailService;

  SubscriptionBillingService(
    this._repository,
    this._paymentService,
    this._emailService,
  );

  /// Process daily subscription billing (to be called by a cron job)
  Future<Map<String, dynamic>> processDailyBilling() async {
    final results = {
      'invoices_generated': 0,
      'payments_processed': 0,
      'reminders_sent': 0,
      'subscriptions_renewed': 0,
      'errors': [],
    };

    try {
      // 1. Process subscriptions due for billing today
      final dueSubscriptions = await _getSubscriptionsDueForBilling();

      for (final subscription in dueSubscriptions) {
        try {
          // Generate invoice
          final invoiceId = await _generateSubscriptionInvoice(subscription);
          results['invoices_generated']++;

          // Attempt payment processing based on payment method
          if (subscription['payment_method'] != null) {
            final paymentMethod = subscription['payment_method'] as String;

            if (paymentMethod == 'cash') {
              // Handle cash payments - mark invoice as pending cash payment
              await _handleCashPayment(subscription, invoiceId);
              results['payments_processed']++; // Count as processed for reporting
            } else if (_paymentService != null) {
              // Handle automatic online payments
              final paymentResult = await _processAutomaticPayment(
                subscription,
                invoiceId,
              );

              if (paymentResult['success'] == true) {
                results['payments_processed']++;
                results['subscriptions_renewed']++;
              }
            }
          }

          // Send invoice notification
          await _sendInvoiceNotification(subscription, invoiceId);
          results['reminders_sent']++;
        } catch (e) {
          results['errors'].add({
            'subscription_id': subscription['id'],
            'error': e.toString(),
          });
        }
      }

      // 2. Send renewal reminders (7 days before expiration)
      final expiringSubscriptions = await _getExpiringSubscriptions();
      for (final subscription in expiringSubscriptions) {
        await _sendRenewalReminder(subscription);
        results['reminders_sent']++;
      }

      // 3. Process overdue invoices
      await _processOverdueInvoices();

      // 4. Suspend services for non-payment
      await _suspendServicesForNonPayment();
    } catch (e) {
      results['errors'].add({'process_error': e.toString()});
    }

    return results;
  }

  /// Generate subscription invoice
  Future<String> _generateSubscriptionInvoice(
    Map<String, dynamic> subscription,
  ) async {
    final plan = await _repository.getPlanById(subscription['plan_id']);
    final amount = _calculateInvoiceAmount(plan, subscription['billing_cycle']);

    final response = await SupabaseManager.client
        .from('school_invoices')
        .insert({
          'subscription_id': subscription['id'],
          'school_id': subscription['school_id'],
          'invoice_number': await _generateInvoiceNumber(),
          'issue_date': DateTime.now().toIso8601String(),
          'due_date': DateTime.now()
              .add(const Duration(days: 15))
              .toIso8601String(),
          'period_start': subscription['start_date'],
          'period_end': subscription['end_date'],
          'subtotal': amount,
          'total_amount': amount,
          'currency': plan.currency ?? 'PKR',
          'status': 'unpaid',
        })
        .select('id')
        .single();

    return response['id'] as String;
  }

  /// Process automatic payment for subscription
  Future<Map<String, dynamic>> _processAutomaticPayment(
    Map<String, dynamic> subscription,
    String invoiceId,
  ) async {
    final plan = await _repository.getPlanById(subscription['plan_id']);
    final amount = _calculateInvoiceAmount(plan, subscription['billing_cycle']);

    try {
      if (_paymentService == null) {
        throw Exception('Payment service not available');
      }
      final paymentResult = await _paymentService.createPaymentIntent(
        amount: amount,
        currency: plan.currency ?? 'PKR',
        reference: 'subscription_${subscription['id']}',
        customerEmail: subscription['admin_email'],
        metadata: {
          'subscription_id': subscription['id'],
          'invoice_id': invoiceId,
          'school_id': subscription['school_id'],
          'billing_cycle': subscription['billing_cycle'],
        },
        isSubscription: true,
      );

      if (paymentResult['success'] == true) {
        // Update subscription with new dates
        await _renewSubscription(
          subscription['id'],
          subscription['billing_cycle'],
        );

        // Update invoice status
        await SupabaseManager.client
            .from('school_invoices')
            .update({
              'status': 'paid',
              'paid_at': DateTime.now().toIso8601String(),
              'payment_method': subscription['payment_method'],
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', invoiceId);

        return {
          'success': true,
          'transaction_id': paymentResult['transaction_id'],
        };
      }

      return {'success': false, 'error': paymentResult['error']};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Handle cash payment for subscription
  Future<void> _handleCashPayment(
    Map<String, dynamic> subscription,
    String invoiceId,
  ) async {
    try {
      // Update invoice status to pending_cash
      await SupabaseManager.client
          .from('school_invoices')
          .update({
            'status': 'pending_cash',
            'payment_method': 'cash',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', invoiceId);

      // Send cash collection notification
      await _sendCashCollectionNotification(subscription, invoiceId);
    } catch (e) {
      // Log error but don't fail the entire process
      print('Error handling cash payment: \$e');
    }
  }

  /// Renew subscription period
  Future<void> _renewSubscription(
    String subscriptionId,
    String billingCycle,
  ) async {
    final currentDate = DateTime.now();
    final endDate = _calculateEndDate(currentDate, billingCycle);

    await SupabaseManager.client
        .from('school_subscriptions')
        .update({
          'start_date': currentDate.toIso8601String(),
          'end_date': endDate.toIso8601String(),
          'next_billing_date': endDate
              .add(const Duration(days: 1))
              .toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', subscriptionId);
  }

  /// Send invoice notification
  Future<void> _sendInvoiceNotification(
    Map<String, dynamic> subscription,
    String invoiceId,
  ) async {
    final plan = await _repository.getPlanById(subscription['plan_id']);
    final amount = _calculateInvoiceAmount(plan, subscription['billing_cycle']);

    await _emailService.notifySubscriptionInvoice(
      recipientEmail: subscription['admin_email'],
      recipientName: subscription['school_name'],
      invoiceNumber: await _generateInvoiceNumber(),
      amount: amount,
      dueDate: DateTime.now().add(const Duration(days: 15)),
      planName: plan.name,
      billingCycle: subscription['billing_cycle'],
    );
  }

  /// Send renewal reminder
  Future<void> _sendRenewalReminder(Map<String, dynamic> subscription) async {
    await _emailService.notifySubscriptionRenewal(
      recipientEmail: subscription['admin_email'],
      recipientName: subscription['school_name'],
      planName: subscription['plan_name'],
      expirationDate: DateTime.parse(subscription['end_date']),
      autoRenew: subscription['auto_renew'] ?? false,
    );
  }

  /// Send cash collection notification
  Future<void> _sendCashCollectionNotification(
    Map<String, dynamic> subscription,
    String invoiceId,
  ) async {
    final plan = await _repository.getPlanById(subscription['plan_id']);
    final amount = _calculateInvoiceAmount(plan, subscription['billing_cycle']);

    await _emailService.notifyCashPaymentRequired(
      recipientEmail: subscription['admin_email'],
      recipientName: subscription['school_name'],
      invoiceNumber: await _generateInvoiceNumber(),
      amount: amount,
      dueDate: DateTime.now().add(const Duration(days: 15)),
      planName: plan.name,
      billingCycle: subscription['billing_cycle'],
      schoolName: subscription['school_name'],
    );
  }

  /// Process overdue invoices
  Future<void> _processOverdueInvoices() async {
    final overdueInvoices = await SupabaseManager.client
        .from('school_invoices')
        .select('')
        .eq('status', 'unpaid')
        .lt('due_date', DateTime.now().toIso8601String());

    for (final invoice in overdueInvoices ?? []) {
      await SupabaseManager.client
          .from('school_invoices')
          .update({
            'status': 'overdue',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', invoice['id']);

      // Send overdue notification
      final school = await SupabaseManager.client
          .from('schools')
          .select('name, admin_email')
          .eq('id', invoice['school_id'])
          .single();

      await _emailService.notifyPaymentOverdue(
        recipientEmail: school['admin_email'],
        recipientName: school['name'],
        invoiceNumber: invoice['invoice_number'],
        amount: invoice['total_amount'],
        dueDate: DateTime.parse(invoice['due_date']),
      );
    }
  }

  /// Suspend services for non-payment
  Future<void> _suspendServicesForNonPayment() async {
    final overdueInvoices = await SupabaseManager.client
        .from('school_invoices')
        .select('school_id')
        .eq('status', 'overdue')
        .lt(
          'due_date',
          DateTime.now().subtract(const Duration(days: 30)).toIso8601String(),
        );

    for (final invoice in overdueInvoices ?? []) {
      await SupabaseManager.client
          .from('schools')
          .update({
            'status': 'suspended',
            'suspension_reason': 'non_payment',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', invoice['school_id']);

      // Send suspension notification
      final school = await SupabaseManager.client
          .from('schools')
          .select('name, admin_email')
          .eq('id', invoice['school_id'])
          .single();

      await _emailService.notifyServiceSuspended(
        recipientEmail: school['admin_email'],
        recipientName: school['name'],
        reason: 'non_payment',
      );
    }
  }

  // Helper methods
  Future<List<Map<String, dynamic>>> _getSubscriptionsDueForBilling() async {
    final response = await SupabaseManager.client
        .from('school_subscriptions')
        .select('')
        .eq('status', 'active')
        .eq('auto_renew', true)
        .lte('next_billing_date', DateTime.now().toIso8601String());

    return (response ?? []).cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> _getExpiringSubscriptions() async {
    final sevenDaysFromNow = DateTime.now().add(const Duration(days: 7));

    final response = await SupabaseManager.client
        .from('school_subscriptions')
        .select('')
        .eq('status', 'active')
        .lte('end_date', sevenDaysFromNow.toIso8601String());

    return (response ?? []).cast<Map<String, dynamic>>();
  }

  double _calculateInvoiceAmount(SubscriptionPlan plan, String billingCycle) {
    switch (billingCycle) {
      case 'monthly':
        return plan.pricePerMonth;
      case 'quarterly':
        return plan.pricePerQuarter ?? plan.pricePerMonth * 3;
      case 'half_yearly':
        return plan.pricePerHalfYear ?? plan.pricePerMonth * 6;
      case 'yearly':
        return plan.pricePerYear ?? plan.pricePerMonth * 12;
      default:
        return plan.pricePerMonth;
    }
  }

  DateTime _calculateEndDate(DateTime startDate, String billingCycle) {
    switch (billingCycle) {
      case 'monthly':
        return DateTime(startDate.year, startDate.month + 1, startDate.day);
      case 'quarterly':
        return DateTime(startDate.year, startDate.month + 3, startDate.day);
      case 'half_yearly':
        return DateTime(startDate.year, startDate.month + 6, startDate.day);
      case 'yearly':
        return DateTime(startDate.year + 1, startDate.month, startDate.day);
      default:
        return startDate.add(const Duration(days: 30));
    }
  }

  Future<String> _generateInvoiceNumber() async {
    final response = await SupabaseManager.client
        .from('school_invoices')
        .select('invoice_number')
        .order('created_at', ascending: false)
        .limit(1)
        .single();

    final lastNumber = int.parse(
      (response['invoice_number'] as String).split('-').last,
    );
    return 'INV-${(lastNumber + 1).toString().padLeft(6, '0')}';
  }
}

// Riverpod provider
final subscriptionBillingServiceProvider = Provider<SubscriptionBillingService>(
  (ref) {
    final repository = ref.read(subscriptionRepositoryProvider);
    // TODO: Add missing providers when available
    // final paymentService = ref.read(paymentGatewayServiceProvider);
    // final emailService = ref.read(emailNotificationServiceProvider);
    return SubscriptionBillingService(repository, null, null);
  },
);
