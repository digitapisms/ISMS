import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/fee_providers.dart';
import '../dialogs/fee_structure_form_dialog.dart';

/// Tab for managing fee structures
class FeeStructuresTab extends ConsumerWidget {
  const FeeStructuresTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final structuresAsync = ref.watch(feeStructuresProvider);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Fee Structures',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              ElevatedButton.icon(
                onPressed: () async {
                  final result = await showDialog(
                    context: context,
                    builder: (_) => const FeeStructureFormDialog(),
                  );
                  if (result == true) {
                    ref.invalidate(feeStructuresProvider);
                  }
                },
                icon: const Icon(Icons.add),
                label: const Text('Create Structure'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: structuresAsync.when(
              data: (structures) {
                if (structures.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.account_balance_wallet_outlined,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No fee structures found',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Create fee structures to define fees for different categories',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: Colors.grey[600]),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: structures.length,
                  itemBuilder: (context, index) {
                    final structure = structures[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Theme.of(context).primaryColor,
                          child: const Icon(
                            Icons.account_balance_wallet,
                            color: Colors.white,
                          ),
                        ),
                        title: Text(structure.name),
                        subtitle: Text(
                          '${structure.frequency.displayName} • PKR ${structure.amount.toStringAsFixed(2)}',
                        ),
                        trailing: PopupMenuButton(
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              child: const ListTile(
                                leading: Icon(Icons.edit),
                                title: Text('Edit'),
                              ),
                              onTap: () async {
                                Navigator.pop(context);
                                final result = await showDialog(
                                  context: context,
                                  builder: (_) => FeeStructureFormDialog(
                                    feeStructure: structure,
                                  ),
                                );
                                if (result == true) {
                                  ref.invalidate(feeStructuresProvider);
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Error loading fee structures',
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
        ],
      ),
    );
  }
}
