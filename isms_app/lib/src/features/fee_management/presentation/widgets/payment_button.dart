import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/fee_providers.dart';
import '../../domain/fee_invoice.dart';
import '../dialogs/payment_integration_dialog.dart';

class PaymentButton extends ConsumerWidget {
  const PaymentButton({super.key, required this.invoice});

  final FeeInvoice invoice;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (invoice.isPaid) {
      return const SizedBox.shrink();
    }

    return ElevatedButton.icon(
      onPressed: () async {
        final result = await showDialog(
          context: context,
          builder: (_) => PaymentIntegrationDialog(invoice: invoice),
        );
        if (result == true) {
          ref.invalidate(feeInvoicesProvider);
        }
      },
      icon: const Icon(Icons.payment),
      label: const Text('Record Payment'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
    );
  }
}
