import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/subscription_repository.dart';
import '../domain/subscription_plan.dart';
import 'subscription_billing_engine.dart';
import 'package:isms_app/src/features/institution/application/institution_config_loader.dart';

// Repository provider
final subscriptionRepositoryProvider = Provider<SubscriptionRepository>(
  (ref) => SubscriptionRepository(),
);

// Billing engine provider
final subscriptionBillingEngineProvider = Provider<SubscriptionBillingEngine>((
  ref,
) {
  final repository = ref.read(subscriptionRepositoryProvider);
  final configLoader = ref.read(institutionConfigLoaderProvider);
  return SubscriptionBillingEngine(repository, configLoader);
});

// All available subscription plans
final allPlansProvider = FutureProvider<List<SubscriptionPlan>>((ref) async {
  final repo = ref.read(subscriptionRepositoryProvider);
  return repo.getAllPlans();
});

// Specific plan by ID
final planByIdProvider = FutureProvider.family<SubscriptionPlan, String>((
  ref,
  planId,
) async {
  final repo = ref.read(subscriptionRepositoryProvider);
  return repo.getPlanById(planId);
});

// School's current subscription
final schoolSubscriptionProvider =
    FutureProvider.family<Map<String, dynamic>, String>((ref, schoolId) async {
      final repo = ref.read(subscriptionRepositoryProvider);
      return repo.getSchoolSubscription(schoolId);
    });

// School subscription invoices
final schoolInvoicesProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>((
      ref,
      schoolId,
    ) async {
      final repo = ref.read(subscriptionRepositoryProvider);
      return repo.getSchoolInvoices(schoolId);
    });

// Check if school has active subscription
final hasActiveSubscriptionProvider = FutureProvider.family<bool, String>((
  ref,
  schoolId,
) async {
  final repo = ref.read(subscriptionRepositoryProvider);
  return repo.hasActiveSubscription(schoolId);
});

// Subscription usage statistics
final subscriptionUsageProvider =
    FutureProvider.family<Map<String, dynamic>, String>((ref, schoolId) async {
      final repo = ref.read(subscriptionRepositoryProvider);
      return repo.getUsageStatistics(schoolId);
    });

// Institution-specific pricing plans
final institutionPlansProvider =
    FutureProvider.family<List<SubscriptionPlan>, String>((
      ref,
      institutionType,
    ) async {
      final engine = ref.read(subscriptionBillingEngineProvider);
      return engine.getAvailablePlans(institutionType: institutionType);
    });

// Create subscription
final createSubscriptionProvider =
    FutureProvider.family<void, Map<String, dynamic>>((ref, params) async {
      final repo = ref.read(subscriptionRepositoryProvider);
      await repo.createSubscription(
        schoolId: params['schoolId'] as String,
        planId: params['planId'] as String,
        billingCycle: params['billingCycle'] as String,
        startDate: params['startDate'] as DateTime,
        autoRenew: params['autoRenew'] as bool? ?? true,
      );
    });

// Generate subscription invoice
final generateInvoiceProvider =
    FutureProvider.family<void, Map<String, dynamic>>((ref, params) async {
      final repo = ref.read(subscriptionRepositoryProvider);
      await repo.generateInvoice(
        subscriptionId: params['subscriptionId'] as String,
        schoolId: params['schoolId'] as String,
        amount: params['amount'] as double,
        currency: params['currency'] as String,
        periodStart: params['periodStart'] as DateTime,
        periodEnd: params['periodEnd'] as DateTime,
      );
    });

// Process subscription payment
final processPaymentProvider =
    FutureProvider.family<void, Map<String, dynamic>>((ref, params) async {
      final repo = ref.read(subscriptionRepositoryProvider);
      await repo.processPayment(
        invoiceId: params['invoiceId'] as String,
        amount: params['amount'] as double,
        paymentMethod: params['paymentMethod'] as String,
        transactionId: params['transactionId'] as String,
      );
    });
