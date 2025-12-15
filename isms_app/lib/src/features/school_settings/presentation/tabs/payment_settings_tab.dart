import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/subscription/feature_guard.dart';
import '../../../payments/application/payment_providers.dart';
import '../../../payments/domain/cash_fee_receipt.dart';
import '../../../payments/domain/payment_account.dart';
import '../../../payments/domain/payment_provider.dart';
import '../../../payments/domain/payment_transaction.dart';
import '../../../school_registration/domain/school.dart';

class PaymentSettingsTab extends ConsumerWidget {
  const PaymentSettingsTab({super.key, required this.school});

  final School school;

  static final _amountFormat = NumberFormat.currency(
    locale: 'en_PK',
    symbol: '₨',
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final providersAsync = ref.watch(paymentProvidersProvider);
    final accountsAsync = ref.watch(schoolPaymentAccountsProvider);
    final transactionsAsync = ref.watch(paymentTransactionsProvider);
    final cashReceiptsAsync = ref.watch(cashReceiptsProvider);

    return FeatureGuard(
      featureKey: 'payment_integration',
      child: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(paymentProvidersProvider);
          ref.invalidate(schoolPaymentAccountsProvider);
          ref.invalidate(paymentTransactionsProvider);
          ref.invalidate(cashReceiptsProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              'Payment Channels',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              'Connect Easypaisa, JazzCash, bank transfers, or card gateways so you can start collecting fees online.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            providersAsync.when(
              data: (providers) => accountsAsync.when(
                data: (accounts) => _ProvidersGrid(
                  providers: providers,
                  accounts: accounts,
                  onConfigure: (provider) =>
                      _showConfigureProviderDialog(context, ref, provider),
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => _ErrorBanner(message: '$e'),
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => _ErrorBanner(message: '$e'),
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Cash Fee Receipts',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Record over-the-counter fee payments so everything stays in sync.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                FilledButton.icon(
                  icon: const Icon(Icons.note_add_outlined),
                  label: const Text('Record cash receipt'),
                  onPressed: () =>
                      _showCashReceiptDialog(context, ref, school.id),
                ),
              ],
            ),
            const SizedBox(height: 16),
            cashReceiptsAsync.when(
              data: (receipts) {
                if (receipts.isEmpty) {
                  return const Text('No cash receipts recorded yet.');
                }
                return Column(
                  children: receipts
                      .map((receipt) => _CashReceiptTile(receipt: receipt))
                      .toList(),
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
              error: (e, _) => _ErrorBanner(message: '$e'),
            ),
            const SizedBox(height: 32),
            Text(
              'Recent Transactions',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            transactionsAsync.when(
              data: (transactions) {
                if (transactions.isEmpty) {
                  return const Text(
                    'No transactions yet. Once you start collecting payments, they will appear here.',
                  );
                }
                return Column(
                  children: transactions
                      .map((tx) => _TransactionTile(transaction: tx))
                      .toList(),
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
              error: (e, _) => _ErrorBanner(message: '$e'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showConfigureProviderDialog(
    BuildContext context,
    WidgetRef ref,
    PaymentProvider provider,
  ) async {
    final formKey = GlobalKey<FormState>();
    final controllers = <String, TextEditingController>{};
    for (final field in provider.requiredFields) {
      controllers[field] = TextEditingController();
    }
    final labelController = TextEditingController(
      text: '${provider.displayName} Account',
    );

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Connect ${provider.displayName}'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: labelController,
                    decoration: const InputDecoration(
                      labelText: 'Account label',
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Enter a label';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  ...provider.requiredFields.map(
                    (field) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: TextFormField(
                        controller: controllers[field],
                        decoration: InputDecoration(
                          labelText: _formatFieldLabel(field),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Required';
                          }
                          return null;
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) {
                  return;
                }

                final fields = <String, String>{
                  for (final entry in controllers.entries)
                    entry.key: entry.value.text.trim(),
                };

                try {
                  await ref
                      .read(paymentsRepositoryProvider)
                      .upsertAccount(
                        schoolId: school.id,
                        providerKey: provider.providerKey,
                        credentials: fields,
                        accountLabel: labelController.text.trim(),
                      );
                  ref.invalidate(schoolPaymentAccountsProvider);
                  if (!context.mounted) return;
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '${provider.displayName} submitted for review.',
                      ),
                    ),
                  );
                } catch (e) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to connect account: $e')),
                  );
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  String _formatFieldLabel(String key) {
    return key
        .split(RegExp(r'[_\s]+'))
        .map(
          (part) => part.isEmpty
              ? part
              : part[0].toUpperCase() + part.substring(1).toLowerCase(),
        )
        .join(' ');
  }

  Future<void> _showCashReceiptDialog(
    BuildContext context,
    WidgetRef ref,
    String schoolId,
  ) async {
    final formKey = GlobalKey<FormState>();
    final payerController = TextEditingController();
    final amountController = TextEditingController();
    final receiptController = TextEditingController();
    final notesController = TextEditingController();
    DateTime selectedDate = DateTime.now();

    await showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              title: const Text('Record cash fee receipt'),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: payerController,
                        decoration: const InputDecoration(
                          labelText: 'Payer name',
                        ),
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                            ? 'Required'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: amountController,
                        decoration: const InputDecoration(
                          labelText: 'Amount',
                          prefixText: '₨ ',
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        validator: (value) {
                          final parsed = double.tryParse(value ?? '');
                          if (parsed == null || parsed <= 0) {
                            return 'Enter a valid amount';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: receiptController,
                        decoration: const InputDecoration(
                          labelText: 'Receipt number (optional)',
                        ),
                      ),
                      const SizedBox(height: 12),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Payment date'),
                        subtitle: Text(DateFormat.yMMMd().format(selectedDate)),
                        trailing: IconButton(
                          icon: const Icon(Icons.calendar_today),
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: selectedDate,
                              firstDate: DateTime.now().subtract(
                                const Duration(days: 365),
                              ),
                              lastDate: DateTime.now(),
                            );
                            if (picked != null) {
                              setModalState(() {
                                selectedDate = picked;
                              });
                            }
                          },
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: notesController,
                        decoration: const InputDecoration(
                          labelText: 'Notes (optional)',
                        ),
                        maxLines: 3,
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;
                    final amount = double.parse(amountController.text.trim());
                    try {
                      await ref
                          .read(paymentsRepositoryProvider)
                          .addCashReceipt(
                            schoolId: schoolId,
                            payerName: payerController.text.trim(),
                            amount: amount,
                            paymentDate: selectedDate,
                            receiptNumber: receiptController.text.trim().isEmpty
                                ? null
                                : receiptController.text.trim(),
                            notes: notesController.text.trim().isEmpty
                                ? null
                                : notesController.text.trim(),
                          );
                      ref.invalidate(cashReceiptsProvider);
                      if (!context.mounted) return;
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Cash receipt recorded.')),
                      );
                    } catch (e) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to record receipt: $e')),
                      );
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _ProvidersGrid extends StatelessWidget {
  const _ProvidersGrid({
    required this.providers,
    required this.accounts,
    required this.onConfigure,
  });

  final List<PaymentProvider> providers;
  final List<PaymentAccount> accounts;
  final void Function(PaymentProvider provider) onConfigure;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: providers.map((provider) {
        PaymentAccount? account;
        for (final acc in accounts) {
          if (acc.providerId == provider.id) {
            account = acc;
            break;
          }
        }
        final hasAccount = account != null;

        return Container(
          width: 320,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            border: Border.all(
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    providerIcon(provider),
                    size: 28,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      provider.displayName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  _StatusChip(status: account?.status ?? 'not set'),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                _providerDescription(provider.providerKey),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
              FilledButton.tonalIcon(
                icon: Icon(hasAccount ? Icons.refresh : Icons.link),
                label: Text(hasAccount ? 'Update credentials' : 'Connect'),
                onPressed: provider.isActive
                    ? () => onConfigure(provider)
                    : null,
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  IconData providerIcon(PaymentProvider provider) {
    switch (provider.providerKey) {
      case 'easypaisa':
        return Icons.account_balance_wallet_outlined;
      case 'jazzcash':
        return Icons.phone_iphone;
      case 'bank_transfer':
        return Icons.account_balance;
      case 'stripe':
        return Icons.credit_card;
      default:
        return Icons.payment;
    }
  }

  String _providerDescription(String key) {
    switch (key) {
      case 'easypaisa':
        return 'Accept payments via Easypaisa merchant checkout.';
      case 'jazzcash':
        return 'Connect JazzCash account for wallet and card acceptance.';
      case 'bank_transfer':
        return 'Share bank account details for manual deposits.';
      case 'stripe':
        return 'Use Stripe to accept global card payments.';
      default:
        return 'Configure this provider to start receiving payments.';
    }
  }
}

class _TransactionTile extends StatelessWidget {
  const _TransactionTile({required this.transaction});

  final PaymentTransaction transaction;

  Color _statusColor(BuildContext context) {
    switch (transaction.status) {
      case 'succeeded':
        return Colors.green;
      case 'failed':
        return Theme.of(context).colorScheme.error;
      default:
        return Theme.of(context).colorScheme.outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final subtitleParts = <String>[];
    if (transaction.payerName != null) {
      subtitleParts.add(transaction.payerName!);
    }
    if (transaction.referenceCode != null) {
      subtitleParts.add('#${transaction.referenceCode!}');
    }

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: _statusColor(context).withValues(alpha: 0.15),
        child: Icon(
          transaction.isSuccessful
              ? Icons.check
              : transaction.isFailed
              ? Icons.error_outline
              : Icons.hourglass_empty,
          color: _statusColor(context),
        ),
      ),
      title: Text(PaymentSettingsTab._amountFormat.format(transaction.amount)),
      subtitle: Text(subtitleParts.isEmpty ? '—' : subtitleParts.join(' • ')),
      trailing: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(transaction.status.toUpperCase()),
          if (transaction.initiatedAt != null)
            Text(
              DateFormat.yMMMd().add_Hm().format(
                transaction.initiatedAt!.toLocal(),
              ),
              style: Theme.of(context).textTheme.bodySmall,
            ),
        ],
      ),
    );
  }
}

class _CashReceiptTile extends StatelessWidget {
  const _CashReceiptTile({required this.receipt});

  final CashFeeReceipt receipt;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Theme.of(
          context,
        ).colorScheme.primary.withValues(alpha: 0.15),
        child: Icon(Icons.money, color: Theme.of(context).colorScheme.primary),
      ),
      title: Text(PaymentSettingsTab._amountFormat.format(receipt.amount)),
      subtitle: Text(
        '${receipt.payerName} • ${DateFormat.yMMMd().format(receipt.paymentDate)}',
      ),
      trailing: Text(receipt.receiptNumber ?? 'CASH'),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status) {
      case 'active':
        color = Colors.green;
        break;
      case 'pending':
        color = Colors.orange;
        break;
      case 'rejected':
      case 'suspended':
        color = Theme.of(context).colorScheme.error;
        break;
      default:
        color = Theme.of(context).colorScheme.outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(50),
      ),
      child: Text(
        status.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Theme.of(context).colorScheme.errorContainer,
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: Theme.of(context).colorScheme.onErrorContainer,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onErrorContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
