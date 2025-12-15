import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Manages offline functionality and connectivity state
class OfflineManager {
  static const String _offlineDataBox = 'offline_data';
  static Box? _offlineBox;

  static Future<void> init() async {
    _offlineBox = await Hive.openBox(_offlineDataBox);
  }

  /// Check if device is online
  static Future<bool> isOnline() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }

  /// Stream of connectivity changes
  static Stream<ConnectivityResult> connectivityStream() {
    return Connectivity().onConnectivityChanged;
  }

  /// Save data for offline access
  static Future<void> saveOfflineData(String key, Map<String, dynamic> data) async {
    await _offlineBox?.put(key, data);
  }

  /// Get offline data
  static Map<String, dynamic>? getOfflineData(String key) {
    return _offlineBox?.get(key) as Map<String, dynamic>?;
  }

  /// Clear offline data
  static Future<void> clearOfflineData() async {
    await _offlineBox?.clear();
  }

  /// Get all offline data keys
  static List<String> getOfflineKeys() {
    return _offlineBox?.keys.cast<String>().toList() ?? [];
  }
}

/// Provider for connectivity state
final connectivityProvider = StreamProvider<ConnectivityResult>((ref) {
  return OfflineManager.connectivityStream();
});

/// Provider for online/offline status
final isOnlineProvider = StreamProvider<bool>((ref) async* {
  yield await OfflineManager.isOnline();
  yield* OfflineManager.connectivityStream().asyncMap((_) async {
    return await OfflineManager.isOnline();
  });
});

