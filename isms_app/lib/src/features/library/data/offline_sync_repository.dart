import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/network/supabase_client.dart';
import '../domain/offline_sync_queue.dart';
import '../domain/offline_sync_status.dart';

class OfflineSyncRepository {
  static const String _syncQueueBox = 'offline_sync_queue';
  static const String _offlineDataBox = 'offline_data';
  
  final SupabaseClient _client = SupabaseManager.client;
  Box<OfflineSyncQueue>? _syncQueueBoxInstance;
  Box? _offlineDataBoxInstance;
  
  String? _schoolId;

  void setSchoolId(String? schoolId) {
    _schoolId = schoolId;
  }

  Future<void> init() async {
    _syncQueueBoxInstance = await Hive.openBox<OfflineSyncQueue>(_syncQueueBox);
    _offlineDataBoxInstance = await Hive.openBox(_offlineDataBox);
  }

  Future<bool> isOnline() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }

  Future<void> addToSyncQueue({
    required String tableName,
    required OfflineOperation operation,
    required Map<String, dynamic> data,
  }) async {
    final schoolId = _schoolId;
    if (schoolId == null) {
      throw Exception('School context required for offline sync');
    }

    final syncItem = OfflineSyncQueue.create(
      tableName: tableName,
      operation: operation.dbValue,
      data: data,
      schoolId: schoolId,
    );

    await _syncQueueBoxInstance?.put(syncItem.id, syncItem);
  }

  Future<List<OfflineSyncQueue>> getPendingSyncItems() async {
    final allItems = _syncQueueBoxInstance?.values.toList() ?? [];
    return allItems.where((item) => 
      item.syncStatus == 'pending' || 
      item.syncStatus == 'failed'
    ).toList();
  }

  Future<void> saveOfflineData(String key, Map<String, dynamic> data) async {
    await _offlineDataBoxInstance?.put(key, json.encode(data));
  }

  Future<Map<String, dynamic>?> getOfflineData(String key) async {
    final data = _offlineDataBoxInstance?.get(key) as String?;
    return data != null ? Map<String, dynamic>.from(json.decode(data)) : null;
  }

  Future<List<String>> getOfflineDataKeys() async {
    return _offlineDataBoxInstance?.keys.cast<String>().toList() ?? [];
  }

  Future<void> clearOfflineData() async {
    await _offlineDataBoxInstance?.clear();
  }

  Future<void> processSyncQueue() async {
    final pendingItems = await getPendingSyncItems();
    
    for (final item in pendingItems) {
      try {
        // Update status to in progress
        await _syncQueueBoxInstance?.put(
          item.id,
          item.copyWith(
            syncStatus: 'in_progress',
            lastAttemptAt: DateTime.now(),
            attemptCount: item.attemptCount + 1,
          ),
        );

        // Execute the operation
        switch (OfflineOperationX.fromDb(item.operation)) {
          case OfflineOperation.create:
            await _client.from(item.tableName).insert(item.data);
            break;
          case OfflineOperation.update:
            await _client.from(item.tableName).update(item.data);
            break;
          case OfflineOperation.delete:
            await _client.from(item.tableName).delete().eq('id', item.data['id']);
            break;
        }

        // Mark as synced
        await _syncQueueBoxInstance?.put(
          item.id,
          item.copyWith(syncStatus: 'synced'),
        );

      } catch (error) {
        // Mark as failed
        await _syncQueueBoxInstance?.put(
          item.id,
          item.copyWith(
            syncStatus: 'failed',
            errorMessage: error.toString(),
          ),
        );
      }
    }
  }

  Future<void> downloadForOfflineAccess({
    required String tableName,
    required String resourceId,
    required Map<String, dynamic> data,
  }) async {
    final schoolId = _schoolId;
    if (schoolId == null) {
      throw Exception('School context required for offline download');
    }

    final key = '${tableName}_${resourceId}_$schoolId';
    await saveOfflineData(key, data);
  }

  Future<bool> hasOfflineAccess(String tableName, String resourceId) async {
    final schoolId = _schoolId;
    if (schoolId == null) return false;

    final key = '${tableName}_${resourceId}_$schoolId';
    return _offlineDataBoxInstance?.containsKey(key) ?? false;
  }

  Future<void> removeOfflineData(String tableName, String resourceId) async {
    final schoolId = _schoolId;
    if (schoolId == null) return;

    final key = '${tableName}_${resourceId}_$schoolId';
    await _offlineDataBoxInstance?.delete(key);
  }

  Future<int> getOfflineStorageUsage() async {
    final keys = await getOfflineDataKeys();
    int totalSize = 0;
    
    for (final key in keys) {
      final data = _offlineDataBoxInstance?.get(key) as String?;
      totalSize += data?.length ?? 0;
    }
    
    return totalSize;
  }

  Future<void> cleanupOldSyncItems({int days = 30}) async {
    final cutoffDate = DateTime.now().subtract(Duration(days: days));
    final allItems = _syncQueueBoxInstance?.values.toList() ?? [];
    
    for (final item in allItems) {
      if (item.createdAt.isBefore(cutoffDate) && item.syncStatus == 'synced') {
        await _syncQueueBoxInstance?.delete(item.id);
      }
    }
  }
}