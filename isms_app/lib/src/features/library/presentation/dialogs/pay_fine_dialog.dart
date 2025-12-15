import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/library_providers.dart';
import '../../domain/book_fine.dart';

class PayFineDialog extends ConsumerStatefulWidget {
  const PayFineDialog({super.key, required this.fine});

  final BookFine fine;

  @override
  ConsumerState<PayFineDialog> createState() => _PayFineDialogState();
}

class _PayFineDialogState extends ConsumerState<PayFineDialog> {
  final _formKey = GlobalKey<FormState>();
  String _selectedPaymentMethod = 'cash';
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 400,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppBar(
                title: const Text('Pay Fine'),
                automaticallyImplyLeading: false,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Card(
                      color: Colors.blue.withOpacity(0.1),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Text(
                              'Fine Amount',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'PKR ${widget.fine.amount.toStringAsFixed(2)}',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedPaymentMethod,
                      decoration: const InputDecoration(
                        labelText: 'Payment Method *',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'cash', child: Text('Cash')),
                        DropdownMenuItem(
                          value: 'easypaisa',
                          child: Text('Easypaisa'),
                        ),
                        DropdownMenuItem(
                          value: 'jazzcash',
                          child: Text('JazzCash'),
                        ),
                        DropdownMenuItem(
                          value: 'bank_transfer',
                          child: Text('Bank Transfer'),
                        ),
                        DropdownMenuItem(
                          value: 'card',
                          child: Text('Credit/Debit Card'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _selectedPaymentMethod = value);
                        }
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select payment method';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _isLoading
                          ? null
                          : () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _payFine,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Pay Fine'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _payFine() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final repo = ref.read(libraryRepositoryProvider);
      await repo.payFine(widget.fine.id, _selectedPaymentMethod);

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Fine paid successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}

