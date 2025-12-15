import 'package:isms_app/src/core/network/supabase_client.dart';
import 'package:isms_app/src/features/institution/application/institution_config_loader.dart';
import 'package:isms_app/src/features/subscription/data/subscription_repository.dart';
import 'package:isms_app/src/features/subscription/domain/subscription_plan.dart';

class SubscriptionBillingEngine {
  final SubscriptionRepository _repository;
  final InstitutionConfigLoader _configLoader;

  SubscriptionBillingEngine(this._repository, this._configLoader);

  /// Get all available subscription plans with institution-specific pricing
  Future<List<SubscriptionPlan>> getAvailablePlans({
    String? institutionType,
  }) async {
    // Currently, pricing is not varied by institution type.
    // Return all active public plans from repository.
    return _repository.getAllPlans();
  }

  /// Create a new subscription for a school
  Future<void> createSchoolSubscription({
    required String schoolId,
    required String planId,
    required String billingCycle,
    required DateTime startDate,
    bool autoRenew = true,
  }) async {
    // Calculate end date based on billing cycle
    final endDate = _calculateEndDate(startDate, billingCycle);

    await SupabaseManager.client.from('school_subscriptions').insert({
      'school_id': schoolId,
      'plan_id': planId,
      'billing_cycle': billingCycle,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'auto_renew': autoRenew,
      'status': 'active',
      'next_billing_date': endDate
          .add(const Duration(days: 1))
          .toIso8601String(),
    });
  }

  /// Generate invoice for a subscription
  Future<void> generateSubscriptionInvoice({
    required String subscriptionId,
    required DateTime periodStart,
    required DateTime periodEnd,
  }) async {
    final subscription = await _getSubscription(subscriptionId);
    final plan = await _repository.getPlanById(subscription['plan_id'] as String);

    final amount = _calculateInvoiceAmount(
      plan,
      subscription['billing_cycle'] as String? ?? 'monthly',
    );

    await SupabaseManager.client.from('school_invoices').insert({
      'subscription_id': subscriptionId,
      'school_id': subscription['school_id'] as String,
      'invoice_number': await _generateInvoiceNumber(),
      'issue_date': DateTime.now().toIso8601String(),
      'due_date': DateTime.now()
          .add(const Duration(days: 15))
          .toIso8601String(),
      'period_start': periodStart.toIso8601String(),
      'period_end': periodEnd.toIso8601String(),
      'subtotal': amount,
      'total_amount': amount,
      'currency': plan.currency,
      'status': 'unpaid',
    });
  }

  /// Process subscription renewal
  Future<void> processSubscriptionRenewal(String subscriptionId) async {
    final subscription = await _getSubscription(subscriptionId);

    if ((subscription['auto_renew'] as bool?) ?? false) {
      final endDate = DateTime.parse(subscription['end_date'] as String);
      final newStartDate = endDate.add(const Duration(days: 1));
      final newEndDate = _calculateEndDate(
        newStartDate,
        subscription['billing_cycle'] as String? ?? 'monthly',
      );

      await SupabaseManager.client
          .from('school_subscriptions')
          .update({
            'start_date': newStartDate.toIso8601String(),
            'end_date': newEndDate.toIso8601String(),
            'next_billing_date': newEndDate
                .add(const Duration(days: 1))
                .toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', subscriptionId);

      // Generate invoice for new period
      await generateSubscriptionInvoice(
        subscriptionId: subscriptionId,
        periodStart: newStartDate,
        periodEnd: newEndDate,
      );
    } else {
      // Mark subscription as expired
      await SupabaseManager.client
          .from('school_subscriptions')
          .update({
            'status': 'expired',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', subscriptionId);
    }
  }

  /// Check for expiring subscriptions and send reminders
  Future<void> checkExpiringSubscriptions() async {
    final expiringSoon = DateTime.now().add(const Duration(days: 7));

    final response = await SupabaseManager.client
        .from('school_subscriptions')
        .select()
        .lte('end_date', expiringSoon.toIso8601String())
        .eq('status', 'active');

    final expiringSubscriptions = response as List<dynamic>;
    for (final subscription in expiringSubscriptions) {
      await _sendRenewalReminder((subscription as Map<String, dynamic>)['id'] as String);
    }
  }

  /// Get school's current subscription
  Future<Map<String, dynamic>> getSchoolSubscription(String schoolId) async {
    final response = await SupabaseManager.client
        .from('school_subscriptions')
        .select('''
          *,
          plan:subscription_plans(*)
        ''')
        .eq('school_id', schoolId)
        .eq('status', 'active')
        .maybeSingle();

    return response ?? {};
  }

  /// Get subscription invoices for a school
  Future<List<Map<String, dynamic>>> getSchoolInvoices(String schoolId) async {
    final response = await SupabaseManager.client
        .from('school_invoices')
        .select()
        .eq('school_id', schoolId)
        .order('issue_date', ascending: false);

    final invoices = response as List<dynamic>;
    return invoices.map((e) => e as Map<String, dynamic>).toList();
  }

  // Private helper methods
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

  Future<String> _generateInvoiceNumber() async {
    final response = await SupabaseManager.client
        .from('school_invoices')
        .select('invoice_number')
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();

    final lastInvoice = response;
    if (lastInvoice == null) {
      return 'INV-SCH-000001';
    }

    final lastNumber = int.parse(
      (lastInvoice['invoice_number'] as String).split('-').last,
    );
    return 'INV-SCH-${(lastNumber + 1).toString().padLeft(6, '0')}';
  }

  Future<Map<String, dynamic>> _getSubscription(String subscriptionId) async {
    final response = await SupabaseManager.client
        .from('school_subscriptions')
        .select()
        .eq('id', subscriptionId)
        .maybeSingle();

    return response ?? {};
  }

  Future<void> _sendRenewalReminder(String subscriptionId) async {
    // Implementation placeholder for sending renewal reminders via email/SMS
  }
}

// Provider is defined in subscription_providers.dart to avoid circular imports.
