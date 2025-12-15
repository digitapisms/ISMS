import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../application/payment_providers.dart';
import '../../domain/payment_account.dart';
import '../widgets/add_payment_account_dialog.dart';
import '../widgets/edit_payment_account_dialog.dart';

class PaymentAccountsTab extends ConsumerWidget {
  const PaymentAccountsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountsAsync = ref.watch(schoolPaymentAccountsProvider);

    return accountsAsync.when(
      data: (accounts) {
        if (accounts.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.account_balance_wallet_outlined,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'No payment accounts configured',
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                Text(
                  'Add a payment account to start receiving payments',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.grey[500]),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => _showAddAccountDialog(context, ref),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Payment Account'),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Payment Accounts',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _showAddAccountDialog(context, ref),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Account'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: accounts.length,
                itemBuilder: (context, index) {
                  final account = accounts[index];
                  return _PaymentAccountCard(
                    account: account,
                    onRefresh: () {
                      ref.invalidate(schoolPaymentAccountsProvider);
                    },
                    onEdit: () {
                      showDialog(
                        context: context,
                        builder: (context) =>
                            EditPaymentAccountDialog(account: account),
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
              'Failed to load payment accounts',
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
                ref.invalidate(schoolPaymentAccountsProvider);
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddAccountDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => const AddPaymentAccountDialog(),
    );
  }
}

class _PaymentAccountCard extends StatelessWidget {
  const _PaymentAccountCard({
    required this.account,
    required this.onRefresh,
    this.onEdit,
  });

  final PaymentAccount account;
  final VoidCallback onRefresh;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final provider = account.provider;
    final statusColor = _getStatusColor(account.status);
    final statusIcon = _getStatusIcon(account.status);

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
                        account.accountLabel,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      if (provider != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          provider.displayName,
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
                        account.status.toUpperCase(),
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
            if (account.currency != null || account.country != null) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 16,
                children: [
                  if (account.currency != null)
                    _InfoChip(
                      icon: Icons.currency_exchange,
                      label: account.currency!,
                    ),
                  if (account.country != null)
                    _InfoChip(icon: Icons.public, label: account.country!),
                ],
              ),
            ],
            if (account.verifiedAt != null) ...[
              const SizedBox(height: 8),
              Text(
                'Verified: ${DateFormat('MMM dd, yyyy').format(account.verifiedAt!)}',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.edit, size: 18),
                  label: const Text('Edit'),
                  onPressed: onEdit,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'rejected':
        return Colors.red;
      case 'suspended':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Icons.check_circle;
      case 'pending':
        return Icons.pending;
      case 'rejected':
        return Icons.cancel;
      case 'suspended':
        return Icons.pause_circle;
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
