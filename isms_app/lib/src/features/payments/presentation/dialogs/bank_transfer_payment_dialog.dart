import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'dart:io';

import '../../../../core/network/supabase_client.dart';

class BankTransferPaymentDialog extends ConsumerStatefulWidget {
  const BankTransferPaymentDialog({
    super.key,
    required this.amount,
    required this.currency,
    this.referenceCode,
    this.payerName,
    this.payerEmail,
    this.payerPhone,
  });

  final double amount;
  final String currency;
  final String? referenceCode;
  final String? payerName;
  final String? payerEmail;
  final String? payerPhone;

  @override
  ConsumerState<BankTransferPaymentDialog> createState() =>
      _BankTransferPaymentDialogState();
}

class _BankTransferPaymentDialogState
    extends ConsumerState<BankTransferPaymentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _bankNameController = TextEditingController();
  final _accountNumberController = TextEditingController();
  final _referenceNumberController = TextEditingController();
  final _transferDateController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime? _selectedTransferDate;
  File? _receiptFile;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _transferDateController.text = DateFormat.yMd().format(DateTime.now());
    _selectedTransferDate = DateTime.now();
  }

  @override
  void dispose() {
    _bankNameController.dispose();
    _accountNumberController.dispose();
    _referenceNumberController.dispose();
    _transferDateController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickReceiptFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _receiptFile = File(result.files.single.path!);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick file: \$e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _uploadReceiptAndCreateTransaction() async {
    if (!_formKey.currentState!.validate()) return;
    if (_receiptFile == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please upload a bank transfer receipt'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Upload receipt file to Supabase storage
      final fileName =
          'bank_receipt_\${DateTime.now().millisecondsSinceEpoch}_\${_receiptFile!.path.split(' /
          ').last}';
      final fileBytes = await _receiptFile!.readAsBytes();

      // Upload receipt file to Supabase storage
      await SupabaseManager.client.storage
          .from('bank-receipts')
          .uploadBinary(fileName, fileBytes);

      // Get public URL for the uploaded file
      final publicUrlResponse = SupabaseManager.client.storage
          .from('bank-receipts')
          .getPublicUrl(fileName);

      // Create payment transaction
      final transactionResponse = await SupabaseManager.client
          .from('payment_transactions')
          .insert({
            'amount': widget.amount,
            'currency': widget.currency,
            'status': 'pending',
            'payment_method': 'bank_transfer',
            'reference_code': widget.referenceCode,
            'payer_name': widget.payerName,
            'payer_email': widget.payerEmail,
            'payer_phone': widget.payerPhone,
            'initiated_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();

      final transaction = transactionResponse;

      // Create bank transfer receipt record
      await SupabaseManager.client.from('bank_transfer_receipts').insert({
        'transaction_id': transaction['id'],
        'bank_name': _bankNameController.text.trim(),
        'account_number': _accountNumberController.text.trim(),
        'transfer_date': _selectedTransferDate!.toIso8601String().split('T')[0],
        'amount': widget.amount,
        'receipt_image_url': publicUrlResponse.publicUrl,
        'reference_number': _referenceNumberController.text.trim(),
        'status': 'pending',
      });

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bank transfer payment submitted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to process payment: \$e'),
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

  Future<void> _selectTransferDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedTransferDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );

    if (pickedDate != null) {
      setState(() {
        _selectedTransferDate = pickedDate;
        _transferDateController.text = DateFormat.yMd().format(pickedDate);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 700),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              title: const Text('Bank Transfer Payment'),
              automaticallyImplyLeading: false,
              actions: [
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Amount display
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              const Text(
                                'Payment Amount',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                NumberFormat.currency(
                                  symbol: 'PKR ',
                                  decimalDigits: 2,
                                ).format(widget.amount),
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Bank details
                      TextFormField(
                        controller: _bankNameController,
                        decoration: const InputDecoration(
                          labelText: 'Bank Name *',
                          border: OutlineInputBorder(),
                          hintText: 'e.g., HBL, UBL, MCB',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter bank name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),

                      TextFormField(
                        controller: _accountNumberController,
                        decoration: const InputDecoration(
                          labelText: 'Account Number',
                          border: OutlineInputBorder(),
                          hintText: 'Optional',
                        ),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 12),

                      TextFormField(
                        controller: _referenceNumberController,
                        decoration: const InputDecoration(
                          labelText: 'Transaction Reference Number *',
                          border: OutlineInputBorder(),
                          hintText: 'e.g., TRX123456789',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter reference number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),

                      // Transfer date
                      TextFormField(
                        controller: _transferDateController,
                        decoration: const InputDecoration(
                          labelText: 'Transfer Date *',
                          border: OutlineInputBorder(),
                          suffixIcon: Icon(Icons.calendar_today),
                        ),
                        readOnly: true,
                        onTap: _selectTransferDate,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please select transfer date';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),

                      // Receipt upload
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'Bank Receipt *',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          OutlinedButton(
                            onPressed: _pickReceiptFile,
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.all(16),
                              side: BorderSide(
                                color: _receiptFile != null
                                    ? Colors.green
                                    : Theme.of(context).colorScheme.primary,
                              ),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.receipt,
                                  size: 32,
                                  color: _receiptFile != null
                                      ? Colors.green
                                      : Theme.of(context).colorScheme.primary,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _receiptFile != null
                                      ? 'Receipt Selected: \${_receiptFile!.path.split(' /
                                            ').last}'
                                      : 'Upload Bank Receipt',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: _receiptFile != null
                                        ? Colors.green
                                        : Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                                if (_receiptFile != null)
                                  const Text(
                                    '✓ Ready to submit',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.green,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Upload a clear image or PDF of your bank transfer receipt',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Additional notes
                      TextFormField(
                        controller: _notesController,
                        decoration: const InputDecoration(
                          labelText: 'Additional Notes (Optional)',
                          border: OutlineInputBorder(),
                          hintText:
                              'Any additional information about this transfer',
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 24),

                      // Submit button
                      ElevatedButton(
                        onPressed: _isSubmitting
                            ? null
                            : _uploadReceiptAndCreateTransaction,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.all(16),
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Submit Payment',
                                style: TextStyle(fontSize: 16),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
