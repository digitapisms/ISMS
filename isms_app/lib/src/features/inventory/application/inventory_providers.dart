import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../authentication/application/auth_providers.dart';
import '../data/inventory_repository.dart';
import '../domain/inventory_item.dart';

final inventoryRepositoryProvider = Provider<InventoryRepository>((ref) {
  final repo = InventoryRepository();
  final currentUser = ref.watch(currentUserProvider).value;
  if (currentUser?.schoolId != null) {
    repo.setSchoolId(currentUser!.schoolId);
  }
  return repo;
});

final inventoryItemsProvider = FutureProvider<List<InventoryItem>>((ref) async {
  final repo = ref.read(inventoryRepositoryProvider);
  return repo.fetchItems();
});

final lowStockItemsProvider = FutureProvider<List<InventoryItem>>((ref) async {
  final repo = ref.read(inventoryRepositoryProvider);
  return repo.fetchItems(needsRestock: true);
});

final inventoryItemProvider = FutureProvider.autoDispose.family<InventoryItem, String>((ref, itemId) async {
  final repo = ref.read(inventoryRepositoryProvider);
  return repo.fetchItem(itemId);
});

