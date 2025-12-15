import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

/// Service for managing scheduled backups
class ScheduledBackupService {
  static const String _backupTaskName = 'scheduledBackupTask';
  static const String _prefEnabled = 'scheduled_backup_enabled';
  static const String _prefFrequency = 'scheduled_backup_frequency';
  static const String _prefTime = 'scheduled_backup_time';

  /// Initialize scheduled backup service
  static Future<void> initialize() async {
    await Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: false,
    );
  }

  /// Enable scheduled backups
  static Future<void> enableScheduledBackup({
    required BackupFrequency frequency,
    required String time, // Format: "HH:mm" (24-hour)
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefEnabled, true);
    await prefs.setString(_prefFrequency, frequency.name);
    await prefs.setString(_prefTime, time);

    // Cancel existing tasks
    await Workmanager().cancelByUniqueName(_backupTaskName);

    // Schedule new task
    final duration = _getDurationForFrequency(frequency);
    await Workmanager().registerPeriodicTask(
      _backupTaskName,
      _backupTaskName,
      frequency: duration,
      initialDelay: _calculateInitialDelay(time),
      constraints: Constraints(
        networkType: NetworkType.connected,
        requiresBatteryNotLow: false,
        requiresCharging: false,
        requiresDeviceIdle: false,
        requiresStorageNotLow: false,
      ),
    );
  }

  /// Disable scheduled backups
  static Future<void> disableScheduledBackup() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefEnabled, false);
    await Workmanager().cancelByUniqueName(_backupTaskName);
  }

  /// Get current backup schedule
  static Future<BackupSchedule?> getSchedule() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool(_prefEnabled) ?? false;
    if (!enabled) return null;

    final frequencyStr = prefs.getString(_prefFrequency);
    final time = prefs.getString(_prefTime) ?? '02:00';

    if (frequencyStr == null) return null;

    BackupFrequency? frequency;
    try {
      frequency = BackupFrequency.values.firstWhere(
        (f) => f.name == frequencyStr,
      );
    } catch (_) {
      return null;
    }

    return BackupSchedule(
      enabled: true,
      frequency: frequency,
      time: time,
    );
  }

  static Duration _getDurationForFrequency(BackupFrequency frequency) {
    switch (frequency) {
      case BackupFrequency.daily:
        return const Duration(hours: 24);
      case BackupFrequency.weekly:
        return const Duration(days: 7);
      case BackupFrequency.monthly:
        return const Duration(days: 30);
    }
  }

  static Duration _calculateInitialDelay(String time) {
    final parts = time.split(':');
    if (parts.length != 2) return const Duration(hours: 2);

    final hour = int.tryParse(parts[0]) ?? 2;
    final minute = int.tryParse(parts[1]) ?? 0;

    final now = DateTime.now();
    var scheduledTime = DateTime(
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    if (scheduledTime.isBefore(now)) {
      scheduledTime = scheduledTime.add(const Duration(days: 1));
    }

    return scheduledTime.difference(now);
  }
}

/// Backup frequency options
enum BackupFrequency {
  daily,
  weekly,
  monthly,
}

/// Backup schedule configuration
class BackupSchedule {
  final bool enabled;
  final BackupFrequency frequency;
  final String time;

  BackupSchedule({
    required this.enabled,
    required this.frequency,
    required this.time,
  });
}

/// Callback dispatcher for background tasks
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (task == ScheduledBackupService._backupTaskName) {
      try {
        // Note: In a real implementation, you'd need to initialize
        // repositories and providers here. For now, this is a placeholder.
        // The actual backup would be triggered via Supabase Edge Function
        // or a separate service.
        print('Scheduled backup executed at ${DateTime.now()}');
        return Future.value(true);
      } catch (e) {
        print('Backup task failed: $e');
        return Future.value(false);
      }
    }
    return Future.value(true);
  });
}

