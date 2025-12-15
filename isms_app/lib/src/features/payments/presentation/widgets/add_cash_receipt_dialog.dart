import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../application/payment_providers.dart';
import '../../../student_management/application/student_providers.dart';
import '../../../student_management/domain/student.dart';

class AddCashReceiptDialog extends ConsumerStatefulWidget {
  const AddCashReceiptDialog({super.key});

  @override
  ConsumerState<AddCashReceiptDialog> createState() =>
      _AddCashReceiptDialogState();
}

class _AddCashReceiptDialogState extends ConsumerState<AddCashReceiptDialog> {
  final _formKey = GlobalKey<FormState>();
  final _payerNameController = TextEditingController();
  final _amountController = TextEditingController();
  final _receiptNumberController = TextEditingController();
  final _notesController = TextEditingController();
  DateTime? _selectedDate;
  Student? _selectedStudent;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _payerNameController.dispose();
    _amountController.dispose();
    _receiptNumberController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final studentsAsync = ref.watch(studentsProvider);

    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 700),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              title: const Text('Record Cash Payment'),
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
                      // Payer Name
                      TextFormField(
                        controller: _payerNameController,
                        decoration: const InputDecoration(
                          labelText: 'Payer Name *',
                          border: OutlineInputBorder(),
                          helperText: 'Name of the person who made the payment',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter payer name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Student Selection (Optional)
                      studentsAsync.when(
                        data: (students) {
                          if (students.isEmpty) {
                            return const SizedBox.shrink();
                          }
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              DropdownButtonFormField<Student>(
                                initialValue: _selectedStudent,
                                decoration: const InputDecoration(
                                  labelText: 'Student (Optional)',
                                  border: OutlineInputBorder(),
                                  helperText:
                                      'Link this payment to a student if applicable',
                                ),
                                items: [
                                  const DropdownMenuItem<Student>(
                                    value: null,
                                    child: Text('None'),
                                  ),
                                  ...students.map((student) {
                                    return DropdownMenuItem(
                                      value: student,
                                      child: Text(
                                        '${student.fullName} (${student.admissionNo})',
                                      ),
                                    );
                                  }),
                                ],
                                onChanged: (student) {
                                  setState(() {
                                    _selectedStudent = student;
                                  });
                                },
                              ),
                              const SizedBox(height: 16),
                            ],
                          );
                        },
                        loading: () => const SizedBox.shrink(),
                        error: (_, __) => const SizedBox.shrink(),
                      ),

                      // Amount
                      TextFormField(
                        controller: _amountController,
                        decoration: const InputDecoration(
                          labelText: 'Amount (PKR) *',
                          border: OutlineInputBorder(),
                          prefixText: 'PKR ',
                          helperText: 'Enter the payment amount',
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter amount';
                          }
                          final amount = double.tryParse(value);
                          if (amount == null || amount <= 0) {
                            return 'Please enter a valid amount';
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
                            initialDate: _selectedDate ?? DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now().add(
                              const Duration(days: 365),
                            ),
                          );
                          if (date != null) {
                            setState(() {
                              _selectedDate = date;
                            });
                          }
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Payment Date *',
                            border: OutlineInputBorder(),
                            helperText:
                                'Select the date when payment was received',
                            suffixIcon: Icon(Icons.calendar_today),
                          ),
                          child: Text(
                            _selectedDate != null
                                ? DateFormat(
                                    'MMM dd, yyyy',
                                  ).format(_selectedDate!)
                                : 'Select date',
                            style: _selectedDate != null
                                ? null
                                : TextStyle(color: Colors.grey[600]),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Receipt Number (Optional)
                      TextFormField(
                        controller: _receiptNumberController,
                        decoration: const InputDecoration(
                          labelText: 'Receipt Number (Optional)',
                          border: OutlineInputBorder(),
                          helperText: 'Enter receipt number if available',
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Notes (Optional)
                      TextFormField(
                        controller: _notesController,
                        decoration: const InputDecoration(
                          labelText: 'Notes (Optional)',
                          border: OutlineInputBorder(),
                          helperText: 'Additional notes about this payment',
                        ),
                        maxLines: 3,
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
                        : const Text('Record Payment'),
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
    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a payment date'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final amount = double.parse(_amountController.text.trim());

      await ref.read(
        addCashReceiptProvider(
          CashReceiptRequest(
            payerName: _payerNameController.text.trim(),
            amount: amount,
            paymentDate: _selectedDate,
            receiptNumber: _receiptNumberController.text.trim().isEmpty
                ? null
                : _receiptNumberController.text.trim(),
            notes: _notesController.text.trim().isEmpty
                ? null
                : _notesController.text.trim(),
            studentId: _selectedStudent?.id,
          ),
        ).future,
      );

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cash payment recorded successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to record payment: ${e.toString()}'),
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
