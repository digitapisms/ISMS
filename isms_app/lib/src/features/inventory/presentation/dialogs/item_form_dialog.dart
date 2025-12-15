import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/inventory_providers.dart';
import '../../domain/inventory_item.dart';
import '../../../authentication/application/auth_providers.dart';

class ItemFormDialog extends ConsumerStatefulWidget {
  const ItemFormDialog({super.key});

  @override
  ConsumerState<ItemFormDialog> createState() => _ItemFormDialogState();
}

class _ItemFormDialogState extends ConsumerState<ItemFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _itemCodeController = TextEditingController();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _unitController = TextEditingController(text: 'piece');
  final _quantityController = TextEditingController();
  final _minQuantityController = TextEditingController();
  final _unitPriceController = TextEditingController();
  final _locationController = TextEditingController();
  final _supplierController = TextEditingController();

  ConditionStatus _conditionStatus = ConditionStatus.good;
  bool _isConsumable = true;

  @override
  void dispose() {
    _itemCodeController.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    _unitController.dispose();
    _quantityController.dispose();
    _minQuantityController.dispose();
    _unitPriceController.dispose();
    _locationController.dispose();
    _supplierController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final repo = ref.read(inventoryRepositoryProvider);
    final currentUser = ref.read(currentUserProvider).value;
    if (currentUser?.id == null) return;

    final item = InventoryItem(
      id: '',
      schoolId: repo.schoolId ?? '',
      itemCode: _itemCodeController.text.trim(),
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      unit: _unitController.text.trim(),
      currentQuantity: double.tryParse(_quantityController.text.trim()) ?? 0,
      minimumQuantity: double.tryParse(_minQuantityController.text.trim()) ?? 0,
      unitPrice: _unitPriceController.text.trim().isEmpty
          ? null
          : double.tryParse(_unitPriceController.text.trim()),
      location: _locationController.text.trim().isEmpty
          ? null
          : _locationController.text.trim(),
      supplierName: _supplierController.text.trim().isEmpty
          ? null
          : _supplierController.text.trim(),
      conditionStatus: _conditionStatus,
      isConsumable: _isConsumable,
      createdBy: currentUser!.id,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    try {
      await repo.createItem(item);

      if (mounted) {
        Navigator.pop(context);
        ref.invalidate(inventoryItemsProvider);
        ref.invalidate(lowStockItemsProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Item added successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Add Inventory Item',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _itemCodeController,
                  decoration: InputDecoration(
                    labelText: 'Item Code *',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.qr_code),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter item code';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Item Name *',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.inventory_2),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter item name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  decoration: InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.description),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _unitController,
                        decoration: InputDecoration(
                          labelText: 'Unit',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _quantityController,
                        decoration: InputDecoration(
                          labelText: 'Quantity',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _minQuantityController,
                  decoration: InputDecoration(
                    labelText: 'Minimum Quantity (Reorder Level)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _unitPriceController,
                  decoration: InputDecoration(
                    labelText: 'Unit Price (PKR)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.currency_rupee),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _locationController,
                  decoration: InputDecoration(
                    labelText: 'Location',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.location_on),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<ConditionStatus>(
                  value: _conditionStatus,
                  decoration: InputDecoration(
                    labelText: 'Condition',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: ConditionStatus.values.map((status) {
                    return DropdownMenuItem(
                      value: status,
                      child: Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: status.color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(status.displayName),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _conditionStatus = value);
                    }
                  },
                ),
                const SizedBox(height: 16),
                CheckboxListTile(
                  title: const Text('Consumable Item'),
                  value: _isConsumable,
                  onChanged: (value) {
                    setState(() => _isConsumable = value ?? true);
                  },
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _save,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Add Item'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

