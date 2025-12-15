import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/network/supabase_client.dart';
import '../domain/subscription_plan.dart';

class SubscriptionRepository {
  SupabaseClient get _client => SupabaseManager.client;

  /// Get all available subscription plans
  Future<List<SubscriptionPlan>> getAllPlans() async {
    final response = await _client
        .from('subscription_plans')
        .select()
        .eq('is_active', true)
        .eq('is_public', true)
        .order('price_per_month');

    final data = response as List<dynamic>;
    return data
        .map((row) => SubscriptionPlan.fromMap(row as Map<String, dynamic>))
        .toList();
  }

  /// Get a specific plan by ID
  Future<SubscriptionPlan> getPlanById(String planId) async {
    final response = await _client
        .from('subscription_plans')
        .select()
        .eq('id', planId)
        .single();

    return SubscriptionPlan.fromMap(response);
  }

  /// Get school's current subscription
  Future<Map<String, dynamic>> getSchoolSubscription(String schoolId) async {
    final response = await _client
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

  /// Create a new subscription for a school
  Future<void> createSubscription({
    required String schoolId,
    required String planId,
    required String billingCycle,
    required DateTime startDate,
    bool autoRenew = true,
  }) async {
    await _client.from('school_subscriptions').insert({
      'school_id': schoolId,
      'plan_id': planId,
      'billing_cycle': billingCycle,
      'start_date': startDate.toIso8601String(),
      'end_date': _calculateEndDate(startDate, billingCycle).toIso8601String(),
      'auto_renew': autoRenew,
      'status': 'active',
    });
  }

  /// Update subscription status
  Future<void> updateSubscriptionStatus({
    required String subscriptionId,
    required String status,
  }) async {
    await _client
        .from('school_subscriptions')
        .update({
          'status': status,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', subscriptionId);
  }

  /// Get subscription invoices for a school
  Future<List<Map<String, dynamic>>> getSchoolInvoices(String schoolId) async {
    final response = await _client
        .from('school_invoices')
        .select()
        .eq('school_id', schoolId)
        .order('issue_date', ascending: false);

    final data = response as List<dynamic>? ?? [];
    return data.map((e) => e as Map<String, dynamic>).toList();
  }

  /// Check if a school has an active subscription
  Future<bool> hasActiveSubscription(String schoolId) async {
    final response = await _client
        .from('school_subscriptions')
        .select('id')
        .eq('school_id', schoolId)
        .eq('status', 'active')
        .maybeSingle();

    return response != null;
  }

  /// Check if a feature is enabled for a given plan
  Future<bool> isFeatureEnabled(String planName, String featureKey) async {
    // Simple defaults: enterprise enables everything, others enable common features
    if (planName.toLowerCase() == 'enterprise') return true;

    final normalizedPlan = planName.toLowerCase();
    final enabledByPlan = <String, Set<String>>{
      'free': {
        'student_list_view',
      },
      'basic': {
        'student_list_view',
        'notifications',
      },
      'premium': {
        'notifications',
        'reports',
        'advanced_reports',
        'fee_management',
        'exam_management',
        'timetable_management',
        'library_management',
        'transport_management',
        'ai_tutor',
      },
    };

    final features = enabledByPlan[normalizedPlan] ?? const {};
    return features.contains(featureKey);
  }

  /// Get usage limit for a feature in a given plan
  /// Return null for unlimited
  Future<int?> getFeatureLimit(String planName, String featureKey) async {
    if (planName.toLowerCase() == 'enterprise') return null;

    final normalizedPlan = planName.toLowerCase();
    final limitsByPlan = <String, Map<String, int>>{
      'free': {
        'student_list_view': 50,
      },
      'basic': {
        'student_list_view': 200,
        'notifications': 100,
      },
      'premium': {
        'notifications': 1000,
        'reports': 10,
        'advanced_reports': 5,
        'fee_management': 1000,
        'exam_management': 1000,
        'timetable_management': 1000,
        'library_management': 1000,
        'transport_management': 1000,
        'ai_tutor': 1000,
      },
    };

    return limitsByPlan[normalizedPlan]?[featureKey];
  }

  /// Get subscription usage statistics
  Future<Map<String, dynamic>> getUsageStatistics(String schoolId) async {
    final response = await _client.rpc(
      'get_subscription_usage',
      params: {'p_school_id': schoolId},
    );

    return response as Map<String, dynamic>? ?? {};
  }

  /// Generate subscription invoice
  Future<void> generateInvoice({
    required String subscriptionId,
    required String schoolId,
    required double amount,
    required String currency,
    required DateTime periodStart,
    required DateTime periodEnd,
  }) async {
    await _client.from('school_invoices').insert({
      'subscription_id': subscriptionId,
      'school_id': schoolId,
      'invoice_number': await _generateInvoiceNumber(),
      'issue_date': DateTime.now().toIso8601String(),
      'due_date': DateTime.now()
          .add(const Duration(days: 15))
          .toIso8601String(),
      'period_start': periodStart.toIso8601String(),
      'period_end': periodEnd.toIso8601String(),
      'subtotal': amount,
      'total_amount': amount,
      'currency': currency,
      'status': 'unpaid',
    });
  }

  /// Process subscription payment
  Future<void> processPayment({
    required String invoiceId,
    required double amount,
    required String paymentMethod,
    required String transactionId,
  }) async {
    // Update invoice status
    await _client
        .from('school_invoices')
        .update({
          'status': 'paid',
          'paid_at': DateTime.now().toIso8601String(),
          'payment_method': paymentMethod,
        })
        .eq('id', invoiceId);

    // Create payment transaction
    await _client.from('payment_transactions').insert({
      'invoice_id': invoiceId,
      'invoice_type': 'school',
      'amount': amount,
      'payment_method': paymentMethod,
      'transaction_id': transactionId,
      'status': 'completed',
      'processed_at': DateTime.now().toIso8601String(),
    });
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

  Future<String> _generateInvoiceNumber() async {
    final response = await _client
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
}
