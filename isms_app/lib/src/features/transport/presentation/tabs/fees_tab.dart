import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/transport_providers.dart';
import '../../domain/transport_type.dart';

class FeesTab extends ConsumerWidget {
  const FeesTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feesAsync = ref.watch(transportFeesProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Transport Fees',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Fee management coming soon')),
                  );
                },
                icon: const Icon(Icons.payment),
                label: const Text('Collect Fee'),
              ),
            ],
          ),
        ),
        Expanded(
          child: feesAsync.when(
            data: (fees) {
              if (fees.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.payment_outlined,
                          size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'No transport fees found',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: fees.length,
                itemBuilder: (context, index) {
                  final fee = fees[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: const Icon(Icons.payment),
                      title: Text('PKR ${fee.amount.toStringAsFixed(2)}'),
                      subtitle: Text(
                        'Month: ${fee.feeMonth.month}/${fee.feeMonth.year} | Status: ${fee.status.dbValue}',
                      ),
                      trailing: fee.isOverdue
                          ? const Chip(
                              label: Text('Overdue'),
                              backgroundColor: Colors.red,
                            )
                          : fee.status == FeeStatus.paid
                              ? const Chip(
                                  label: Text('Paid'),
                                  backgroundColor: Colors.green,
                                )
                              : const Chip(
                                  label: Text('Pending'),
                                  backgroundColor: Colors.orange,
                                ),
                    ),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(
              child: Text('Error: $error'),
            ),
          ),
        ),
      ],
    );
  }
}

