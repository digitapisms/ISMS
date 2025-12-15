import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/payment_providers.dart';
import '../../domain/payment_provider.dart';

class AddPaymentAccountDialog extends ConsumerStatefulWidget {
  const AddPaymentAccountDialog({super.key});

  @override
  ConsumerState<AddPaymentAccountDialog> createState() =>
      _AddPaymentAccountDialogState();
}

class _AddPaymentAccountDialogState
    extends ConsumerState<AddPaymentAccountDialog> {
  final _formKey = GlobalKey<FormState>();
  PaymentProvider? _selectedProvider;
  final Map<String, TextEditingController> _fieldControllers = {};
  final _accountLabelController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _accountLabelController.dispose();
    for (final controller in _fieldControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final providersAsync = ref.watch(paymentProvidersProvider);

    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              title: const Text('Add Payment Account'),
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
                child: providersAsync.when(
                  data: (providers) {
                    if (providers.isEmpty) {
                      return const Center(
                        child: Text('No payment providers available'),
                      );
                    }

                    return Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Provider Selection
                          DropdownButtonFormField<PaymentProvider>(
                            initialValue: _selectedProvider,
                            decoration: const InputDecoration(
                              labelText: 'Payment Provider *',
                              border: OutlineInputBorder(),
                              helperText:
                                  'Select the payment method you want to configure',
                            ),
                            items: providers.map((provider) {
                              return DropdownMenuItem(
                                value: provider,
                                child: Text(provider.displayName),
                              );
                            }).toList(),
                            onChanged: (provider) {
                              setState(() {
                                _selectedProvider = provider;
                                // Clear previous field controllers
                                for (final controller
                                    in _fieldControllers.values) {
                                  controller.dispose();
                                }
                                _fieldControllers.clear();

                                // Create controllers for required fields
                                if (provider != null) {
                                  for (final field in provider.requiredFields) {
                                    _fieldControllers[field] =
                                        TextEditingController();
                                  }
                                }
                              });
                            },
                            validator: (value) {
                              if (value == null) {
                                return 'Please select a payment provider';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Account Label
                          TextFormField(
                            controller: _accountLabelController,
                            decoration: const InputDecoration(
                              labelText: 'Account Label',
                              border: OutlineInputBorder(),
                              helperText:
                                  'A friendly name for this account (e.g., "Main Easypaisa Account")',
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter an account label';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),

                          // Dynamic Fields based on Provider
                          if (_selectedProvider != null) ...[
                            Text(
                              'Account Details',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 12),
                            ..._selectedProvider!.requiredFields.map((field) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: TextFormField(
                                  controller: _fieldControllers[field],
                                  decoration: InputDecoration(
                                    labelText: _formatFieldLabel(field),
                                    border: const OutlineInputBorder(),
                                    helperText: _getFieldHelperText(field),
                                  ),
                                  obscureText: _isSensitiveField(field),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'This field is required';
                                    }
                                    return null;
                                  },
                                ),
                              );
                            }),
                          ],
                        ],
                      ),
                    );
                  },
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  error: (error, stack) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 48,
                            color: Colors.red[300],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Failed to load payment providers',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            error.toString(),
                            style: Theme.of(context).textTheme.bodySmall,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // Action Buttons
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
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
                        : const Text('Add Account'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatFieldLabel(String field) {
    // Convert snake_case to Title Case
    return field
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  String _getFieldHelperText(String field) {
    final lower = field.toLowerCase();
    if (lower.contains('account') || lower.contains('number')) {
      return 'Enter your account number';
    } else if (lower.contains('phone') || lower.contains('mobile')) {
      return 'Enter your mobile number';
    } else if (lower.contains('email')) {
      return 'Enter your email address';
    } else if (lower.contains('key') || lower.contains('secret')) {
      return 'Keep this information secure';
    } else if (lower.contains('name')) {
      return 'Enter the account holder name';
    }
    return 'Enter the required information';
  }

  bool _isSensitiveField(String field) {
    final lower = field.toLowerCase();
    return lower.contains('password') ||
        lower.contains('secret') ||
        lower.contains('key') ||
        lower.contains('token');
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedProvider == null) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Collect field values
      final fields = <String, String>{};
      for (final entry in _fieldControllers.entries) {
        fields[entry.key] = entry.value.text.trim();
      }

      await ref.read(
        paymentAccountSubmitProvider(
          PaymentAccountRequest(
            providerKey: _selectedProvider!.providerKey,
            fields: fields,
            accountLabel: _accountLabelController.text.trim(),
          ),
        ).future,
      );

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment account added successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add account: ${e.toString()}'),
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
}
