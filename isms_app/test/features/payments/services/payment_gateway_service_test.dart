import 'package:flutter_test/flutter_test.dart';
import 'package:isms_app/src/features/payments/services/payment_gateway_service.dart';

void main() {
  group('PaymentProviderType', () {
    test('enum values are correct', () {
      expect(PaymentProviderType.values.length, greaterThan(3));
      expect(PaymentProviderType.stripe, isNotNull);
      expect(PaymentProviderType.jazzcash, isNotNull);
      expect(PaymentProviderType.easypaisa, isNotNull);
      expect(PaymentProviderType.cash, isNotNull);
    });

    test('Stripe supports international payments', () {
      expect(PaymentProviderType.stripe.supportsInternational, true);
    });

    test('JazzCash does not support international payments', () {
      expect(PaymentProviderType.jazzcash.supportsInternational, false);
    });

    test('EasyPaisa does not support international payments', () {
      expect(PaymentProviderType.easypaisa.supportsInternational, false);
    });

    test('Cash payments have zero processing fee', () {
      expect(PaymentProviderType.cash.processingFee, 0.0);
    });

    test('Stripe has processing fee', () {
      expect(PaymentProviderType.stripe.processingFee, greaterThan(0.0));
    });

    test('JazzCash has processing fee', () {
      expect(PaymentProviderType.jazzcash.processingFee, greaterThan(0.0));
    });

    test('EasyPaisa has processing fee', () {
      expect(PaymentProviderType.easypaisa.processingFee, greaterThan(0.0));
    });

    test('Cash payments support refunds', () {
      expect(PaymentProviderType.cash.supportsRefunds, true);
    });

    test('JazzCash supports refunds', () {
      expect(PaymentProviderType.jazzcash.supportsRefunds, true);
    });

    test('Stripe supports refunds', () {
      expect(PaymentProviderType.stripe.supportsRefunds, true);
    });

    test('EasyPaisa supports refunds', () {
      expect(PaymentProviderType.easypaisa.supportsRefunds, true);
    });

    test('Cash does not support recurring payments', () {
      expect(PaymentProviderType.cash.supportsRecurring, false);
    });

    test('Stripe supports recurring payments', () {
      expect(PaymentProviderType.stripe.supportsRecurring, true);
    });

    test('Provider display names are not empty', () {
      for (final provider in PaymentProviderType.values) {
        expect(provider.displayName, isNotEmpty);
      }
    });

    test('Provider min amounts are positive', () {
      for (final provider in PaymentProviderType.values) {
        expect(provider.minAmount, greaterThan(0.0));
      }
    });
  });

  group('PaymentGatewayException', () {
    test('creates exception with message and error code', () {
      final exception = PaymentGatewayException(
        'Test message',
        errorCode: 'TEST_ERROR',
      );

      expect(exception.message, 'Test message');
      expect(exception.errorCode, 'TEST_ERROR');
      expect(exception.toString(), contains('Test message'));
      expect(exception.toString(), contains('TEST_ERROR'));
    });

    test('creates exception with additional details', () {
      final exception = PaymentGatewayException(
        'Test message',
        errorCode: 'TEST_ERROR',
        originalError: 'Original error',
        responseBody: 'Response body',
        statusCode: 400,
      );

      expect(exception.originalError, 'Original error');
      expect(exception.responseBody, 'Response body');
      expect(exception.statusCode, 400);
      expect(exception.toString(), contains('Original error'));
      expect(exception.toString(), contains('Response body'));
      expect(exception.toString(), contains('400'));
    });
  });
}
