import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/student_providers.dart';

class ApplicationFeePaymentScreen extends ConsumerStatefulWidget {
  const ApplicationFeePaymentScreen({
    super.key,
    required this.applicationId,
    required this.amount,
  });

  final String applicationId;
  final double amount;

  @override
  ConsumerState<ApplicationFeePaymentScreen> createState() =>
      _ApplicationFeePaymentScreenState();
}

class _ApplicationFeePaymentScreenState
    extends ConsumerState<ApplicationFeePaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _cardNumberController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();
  final _cardNameController = TextEditingController();
  bool _isProcessing = false;
  String? _selectedPaymentMethod = 'card';

  @override
  void dispose() {
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    _cardNameController.dispose();
    super.dispose();
  }

  Future<void> _processPayment() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      // Simulate payment processing
      await Future.delayed(const Duration(seconds: 2));

      final repo = ref.read(studentRepositoryProvider);

      // In production, integrate with actual payment gateway (Stripe, Razorpay, etc.)
      // For now, we'll simulate a successful payment
      final transactionId = 'TXN${DateTime.now().millisecondsSinceEpoch}';

      await repo.updatePaymentStatus(
        applicationId: widget.applicationId,
        status: 'paid',
        transactionId: transactionId,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Payment successful!'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Payment failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Application Fee Payment')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                color: Colors.blue.withOpacity(0.1),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: Colors.blue),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Application Fee',
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            Text(
                              '₹${widget.amount.toStringAsFixed(2)}',
                              style: Theme.of(context).textTheme.headlineMedium
                                  ?.copyWith(
                                    color: Colors.blue,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Payment Method',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(
                    value: 'card',
                    label: Text('Card'),
                    icon: Icon(Icons.credit_card),
                  ),
                  ButtonSegment(
                    value: 'upi',
                    label: Text('UPI'),
                    icon: Icon(Icons.account_balance_wallet),
                  ),
                ],
                selected: {_selectedPaymentMethod!},
                onSelectionChanged: (Set<String> newSelection) {
                  setState(() {
                    _selectedPaymentMethod = newSelection.first;
                  });
                },
              ),
              const SizedBox(height: 24),
              if (_selectedPaymentMethod == 'card') ...[
                TextFormField(
                  controller: _cardNameController,
                  decoration: const InputDecoration(
                    labelText: 'Cardholder Name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _cardNumberController,
                  decoration: const InputDecoration(
                    labelText: 'Card Number',
                    border: OutlineInputBorder(),
                    hintText: '1234 5678 9012 3456',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Required';
                    if (v.replaceAll(' ', '').length < 16) {
                      return 'Invalid card number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _expiryController,
                        decoration: const InputDecoration(
                          labelText: 'Expiry (MM/YY)',
                          border: OutlineInputBorder(),
                          hintText: '12/25',
                        ),
                        validator: (v) =>
                            (v == null || v.isEmpty) ? 'Required' : null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _cvvController,
                        decoration: const InputDecoration(
                          labelText: 'CVV',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        obscureText: true,
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Required';
                          if (v.length < 3) return 'Invalid CVV';
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
              ] else ...[
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'UPI ID',
                    border: OutlineInputBorder(),
                    hintText: 'yourname@upi',
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Required';
                    if (!v.contains('@')) return 'Invalid UPI ID';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(Icons.qr_code),
                        SizedBox(width: 12),
                        Expanded(child: Text('Scan QR code to pay via UPI')),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isProcessing ? null : _processPayment,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isProcessing
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text('Pay ₹${widget.amount.toStringAsFixed(2)}'),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Note: This is a demo payment. In production, integrate with Stripe, Razorpay, or your preferred payment gateway.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
