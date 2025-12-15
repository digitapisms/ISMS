import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../application/fee_providers.dart';
import '../../domain/fee_invoice.dart';
import '../../../school_registration/application/school_providers.dart';

class PaymentIntegrationDialog extends ConsumerStatefulWidget {
  const PaymentIntegrationDialog({super.key, required this.invoice});

  final FeeInvoice invoice;

  @override
  ConsumerState<PaymentIntegrationDialog> createState() =>
      _PaymentIntegrationDialogState();
}

class _PaymentIntegrationDialogState
    extends ConsumerState<PaymentIntegrationDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _referenceController = TextEditingController();
  final _notesController = TextEditingController();

  String _paymentMethod = 'cash';
  DateTime _paymentDate = DateTime.now();
  String? _selectedTransactionId;
  String? _selectedCashReceiptId;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final outstanding = widget.invoice.outstandingAmount;
    _amountController.text = outstanding > 0
        ? outstanding.toStringAsFixed(2)
        : '0';
  }

  @override
  void dispose() {
    _amountController.dispose();
    _referenceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount')),
      );
      return;
    }

    if (amount > widget.invoice.outstandingAmount) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Amount cannot exceed outstanding amount (PKR ${widget.invoice.outstandingAmount.toStringAsFixed(2)})',
          ),
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final school = ref.read(currentSchoolProvider);
      if (school == null) throw Exception('School not found');

      final repo = ref.read(feeRepositoryProvider);
      await repo.recordFeePayment(
        schoolId: school.id,
        invoiceId: widget.invoice.id,
        studentId: widget.invoice.studentId,
        paymentMethod: _paymentMethod,
        amount: amount,
        paymentDate: _paymentDate,
        paymentTransactionId: _selectedTransactionId,
        cashReceiptId: _selectedCashReceiptId,
        paymentReference: _referenceController.text.trim().isEmpty
            ? null
            : _referenceController.text.trim(),
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );

      if (mounted) {
        ref.invalidate(feeInvoicesProvider);
        ref.invalidate(studentFeeInvoicesProvider(widget.invoice.studentId));
        ref.invalidate(invoicePaymentsProvider(widget.invoice.id));
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment recorded successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppBar(
                title: const Text('Record Payment'),
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
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Invoice Info
                      Card(
                        color: Theme.of(context).primaryColor.withOpacity(0.1),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Invoice: ${widget.invoice.invoiceNumber}',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Total: PKR ${widget.invoice.totalAmount.toStringAsFixed(2)}',
                              ),
                              Text(
                                'Paid: PKR ${widget.invoice.paidAmount.toStringAsFixed(2)}',
                              ),
                              Text(
                                'Outstanding: PKR ${widget.invoice.outstandingAmount.toStringAsFixed(2)}',
                                style: TextStyle(
                                  color: Colors.red[700],
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Payment Method
                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: 'Payment Method *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.payment),
                        ),
                        value: _paymentMethod,
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
                            setState(() {
                              _paymentMethod = value;
                              _selectedTransactionId = null;
                              _selectedCashReceiptId = null;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      // Amount
                      TextFormField(
                        controller: _amountController,
                        decoration: const InputDecoration(
                          labelText: 'Payment Amount (PKR) *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.currency_rupee),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Amount is required';
                          }
                          final amount = double.tryParse(value.trim());
                          if (amount == null || amount <= 0) {
                            return 'Please enter a valid amount';
                          }
                          if (amount > widget.invoice.outstandingAmount) {
                            return 'Amount exceeds outstanding balance';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      // Payment Date
                      InkWell(
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: _paymentDate,
                            firstDate: DateTime.now().subtract(
                              const Duration(days: 365),
                            ),
                            lastDate: DateTime.now(),
                          );
                          if (date != null) {
                            setState(() {
                              _paymentDate = date;
                            });
                          }
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Payment Date *',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.calendar_today),
                          ),
                          child: Text(
                            DateFormat('yyyy-MM-dd').format(_paymentDate),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Payment Reference
                      TextFormField(
                        controller: _referenceController,
                        decoration: const InputDecoration(
                          labelText: 'Payment Reference',
                          hintText: 'Transaction ID, Cheque No, etc.',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.receipt),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Notes
                      TextFormField(
                        controller: _notesController,
                        decoration: const InputDecoration(
                          labelText: 'Notes',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.note),
                        ),
                        maxLines: 2,
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _isSaving
                          ? null
                          : () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: _isSaving ? null : _save,
                      child: _isSaving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Record Payment'),
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
}
