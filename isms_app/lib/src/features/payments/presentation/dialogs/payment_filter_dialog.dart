import 'package:flutter/material.dart';
import 'package:intl/intl.dart';


class PaymentFilterDialog extends StatefulWidget {
  const PaymentFilterDialog({super.key, required this.currentFilters});

  final PaymentFilters currentFilters;

  @override
  State<PaymentFilterDialog> createState() => _PaymentFilterDialogState();
}

class PaymentFilters {
  final String? status;
  final DateTime? startDate;
  final DateTime? endDate;
  final double? minAmount;
  final double? maxAmount;
  final String? paymentMethod;

  const PaymentFilters({
    this.status,
    this.startDate,
    this.endDate,
    this.minAmount,
    this.maxAmount,
    this.paymentMethod,
  });

  PaymentFilters copyWith({
    String? status,
    DateTime? startDate,
    DateTime? endDate,
    double? minAmount,
    double? maxAmount,
    String? paymentMethod,
  }) {
    return PaymentFilters(
      status: status ?? this.status,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      minAmount: minAmount ?? this.minAmount,
      maxAmount: maxAmount ?? this.maxAmount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
    );
  }

  bool get hasFilters {
    return status != null ||
        startDate != null ||
        endDate != null ||
        minAmount != null ||
        maxAmount != null ||
        paymentMethod != null;
  }

  @override
  String toString() {
    return 'PaymentFilters(status: $status, startDate: $startDate, endDate: $endDate, minAmount: $minAmount, maxAmount: $maxAmount, paymentMethod: $paymentMethod)';
  }
}

class _PaymentFilterDialogState extends State<PaymentFilterDialog> {
  late PaymentFilters _filters;
  final _minAmountController = TextEditingController();
  final _maxAmountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _filters = widget.currentFilters;
    _minAmountController.text = _filters.minAmount?.toStringAsFixed(0) ?? '';
    _maxAmountController.text = _filters.maxAmount?.toStringAsFixed(0) ?? '';
  }

  @override
  void dispose() {
    _minAmountController.dispose();
    _maxAmountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Filter Transactions'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Status Filter
            _buildStatusFilter(),
            const SizedBox(height: 16),

            // Date Range
            _buildDateRangeFilter(),
            const SizedBox(height: 16),

            // Amount Range
            _buildAmountRangeFilter(),
            const SizedBox(height: 16),

            // Payment Method
            _buildPaymentMethodFilter(),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(PaymentFilters());
          },
          child: const Text('Clear All'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop(_filters);
          },
          child: const Text('Apply Filters'),
        ),
      ],
    );
  }

  Widget _buildStatusFilter() {
    const statusOptions = ['succeeded', 'pending', 'failed', 'refunded'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Status', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: statusOptions.map((status) {
            final isSelected = _filters.status == status;
            return FilterChip(
              label: Text(status.toUpperCase()),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _filters = _filters.copyWith(
                    status: selected ? status : null,
                  );
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDateRangeFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Date Range', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () async {
                  final date = await showDatePicker(
                    context: context,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                    initialDate: _filters.startDate ?? DateTime.now(),
                  );
                  if (date != null) {
                    setState(() {
                      _filters = _filters.copyWith(startDate: date);
                    });
                  }
                },
                child: Text(
                  _filters.startDate != null
                      ? DateFormat('MMM dd, yyyy').format(_filters.startDate!)
                      : 'Start Date',
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton(
                onPressed: () async {
                  final date = await showDatePicker(
                    context: context,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                    initialDate: _filters.endDate ?? DateTime.now(),
                  );
                  if (date != null) {
                    setState(() {
                      _filters = _filters.copyWith(endDate: date);
                    });
                  }
                },
                child: Text(
                  _filters.endDate != null
                      ? DateFormat('MMM dd, yyyy').format(_filters.endDate!)
                      : 'End Date',
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAmountRangeFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Amount Range (PKR)',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _minAmountController,
                decoration: const InputDecoration(
                  labelText: 'Min',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  final amount = double.tryParse(value);
                  setState(() {
                    _filters = _filters.copyWith(minAmount: amount);
                  });
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextFormField(
                controller: _maxAmountController,
                decoration: const InputDecoration(
                  labelText: 'Max',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  final amount = double.tryParse(value);
                  setState(() {
                    _filters = _filters.copyWith(maxAmount: amount);
                  });
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPaymentMethodFilter() {
    const methods = [
      'stripe',
      'easypaisa',
      'jazzcash',
      'bank_transfer',
      'cash',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Payment Method',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: methods.map((method) {
            final isSelected = _filters.paymentMethod == method;
            return FilterChip(
              label: Text(method.replaceAll('_', ' ').toUpperCase()),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _filters = _filters.copyWith(
                    paymentMethod: selected ? method : null,
                  );
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }
}
