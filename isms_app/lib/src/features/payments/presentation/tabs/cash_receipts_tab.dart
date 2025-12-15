import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../application/payment_providers.dart';
import '../../domain/cash_fee_receipt.dart';
import '../../../school_registration/application/school_providers.dart';
import '../widgets/add_cash_receipt_dialog.dart';
import '../widgets/cash_receipt_generator.dart';

class CashReceiptsTab extends ConsumerWidget {
  const CashReceiptsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final receiptsAsync = ref.watch(cashReceiptsProvider);

    return receiptsAsync.when(
      data: (receipts) {
        // Calculate total
        final totalAmount = receipts.fold<double>(
          0,
          (sum, receipt) => sum + receipt.amount,
        );

        return Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              color: Theme.of(context).colorScheme.surfaceVariant,
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.money,
                                size: 20,
                                color: Colors.green[700],
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Total Cash Received',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(color: Colors.grey[600]),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            NumberFormat.currency(
                              symbol: 'PKR ',
                              decimalDigits: 0,
                            ).format(totalAmount),
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green[700],
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${receipts.length} receipt${receipts.length != 1 ? 's' : ''}',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Cash Receipts',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _showAddReceiptDialog(context, ref),
                    icon: const Icon(Icons.add),
                    label: const Text('Record Payment'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: receipts.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.money_outlined,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No cash receipts yet',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(color: Colors.grey[600]),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Record cash payments received manually',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: Colors.grey[500]),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: () =>
                                _showAddReceiptDialog(context, ref),
                            icon: const Icon(Icons.add),
                            label: const Text('Record Payment'),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: receipts.length,
                      itemBuilder: (context, index) {
                        final receipt = receipts[index];
                        return _CashReceiptCard(
                          receipt: receipt,
                          onGenerateReceipt: () {
                            final school = ref.read(currentSchoolProvider);
                            CashReceiptGenerator.generateReceipt(
                              context: context,
                              receipt: receipt,
                              schoolName: school?.name,
                            );
                          },
                        );
                      },
                    ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              'Failed to load cash receipts',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                ref.invalidate(cashReceiptsProvider);
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddReceiptDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => const AddCashReceiptDialog(),
    );
  }
}

class _CashReceiptCard extends StatelessWidget {
  const _CashReceiptCard({required this.receipt, this.onGenerateReceipt});

  final CashFeeReceipt receipt;
  final VoidCallback? onGenerateReceipt;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        receipt.payerName,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        NumberFormat.currency(
                          symbol: '${receipt.currency} ',
                          decimalDigits: 2,
                        ).format(receipt.amount),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.green[700],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.money, color: Colors.green[700], size: 32),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                _InfoChip(
                  icon: Icons.calendar_today,
                  label: DateFormat('MMM dd, yyyy').format(receipt.paymentDate),
                ),
                if (receipt.receiptNumber != null)
                  _InfoChip(
                    icon: Icons.receipt,
                    label: 'Receipt #${receipt.receiptNumber}',
                  ),
              ],
            ),
            if (receipt.notes != null && receipt.notes!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.note, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        receipt.notes!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (onGenerateReceipt != null)
                  TextButton.icon(
                    icon: const Icon(Icons.receipt_long, size: 18),
                    label: const Text('Generate Receipt'),
                    onPressed: onGenerateReceipt,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: Colors.grey[700]),
        ),
      ],
    );
  }
}
