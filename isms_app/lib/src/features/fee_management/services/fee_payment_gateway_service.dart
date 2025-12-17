import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isms_app/src/features/payments/services/payment_gateway_service.dart';
import 'package:isms_app/src/features/fee_management/domain/fee_invoice.dart';
import 'package:isms_app/src/features/fee_management/application/fee_providers.dart';
import 'package:isms_app/src/features/school_registration/application/school_providers.dart';

/// Service for integrating payment gateway with fee management system
class FeePaymentGatewayService {
  final Ref _ref;

  FeePaymentGatewayService(this._ref);

  /// Get payment gateway service for a specific provider
  PaymentGatewayService _getPaymentGatewayService(
    PaymentProviderType provider,
  ) {
    final config = PaymentGatewayConfig.fromEnv(provider);
    return PaymentGatewayService(provider: provider, config: config);
  }

  /// Process online payment for a fee invoice
  Future<Map<String, dynamic>> processOnlinePayment({
    required FeeInvoice invoice,
    required PaymentProviderType provider,
    required double amount,
    String? customerEmail,
    String? customerPhone,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final paymentGateway = _getPaymentGatewayService(provider);

      // Create payment intent with the gateway
      final paymentIntent = await paymentGateway.createPaymentIntent(
        amount: amount,
        currency: invoice.currency,
        reference: invoice.invoiceNumber,
        customerEmail: customerEmail,
        customerPhone: customerPhone,
        metadata: {
          'invoice_id': invoice.id,
          'student_id': invoice.studentId,
          'school_id': invoice.schoolId,
          ...?metadata,
        },
      );

      return {
        'success': true,
        'payment_intent': paymentIntent,
        'provider': provider.name,
        'next_action': paymentIntent['next_action'] ?? 'confirm_payment',
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
        'provider': provider.name,
      };
    }
  }

  /// Confirm and complete a payment
  Future<Map<String, dynamic>> confirmPayment({
    required String paymentIntentId,
    required PaymentProviderType provider,
    required String paymentMethodId,
    required FeeInvoice invoice,
    required double amount,
    Map<String, dynamic>? confirmationData,
  }) async {
    try {
      final paymentGateway = _getPaymentGatewayService(provider);

      // Confirm payment with gateway
      final confirmation = await paymentGateway.confirmPayment(
        paymentIntentId: paymentIntentId,
        paymentMethodId: paymentMethodId,
        confirmationData: confirmationData,
      );

      if (confirmation['status'] == 'succeeded') {
        // Record the payment in the database
        final school = _ref.read(currentSchoolProvider);
        if (school == null) {
          throw Exception('School context not available');
        }

        final repo = _ref.read(feeRepositoryProvider);
        await repo.recordFeePayment(
          schoolId: school.id,
          invoiceId: invoice.id,
          studentId: invoice.studentId,
          paymentMethod: provider.name,
          amount: amount,
          paymentDate: DateTime.now(),
          paymentTransactionId: paymentIntentId,
          paymentReference: confirmation['id']?.toString(),
          notes: 'Online payment via ${paymentGateway.displayName}',
        );

        return {
          'success': true,
          'confirmation': confirmation,
          'recorded': true,
        };
      }

      return {
        'success': false,
        'confirmation': confirmation,
        'error': 'Payment not succeeded',
      };
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Check payment status
  Future<Map<String, dynamic>> checkPaymentStatus({
    required String paymentIntentId,
    required PaymentProviderType provider,
  }) async {
    try {
      final paymentGateway = _getPaymentGatewayService(provider);
      final status = await paymentGateway.getPaymentStatus(paymentIntentId);

      return {'success': true, 'status': status, 'provider': provider.name};
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
        'provider': provider.name,
      };
    }
  }

  /// Get available payment providers for an institution
  List<PaymentProviderType> getAvailableProviders() {
    // Check environment configuration to see which providers are configured
    final availableProviders = <PaymentProviderType>[];

    for (final provider in PaymentProviderType.values) {
      // Bank transfer and cash are always available (no API keys needed)
      if (provider == PaymentProviderType.bank_transfer ||
          provider == PaymentProviderType.cash) {
        availableProviders.add(provider);
        continue;
      }

      final config = PaymentGatewayConfig.fromEnv(provider);
      if (config.isValid) {
        availableProviders.add(provider);
      }
    }

    return availableProviders;
  }

  /// Get provider display name
  String getProviderDisplayName(PaymentProviderType provider) {
    final paymentGateway = _getPaymentGatewayService(provider);
    return paymentGateway.displayName;
  }
}

// Riverpod provider for the fee payment gateway service
final feePaymentGatewayServiceProvider = Provider<FeePaymentGatewayService>((
  ref,
) {
  return FeePaymentGatewayService(ref);
});
