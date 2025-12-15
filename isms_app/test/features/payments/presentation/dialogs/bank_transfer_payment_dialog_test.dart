import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:isms_app/src/features/payments/presentation/dialogs/bank_transfer_payment_dialog.dart';

class _MockNavigatorObserver extends Mock implements NavigatorObserver {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('BankTransferPaymentDialog', () {
    late NavigatorObserver navigatorObserver;

    setUp(() {
      navigatorObserver = _MockNavigatorObserver();
    });

    Future<void> pumpDialog(WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: Container()),
          navigatorObservers: [navigatorObserver],
        ),
      );

      await tester.pump();

      // Show the dialog
      await tester.runAsync(() async {
        await showDialog(
          context: tester.element(find.byType(Scaffold)),
          builder: (context) => const BankTransferPaymentDialog(
            amount: 1000.0,
            currency: 'PKR',
            referenceCode: 'TEST-123',
            payerName: 'Test User',
            payerEmail: 'test@example.com',
            payerPhone: '+923001234567',
          ),
        );
      });

      await tester.pumpAndSettle();
    }

    testWidgets('displays correct payment amount', (tester) async {
      await pumpDialog(tester);

      expect(find.text('PKR 1,000.00'), findsOneWidget);
      expect(find.text('Payment Amount'), findsOneWidget);
    });

    testWidgets('contains required form fields', (tester) async {
      await pumpDialog(tester);

      expect(find.widgetWithText(TextFormField, 'Bank Name *'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Transaction Reference Number *'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Transfer Date *'), findsOneWidget);
      expect(find.text('Upload Bank Receipt'), findsOneWidget);
    });

    testWidgets('shows validation errors for required fields', (tester) async {
      await pumpDialog(tester);

      // Try to submit without filling required fields
      await tester.tap(find.text('Submit Payment'));
      await tester.pump();

      expect(find.text('Please enter bank name'), findsOneWidget);
      expect(find.text('Please enter reference number'), findsOneWidget);
      expect(find.text('Please select transfer date'), findsOneWidget);
      expect(find.text('Please upload a bank transfer receipt'), findsOneWidget);
    });

    testWidgets('has submit button enabled when form is valid', (tester) async {
      await pumpDialog(tester);

      // Fill in required fields
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Bank Name *'),
        'HBL',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Transaction Reference Number *'),
        'TRX123456789',
      );

      // The submit button should be enabled (not disabled)
      final submitButton = find.widgetWithText(ElevatedButton, 'Submit Payment');
      expect(tester.widget<ElevatedButton>(submitButton).enabled, isTrue);
    });
  });
}