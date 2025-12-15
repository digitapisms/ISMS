import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../authentication/application/auth_providers.dart';
import '../../authentication/domain/user_role.dart';
import '../application/inventory_providers.dart';
import 'widgets/item_card.dart';
import 'dialogs/item_form_dialog.dart';

class InventoryScreen extends ConsumerStatefulWidget {
  const InventoryScreen({super.key});

  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen> {
  bool _showLowStockOnly = false;

  @override
  Widget build(BuildContext context) {
    final itemsAsync = _showLowStockOnly
        ? ref.watch(lowStockItemsProvider)
        : ref.watch(inventoryItemsProvider);
    final currentUser = ref.watch(currentUserProvider).value;
    final isAdmin = currentUser?.role == UserRole.admin ||
        currentUser?.role == UserRole.principal ||
        currentUser?.role == UserRole.staff;

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 120,
              floating: false,
              pinned: true,
              elevation: 0,
              flexibleSpace: FlexibleSpaceBar(
                title: const Text(
                  'Inventory Management',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.teal[700]!,
                        Colors.cyan[700]!,
                      ],
                    ),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.inventory_2,
                      size: 64,
                      color: Colors.white70,
                    ),
                  ),
                ),
              ),
            ),
          ];
        },
        body: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.grey[100],
              child: Row(
                children: [
                  Expanded(
                    child: CheckboxListTile(
                      title: const Text('Show Low Stock Only'),
                      value: _showLowStockOnly,
                      onChanged: (value) {
                        setState(() => _showLowStockOnly = value ?? false);
                      },
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: itemsAsync.when(
                data: (items) {
                  if (items.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.inventory_2_outlined,
                            size: 80,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'No items found',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: ItemCard(
                          item: items[index],
                          onTap: () {
                            // TODO: Show item details
                          },
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
        ),
      ),
      floatingActionButton: isAdmin
          ? FloatingActionButton.extended(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => const ItemFormDialog(),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Add Item'),
            )
          : null,
    );
  }
}

