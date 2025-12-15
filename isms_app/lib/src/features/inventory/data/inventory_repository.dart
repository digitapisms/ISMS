import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/network/supabase_client.dart';
import '../domain/inventory_item.dart';

class InventoryRepository {
  SupabaseClient get _client => SupabaseManager.client;
  String? _schoolId;

  void setSchoolId(String? schoolId) {
    _schoolId = schoolId;
  }

  String? get schoolId => _schoolId;

  String _requireSchoolId() {
    final id = _schoolId;
    if (id == null) {
      throw Exception('School context is required');
    }
    return id;
  }

  Map<String, dynamic> _withSchoolId(Map<String, dynamic> data) {
    final id = _schoolId;
    if (id == null) return data;
    return {...data, 'school_id': id};
  }

  Future<InventoryItem> createItem(InventoryItem item) async {
    _requireSchoolId();
    final response = await _client
        .from('inventory_items')
        .insert(_withSchoolId(item.toJson()))
        .select()
        .single();
    return InventoryItem.fromJson(response);
  }

  Future<List<InventoryItem>> fetchItems({
    String? categoryId,
    bool? isActive,
    bool? needsRestock,
  }) async {
    _requireSchoolId();
    var query = _client
        .from('inventory_items')
        .select()
        .eq('school_id', _requireSchoolId());

    if (categoryId != null) {
      query = query.eq('category_id', categoryId);
    }
    if (isActive != null) {
      query = query.eq('is_active', isActive);
    } else {
      query = query.eq('is_active', true);
    }

    final response = await query.order('name');
    var items = (response as List)
        .map((json) => InventoryItem.fromJson(json as Map<String, dynamic>))
        .toList();

    if (needsRestock == true) {
      items = items.where((item) => item.needsRestock).toList();
    }

    return items;
  }

  Future<InventoryItem> updateItem(InventoryItem item) async {
    _requireSchoolId();
    final response = await _client
        .from('inventory_items')
        .update(item.toJson())
        .eq('id', item.id)
        .eq('school_id', _requireSchoolId())
        .select()
        .single();
    return InventoryItem.fromJson(response);
  }

  Future<void> deleteItem(String itemId) async {
    _requireSchoolId();
    await _client
        .from('inventory_items')
        .delete()
        .eq('id', itemId)
        .eq('school_id', _requireSchoolId());
  }

  Future<InventoryItem> fetchItem(String itemId) async {
    _requireSchoolId();
    final response = await _client
        .from('inventory_items')
        .select()
        .eq('id', itemId)
        .eq('school_id', _requireSchoolId())
        .single();
    return InventoryItem.fromJson(response);
  }
}

