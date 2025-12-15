import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../domain/payment_transaction.dart';
import '../widgets/payment_receipt_generator.dart';

class TransactionDetailScreen extends ConsumerWidget {
  const TransactionDetailScreen({super.key, required this.transaction});

  final PaymentTransaction transaction;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusColor = _getStatusColor(transaction.status);
    final statusIcon = _getStatusIcon(transaction.status);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction Details'),
        actions: [
          if (transaction.isSuccessful)
            IconButton(
              icon: const Icon(Icons.receipt_long),
              onPressed: () => _generateReceipt(context, transaction),
              tooltip: 'Generate Receipt',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status Card
            Card(
              color: statusColor.withOpacity(0.1),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(statusIcon, size: 32, color: statusColor),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Status',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            transaction.status.toUpperCase(),
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(
                                  color: statusColor,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Amount Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Amount',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      NumberFormat.currency(
                        symbol: '${transaction.currency} ',
                        decimalDigits: 2,
                      ).format(transaction.amount),
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: transaction.isSuccessful
                                ? Colors.green[700]
                                : Colors.grey[700],
                          ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Payer Information
            if (transaction.payerName != null ||
                transaction.payerEmail != null ||
                transaction.payerPhone != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Payer Information',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      if (transaction.payerName != null)
                        _DetailRow(
                          icon: Icons.person,
                          label: 'Name',
                          value: transaction.payerName!,
                        ),
                      if (transaction.payerEmail != null) ...[
                        const SizedBox(height: 8),
                        _DetailRow(
                          icon: Icons.email,
                          label: 'Email',
                          value: transaction.payerEmail!,
                        ),
                      ],
                      if (transaction.payerPhone != null) ...[
                        const SizedBox(height: 8),
                        _DetailRow(
                          icon: Icons.phone,
                          label: 'Phone',
                          value: transaction.payerPhone!,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            if (transaction.payerName != null ||
                transaction.payerEmail != null ||
                transaction.payerPhone != null)
              const SizedBox(height: 16),

            // Transaction Details
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Transaction Details',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _DetailRow(
                      icon: Icons.tag,
                      label: 'Transaction ID',
                      value: transaction.id,
                      copyable: true,
                    ),
                    if (transaction.referenceCode != null) ...[
                      const SizedBox(height: 8),
                      _DetailRow(
                        icon: Icons.receipt,
                        label: 'Reference Code',
                        value: transaction.referenceCode!,
                        copyable: true,
                      ),
                    ],
                    if (transaction.externalReference != null) ...[
                      const SizedBox(height: 8),
                      _DetailRow(
                        icon: Icons.link,
                        label: 'External Reference',
                        value: transaction.externalReference!,
                        copyable: true,
                      ),
                    ],
                    if (transaction.initiatedAt != null) ...[
                      const SizedBox(height: 8),
                      _DetailRow(
                        icon: Icons.schedule,
                        label: 'Initiated At',
                        value: DateFormat(
                          'MMM dd, yyyy HH:mm:ss',
                        ).format(transaction.initiatedAt!),
                      ),
                    ],
                    if (transaction.completedAt != null) ...[
                      const SizedBox(height: 8),
                      _DetailRow(
                        icon: Icons.check_circle,
                        label: 'Completed At',
                        value: DateFormat(
                          'MMM dd, yyyy HH:mm:ss',
                        ).format(transaction.completedAt!),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Error Information
            if (transaction.errorMessage != null ||
                transaction.errorCode != null)
              Card(
                color: Colors.red[50],
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.error_outline, color: Colors.red[700]),
                          const SizedBox(width: 8),
                          Text(
                            'Error Information',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  color: Colors.red[700],
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (transaction.errorCode != null)
                        _DetailRow(
                          icon: Icons.code,
                          label: 'Error Code',
                          value: transaction.errorCode!,
                        ),
                      if (transaction.errorMessage != null) ...[
                        if (transaction.errorCode != null)
                          const SizedBox(height: 8),
                        _DetailRow(
                          icon: Icons.message,
                          label: 'Error Message',
                          value: transaction.errorMessage!,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            if (transaction.errorMessage != null ||
                transaction.errorCode != null)
              const SizedBox(height: 16),

            // Raw Response (Expandable)
            if (transaction.rawResponse != null)
              Card(
                child: ExpansionTile(
                  leading: const Icon(Icons.code),
                  title: const Text('Raw Response'),
                  subtitle: const Text('View technical details'),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          transaction.rawResponse.toString(),
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _generateReceipt(BuildContext context, PaymentTransaction transaction) {
    PaymentReceiptGenerator.generateReceipt(
      context: context,
      transaction: transaction,
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'succeeded':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'failed':
        return Colors.red;
      case 'refunded':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'succeeded':
        return Icons.check_circle;
      case 'pending':
        return Icons.pending;
      case 'failed':
        return Icons.cancel;
      case 'refunded':
        return Icons.refresh;
      default:
        return Icons.help_outline;
    }
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.copyable = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool copyable;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      value,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  if (copyable)
                    IconButton(
                      icon: const Icon(Icons.copy, size: 18),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: value));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Copied to clipboard')),
                        );
                      },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
