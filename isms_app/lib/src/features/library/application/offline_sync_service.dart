import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:workmanager/workmanager.dart';

import '../data/offline_sync_repository.dart';

class OfflineSyncService {
  final Ref ref;
  final OfflineSyncRepository _repository;
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;
  Timer? _syncTimer;

  OfflineSyncService(this.ref, this._repository);

  Future<void> initialize() async {
    await _repository.init();
    
    // Start listening for connectivity changes
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen(
      (ConnectivityResult result) {
        if (result != ConnectivityResult.none) {
          // Online - trigger sync
          _triggerSync();
        }
      },
    );

    // Set up periodic sync (every 5 minutes when online)
    _syncTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      _triggerSync();
    });

    // Register background sync with workmanager
    await Workmanager().registerPeriodicTask(
      'offline_sync',
      'offlineSyncTask',
      frequency: const Duration(minutes: 15),
      constraints: Constraints(networkType: NetworkType.connected),
    );
  }

  Future<void> dispose() async {
    await _connectivitySubscription?.cancel();
    _syncTimer?.cancel();
  }

  Future<void> _triggerSync() async {
    final isOnline = await _repository.isOnline();
    if (isOnline) {
      await _repository.processSyncQueue();
    }
  }

  Future<void> downloadResourceForOffline({
    required String tableName,
    required String resourceId,
    required Map<String, dynamic> data,
  }) async {
    await _repository.downloadForOfflineAccess(
      tableName: tableName,
      resourceId: resourceId,
      data: data,
    );
  }

  Future<bool> hasOfflineAccess(String tableName, String resourceId) async {
    return await _repository.hasOfflineAccess(tableName, resourceId);
  }

  Future<void> removeOfflineResource(String tableName, String resourceId) async {
    await _repository.removeOfflineData(tableName, resourceId);
  }

  Future<int> getStorageUsage() async {
    return await _repository.getOfflineStorageUsage();
  }

  Future<void> cleanupOldData({int days = 30}) async {
    await _repository.cleanupOldSyncItems(days: days);
  }

  Future<void> forceSync() async {
    await _triggerSync();
  }

  Future<Map<String, dynamic>?> getOfflineData(String tableName, String resourceId) async {
    final schoolId = _repository.schoolId;
    if (schoolId == null) return null;

    final key = '${tableName}_${resourceId}_$schoolId';
    return await _repository.getOfflineData(key);
  }

  Future<void> queueOfflineOperation({
    required String tableName,
    required String operation,
    required Map<String, dynamic> data,
  }) async {
    final offlineOperation = OfflineOperationX.fromDb(operation);
    await _repository.addToSyncQueue(
      tableName: tableName,
      operation: offlineOperation,
      data: data,
    );
  }
}

// Provider for the offline sync service
final offlineSyncServiceProvider = Provider<OfflineSyncService>((ref) {
  final repository = ref.watch(offlineSyncRepositoryProvider);
  return OfflineSyncService(ref, repository);
});

// Provider for the offline sync repository
final offlineSyncRepositoryProvider = Provider<OfflineSyncRepository>((ref) {
  final repository = OfflineSyncRepository();
  final currentUser = ref.watch(currentUserProvider).value;
  if (currentUser?.schoolId != null) {
    repository.setSchoolId(currentUser!.schoolId);
  }
  return repository;
});

// Provider for connectivity state
final connectivityProvider = StreamProvider<ConnectivityResult>((ref) {
  return Connectivity().onConnectivityChanged;
});

// Provider for sync queue status
final syncQueueStatusProvider = FutureProvider<List<OfflineSyncQueue>>((ref) async {
  final repository = ref.watch(offlineSyncRepositoryProvider);
  return await repository.getPendingSyncItems();
});

// Provider for offline storage usage
final offlineStorageUsageProvider = FutureProvider<int>((ref) async {
  final repository = ref.watch(offlineSyncRepositoryProvider);
  return await repository.getOfflineStorageUsage();
});