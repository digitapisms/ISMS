import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/payment_providers.dart';
import '../../domain/payment_account.dart';

class EditPaymentAccountDialog extends ConsumerStatefulWidget {
  const EditPaymentAccountDialog({super.key, required this.account});

  final PaymentAccount account;

  @override
  ConsumerState<EditPaymentAccountDialog> createState() =>
      _EditPaymentAccountDialogState();
}

class _EditPaymentAccountDialogState
    extends ConsumerState<EditPaymentAccountDialog> {
  final _formKey = GlobalKey<FormState>();
  final _accountLabelController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _accountLabelController.text = widget.account.accountLabel;
  }

  @override
  void dispose() {
    _accountLabelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              title: const Text('Edit Payment Account'),
              automaticallyImplyLeading: false,
              actions: [
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Account Info (Read-only)
                      Card(
                        color: Colors.grey[100],
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Provider',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                widget.account.provider?.displayName ??
                                    'Unknown',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Status',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(
                                    widget.account.status,
                                  ).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Text(
                                  widget.account.status.toUpperCase(),
                                  style: TextStyle(
                                    color: _getStatusColor(
                                      widget.account.status,
                                    ),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Account Label (Editable)
                      TextFormField(
                        controller: _accountLabelController,
                        decoration: const InputDecoration(
                          labelText: 'Account Label *',
                          border: OutlineInputBorder(),
                          helperText: 'A friendly name for this account',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter an account label';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),

                      // Actions
                      if (widget.account.isActive) ...[
                        OutlinedButton.icon(
                          icon: const Icon(Icons.pause),
                          label: const Text('Suspend Account'),
                          onPressed: () => _suspendAccount(context),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.orange,
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                      if (widget.account.isPending) ...[
                        OutlinedButton.icon(
                          icon: const Icon(Icons.refresh),
                          label: const Text('Resubmit for Verification'),
                          onPressed: () {
                            // TODO: Implement resubmission
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Resubmission coming soon'),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 8),
                      ],
                      OutlinedButton.icon(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        label: const Text(
                          'Delete Account',
                          style: TextStyle(color: Colors.red),
                        ),
                        onPressed: () => _deleteAccount(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Action Buttons
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant,
                border: Border(
                  top: BorderSide(color: Theme.of(context).dividerColor),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isSubmitting
                        ? null
                        : () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _isSubmitting ? null : _handleSubmit,
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Save Changes'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final repo = ref.read(paymentsRepositoryProvider);
      await repo.updateAccountLabel(
        accountId: widget.account.id,
        accountLabel: _accountLabelController.text.trim(),
      );
      ref.invalidate(schoolPaymentAccountsProvider);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update account: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<void> _suspendAccount(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Suspend Account?'),
        content: const Text(
          'This account will be suspended and cannot receive payments. You can reactivate it later.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Suspend'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final repo = ref.read(paymentsRepositoryProvider);
        await repo.updateAccountStatus(
          accountId: widget.account.id,
          status: 'suspended',
        );
        ref.invalidate(schoolPaymentAccountsProvider);

        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Account suspended successfully'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to suspend account: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _deleteAccount(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account?'),
        content: const Text(
          'This action cannot be undone. All payment history will be preserved, but you will no longer be able to use this account.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final repo = ref.read(paymentsRepositoryProvider);
        await repo.deleteAccount(widget.account.id);
        ref.invalidate(schoolPaymentAccountsProvider);

        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Account deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete account: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
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
}
