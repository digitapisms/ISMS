import 'package:flutter/material.dart';

class PaymentSearchDialog extends StatefulWidget {
  const PaymentSearchDialog({super.key, required this.initialQuery});

  final String initialQuery;

  @override
  State<PaymentSearchDialog> createState() => _PaymentSearchDialogState();
}

class _PaymentSearchDialogState extends State<PaymentSearchDialog> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.text = widget.initialQuery;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Search Transactions'),
      content: TextField(
        controller: _searchController,
        decoration: const InputDecoration(
          labelText: 'Search by payer name, reference, or amount',
          border: OutlineInputBorder(),
          prefixIcon: Icon(Icons.search),
        ),
        autofocus: true,
        onSubmitted: (value) {
          Navigator.of(context).pop(value);
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop(_searchController.text);
          },
          child: const Text('Search'),
        ),
      ],
    );
  }
}