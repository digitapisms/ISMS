import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../application/inventory_providers.dart';
import '../../../domain/inventory_item.dart';
import '../../widgets/item_card.dart';

class ItemDetailsScreen extends ConsumerWidget {
  final String itemId;

  const ItemDetailsScreen({super.key, required this.itemId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemAsync = ref.watch(inventoryItemProvider(itemId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Item Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              // TODO: Implement edit functionality
            },
          ),
        ],
      ),
      body: itemAsync.when(
        data: (item) => _buildItemDetails(context, item),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: \$error')),
      ),
    );
  }

  Widget _buildItemDetails(BuildContext context, InventoryItem item) {
    final currencyFormat = NumberFormat.currency(symbol: '₹');
    final dateFormat = DateFormat('dd MMM yyyy HH:mm');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Item Card Header
          ItemCard(item: item, onTap: () {}, showDetails: true),
          const SizedBox(height: 24),

          // Basic Information
          _buildSectionHeader('Basic Information'),
          _buildInfoRow('Item Code', item.itemCode),
          _buildInfoRow('Name', item.name),
          if (item.description != null)
            _buildInfoRow('Description', item.description!),
          _buildInfoRow('Unit', item.unit),
          _buildInfoRow('Category', item.categoryId ?? 'Uncategorized'),
          _buildInfoRow('Location', item.location ?? 'Not specified'),
          _buildInfoRow('Condition', item.conditionStatus.displayName),
          _buildInfoRow('Status', item.isActive ? 'Active' : 'Inactive'),
          _buildInfoRow(
            'Type',
            item.isConsumable ? 'Consumable' : 'Durable Asset',
          ),

          const SizedBox(height: 16),

          // Quantity Information
          _buildSectionHeader('Quantity & Pricing'),
          _buildInfoRow(
            'Current Quantity',
            '${item.currentQuantity} ${item.unit}',
          ),
          _buildInfoRow(
            'Minimum Quantity',
            '${item.minimumQuantity} ${item.unit}',
          ),
          if (item.maximumQuantity != null)
            _buildInfoRow(
              'Maximum Quantity',
              '${item.maximumQuantity} ${item.unit}',
            ),
          if (item.unitPrice != null)
            _buildInfoRow('Unit Price', currencyFormat.format(item.unitPrice)),
          if (item.totalValue != null)
            _buildInfoRow(
              'Total Value',
              currencyFormat.format(item.totalValue),
            ),
          _buildInfoRow('Stock Status', _getStockStatus(item)),

          const SizedBox(height: 16),

          // Supplier Information
          if (item.supplierName != null || item.supplierContact != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader('Supplier Information'),
                if (item.supplierName != null)
                  _buildInfoRow('Supplier', item.supplierName!),
                if (item.supplierContact != null)
                  _buildInfoRow('Contact', item.supplierContact!),
                const SizedBox(height: 16),
              ],
            ),

          // Usage History
          _buildSectionHeader('Usage History'),
          if (item.lastRestockedAt != null)
            _buildInfoRow(
              'Last Restocked',
              dateFormat.format(item.lastRestockedAt!),
            ),
          if (item.lastUsedAt != null)
            _buildInfoRow('Last Used', dateFormat.format(item.lastUsedAt!)),

          const SizedBox(height: 16),

          // System Information
          _buildSectionHeader('System Information'),
          _buildInfoRow('Created By', item.createdBy),
          _buildInfoRow('Created At', dateFormat.format(item.createdAt)),
          _buildInfoRow('Updated At', dateFormat.format(item.updatedAt)),

          if (item.notes != null) ...[
            const SizedBox(height: 16),
            _buildSectionHeader('Notes'),
            Text(item.notes!, style: Theme.of(context).textTheme.bodyMedium),
          ],

          const SizedBox(height: 32),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    // TODO: Implement restock functionality
                  },
                  icon: const Icon(Icons.add_shopping_cart),
                  label: const Text('Restock'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    // TODO: Implement issue functionality
                  },
                  icon: const Icon(Icons.remove_circle_outline),
                  label: const Text('Issue'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.teal,
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(value, style: const TextStyle(color: Colors.black87)),
          ),
        ],
      ),
    );
  }

  String _getStockStatus(InventoryItem item) {
    if (item.currentQuantity <= 0) {
      return 'Out of Stock';
    } else if (item.currentQuantity <= item.minimumQuantity) {
      return 'Low Stock';
    } else if (item.maximumQuantity != null &&
        item.currentQuantity >= item.maximumQuantity!) {
      return 'Overstocked';
    } else {
      return 'In Stock';
    }
  }
}
