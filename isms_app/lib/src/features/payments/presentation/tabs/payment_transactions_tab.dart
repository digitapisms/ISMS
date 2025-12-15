import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../application/payment_providers.dart';
import '../../domain/payment_filters.dart';
import '../../domain/payment_transaction.dart';
import '../../services/export_service.dart';
import '../dialogs/payment_filter_dialog.dart';
import '../screens/transaction_detail_screen.dart';

class PaymentTransactionsTab extends ConsumerStatefulWidget {
  const PaymentTransactionsTab({super.key});

  @override
  ConsumerState<PaymentTransactionsTab> createState() =>
      _PaymentTransactionsTabState();
}

class _PaymentTransactionsTabState
    extends ConsumerState<PaymentTransactionsTab> {
  PaymentFilters _filters = const PaymentFilters();
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final transactionsAsync = _searchQuery.isEmpty
        ? ref.watch(filteredPaymentTransactionsProvider(_filters))
        : ref.watch(paymentSearchProvider(_searchQuery));

    return transactionsAsync.when(
      data: (transactions) {
        if (transactions.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.receipt_long_outlined,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'No transactions yet',
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                Text(
                  'Payment transactions will appear here',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.grey[500]),
                ),
              ],
            ),
          );
        }

        // Calculate summary
        final totalAmount = transactions
            .where((t) => t.isSuccessful)
            .fold<double>(0, (sum, t) => sum + t.amount);
        final pendingCount = transactions.where((t) => t.isPending).length;
        final failedCount = transactions.where((t) => t.isFailed).length;

        return Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _SummaryCard(
                          label: 'Total Received',
                          value: NumberFormat.currency(
                            symbol: 'PKR ',
                            decimalDigits: 0,
                          ).format(totalAmount),
                          icon: Icons.account_balance_wallet,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _SummaryCard(
                          label: 'Pending',
                          value: pendingCount.toString(),
                          icon: Icons.pending,
                          color: Colors.orange,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _SummaryCard(
                          label: 'Failed',
                          value: failedCount.toString(),
                          icon: Icons.error_outline,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Filters
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.filter_list, size: 18),
                          label: const Text('Filters'),
                          onPressed: () async {
                            final newFilters = await showDialog<PaymentFilters>(
                              context: context,
                              builder: (context) =>
                                  PaymentFilterDialog(currentFilters: _filters),
                            );

                            if (newFilters != null) {
                              setState(() {
                                _filters = newFilters;
                              });
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.search, size: 18),
                          label: const Text('Search'),
                          onPressed: () async {
                            final query = await showDialog<String>(
                              context: context,
                              builder: (context) => PaymentSearchDialog(
                                initialQuery: _searchQuery,
                              ),
                            );

                            if (query != null) {
                              setState(() {
                                _searchQuery = query;
                              });
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.download, size: 18),
                        label: const Text('Export'),
                        onPressed: () async {
                          try {
                            final transactions = await ref.read(
                              filteredPaymentTransactionsProvider(
                                _filters,
                              ).future,
                            );

                            if (transactions.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('No transactions to export'),
                                ),
                              );
                              return;
                            }

                            final csvContent =
                                await ExportService.exportTransactionsToCSV(
                                  transactions,
                                );
                            final fileName =
                                ExportService.generateExportFileName();

                            // Save file using platform channels
                            await ExportService.saveCSVToFile(
                              csvContent,
                              fileName,
                            );

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Exported ${transactions.length} transactions to $fileName',
                                ),
                              ),
                            );
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Export failed: ${e.toString()}'),
                              ),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: transactions.length,
                itemBuilder: (context, index) {
                  final transaction = transactions[index];
                  return _TransactionCard(
                    transaction: transaction,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) =>
                              TransactionDetailScreen(transaction: transaction),
                        ),
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
              'Failed to load transactions',
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
                ref.invalidate(paymentTransactionsProvider);
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _TransactionCard extends StatelessWidget {
  const _TransactionCard({required this.transaction, this.onTap});

  final PaymentTransaction transaction;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(transaction.status);
    final statusIcon = _getStatusIcon(transaction.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
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
                          NumberFormat.currency(
                            symbol: '${transaction.currency} ',
                            decimalDigits: 2,
                          ).format(transaction.amount),
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        if (transaction.payerName != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            transaction.payerName!,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: Colors.grey[600]),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: statusColor.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusIcon, size: 16, color: statusColor),
                        const SizedBox(width: 4),
                        Text(
                          transaction.status.toUpperCase(),
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (transaction.referenceCode != null ||
                  transaction.externalReference != null) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 16,
                  children: [
                    if (transaction.referenceCode != null)
                      _InfoChip(
                        icon: Icons.tag,
                        label: 'Ref: ${transaction.referenceCode}',
                      ),
                    if (transaction.externalReference != null)
                      _InfoChip(
                        icon: Icons.link,
                        label: 'Ext: ${transaction.externalReference}',
                      ),
                  ],
                ),
              ],
              if (transaction.initiatedAt != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Initiated: ${DateFormat('MMM dd, yyyy HH:mm').format(transaction.initiatedAt!)}',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                ),
              ],
              if (transaction.errorMessage != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.red[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 16,
                        color: Colors.red[700],
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          transaction.errorMessage!,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: Colors.red[700]),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
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
