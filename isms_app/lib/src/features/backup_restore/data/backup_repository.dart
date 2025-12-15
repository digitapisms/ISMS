import 'dart:convert';
import 'dart:io';

import 'package:csv/csv.dart';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/network/supabase_client.dart';

/// Repository for backup and restore operations
class BackupRepository {
  final SupabaseClient _client = SupabaseManager.client;

  String? _schoolId;

  void setSchoolId(String? schoolId) {
    _schoolId = schoolId;
  }

  String _requireSchoolId() {
    if (_schoolId == null) {
      throw Exception('School context required');
    }
    return _schoolId!;
  }

  /// Export all school data to JSON
  Future<Map<String, dynamic>> exportAllData() async {
    final schoolId = _requireSchoolId();

    // Export all major tables
    final data = <String, dynamic>{
      'export_date': DateTime.now().toIso8601String(),
      'school_id': schoolId,
      'students': await _exportTable('students', schoolId),
      'users': await _exportTable('users', schoolId),
      'classes': await _exportTable('classes', schoolId),
      'sections': await _exportTable('sections', schoolId),
      'attendance': await _exportTable('attendance', schoolId),
      'fee_invoices': await _exportTable('fee_invoices', schoolId),
      'fee_payments': await _exportTable('fee_payments', schoolId),
      'examinations': await _exportTable('examinations', schoolId),
      'grades': await _exportTable('grades', schoolId),
      'assignments': await _exportTable('assignments', schoolId),
      'notifications': await _exportTable('notifications', schoolId),
    };

    return data;
  }

  Future<List<Map<String, dynamic>>> _exportTable(
    String tableName,
    String schoolId,
  ) async {
    try {
      final response = await _client
          .from(tableName)
          .select()
          .eq('school_id', schoolId);
      return (response as List).cast<Map<String, dynamic>>();
    } catch (e) {
      return [];
    }
  }

  /// Save backup to file
  Future<File> saveBackupToFile(Map<String, dynamic> data) async {
    final directory = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    final file = File('${directory.path}/isms_backup_$timestamp.json');
    await file.writeAsString(jsonEncode(data));
    return file;
  }

  /// Export data to CSV
  Future<File> exportToCsv(String tableName, List<Map<String, dynamic>> data) async {
    if (data.isEmpty) {
      throw Exception('No data to export');
    }

    final directory = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    final file = File('${directory.path}/${tableName}_$timestamp.csv');

    final headers = data.first.keys.toList();
    final rows = [
      headers,
      ...data.map((row) => headers.map((h) => row[h]?.toString() ?? '').toList()),
    ];

    final csv = const ListToCsvConverter().convert(rows);
    await file.writeAsString(csv);

    return file;
  }

  /// Export data to Excel
  Future<File> exportToExcel(Map<String, List<Map<String, dynamic>>> data) async {
    final excel = Excel.createExcel();
    excel.delete('Sheet1');

    for (final entry in data.entries) {
      final sheet = excel[entry.key];
      if (entry.value.isEmpty) continue;

      final headers = entry.value.first.keys.toList();
      sheet.appendRow(headers);

      for (final row in entry.value) {
        sheet.appendRow(
          headers.map((h) => row[h]?.toString() ?? '').toList(),
        );
      }
    }

    final directory = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    final file = File('${directory.path}/isms_backup_$timestamp.xlsx');
    await file.writeAsBytes(excel.encode()!);

    return file;
  }

  /// Restore data from JSON backup
  Future<void> restoreFromBackup(Map<String, dynamic> data) async {
    final schoolId = _requireSchoolId();

    // Validate backup
    if (data['school_id'] != schoolId) {
      throw Exception('Backup school ID does not match current school');
    }

    // Restore tables in order (respecting foreign keys)
    final restoreOrder = [
      'classes',
      'sections',
      'users',
      'students',
      'attendance',
      'fee_invoices',
      'fee_payments',
      'examinations',
      'grades',
      'assignments',
      'notifications',
    ];

    for (final tableName in restoreOrder) {
      if (data.containsKey(tableName)) {
        await _restoreTable(tableName, data[tableName] as List, schoolId);
      }
    }
  }

  Future<void> _restoreTable(
    String tableName,
    List<dynamic> rows,
    String schoolId,
  ) async {
    if (rows.isEmpty) return;

    // Clear existing data (optional - could be made configurable)
    // await _client.from(tableName).delete().eq('school_id', schoolId);

    // Insert data in batches
    const batchSize = 100;
    for (var i = 0; i < rows.length; i += batchSize) {
      final batch = rows.skip(i).take(batchSize).toList();
      await _client.from(tableName).insert(
        batch.map((row) => {
          ...row as Map<String, dynamic>,
          'school_id': schoolId,
        }).toList(),
      );
    }
  }

  /// Get backup file size
  Future<int> getBackupSize(Map<String, dynamic> data) async {
    final jsonString = jsonEncode(data);
    return jsonString.length;
  }
}

