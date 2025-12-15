import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';

import '../application/backup_providers.dart';
import '../services/scheduled_backup_service.dart';

class BackupRestoreScreen extends ConsumerStatefulWidget {
  const BackupRestoreScreen({super.key});

  @override
  ConsumerState<BackupRestoreScreen> createState() =>
      _BackupRestoreScreenState();
}

class _BackupRestoreScreenState extends ConsumerState<BackupRestoreScreen> {
  bool _isExporting = false;
  bool _isImporting = false;
  BackupSchedule? _currentSchedule;

  Future<void> _exportBackup() async {
    setState(() => _isExporting = true);
    try {
      final repo = ref.read(backupRepositoryProvider);
      final data = await repo.exportAllData();
      final file = await repo.saveBackupToFile(data);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Backup saved to: ${file.path}'),
            action: SnackBarAction(
              label: 'OK',
              onPressed: () {},
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    } finally {
      setState(() => _isExporting = false);
    }
  }

  Future<void> _exportToCsv() async {
    setState(() => _isExporting = true);
    try {
      final repo = ref.read(backupRepositoryProvider);
      final data = await repo.exportAllData();

      // Export each table as CSV
      for (final entry in data.entries) {
        if (entry.value is List && (entry.value as List).isNotEmpty) {
          final list = entry.value as List;
          final mappedList = list
              .map((item) => item is Map<String, dynamic>
                  ? item
                  : Map<String, dynamic>.from(item as Map))
              .toList()
              .cast<Map<String, dynamic>>();
          await repo.exportToCsv(entry.key, mappedList);
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('CSV files exported successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    } finally {
      setState(() => _isExporting = false);
    }
  }

  Future<void> _exportToExcel() async {
    setState(() => _isExporting = true);
    try {
      final repo = ref.read(backupRepositoryProvider);
      final data = await repo.exportAllData();

      final excelData = <String, List<Map<String, dynamic>>>{};
      for (final entry in data.entries) {
        if (entry.value is List) {
          excelData[entry.key] = (entry.value as List)
              .cast<Map<String, dynamic>>();
        }
      }

      final file = await repo.exportToExcel(excelData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Excel file saved to: ${file.path}'),
            action: SnackBarAction(
              label: 'OK',
              onPressed: () {},
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    } finally {
      setState(() => _isExporting = false);
    }
  }

  Future<void> _importBackup() async {
    setState(() => _isImporting = true);
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null || result.files.single.path == null) {
        setState(() => _isImporting = false);
        return;
      }

      final file = File(result.files.single.path!);
      final content = await file.readAsString();
      final data = jsonDecode(content) as Map<String, dynamic>;

      final repo = ref.read(backupRepositoryProvider);
      await repo.restoreFromBackup(data);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Backup restored successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Import failed: $e')),
        );
      }
    } finally {
      setState(() => _isImporting = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _loadSchedule();
  }

  Future<void> _loadSchedule() async {
    final schedule = await ScheduledBackupService.getSchedule();
    setState(() {
      _currentSchedule = schedule;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Backup & Restore'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _buildScheduledBackupSection(context),
          const SizedBox(height: 32),
          _buildSection(
            context,
            title: 'Export Data',
            icon: Icons.download,
            children: [
              _buildActionCard(
                context,
                title: 'Export to JSON',
                subtitle: 'Export all data as JSON backup file',
                icon: Icons.code,
                onTap: _exportBackup,
                isLoading: _isExporting,
              ),
              const SizedBox(height: 12),
              _buildActionCard(
                context,
                title: 'Export to CSV',
                subtitle: 'Export data as CSV files',
                icon: Icons.table_chart,
                onTap: _exportToCsv,
                isLoading: _isExporting,
              ),
              const SizedBox(height: 12),
              _buildActionCard(
                context,
                title: 'Export to Excel',
                subtitle: 'Export all data to Excel workbook',
                icon: Icons.table_chart,
                onTap: _exportToExcel,
                isLoading: _isExporting,
              ),
            ],
          ),
          const SizedBox(height: 32),
          _buildSection(
            context,
            title: 'Import Data',
            icon: Icons.upload,
            children: [
              _buildActionCard(
                context,
                title: 'Import from JSON',
                subtitle: 'Restore data from JSON backup file',
                icon: Icons.restore,
                onTap: _importBackup,
                isLoading: _isImporting,
                color: Colors.orange,
              ),
            ],
          ),
          const SizedBox(height: 32),
          _buildInfoCard(context),
        ],
      ),
    );
  }

  Widget _buildScheduledBackupSection(BuildContext context) {
    return _buildSection(
      context,
      title: 'Scheduled Backups',
      icon: Icons.schedule,
      children: [
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Automatic Backups',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    Switch(
                      value: _currentSchedule?.enabled ?? false,
                      onChanged: (enabled) async {
                        if (enabled) {
                          await _showScheduleDialog(context);
                        } else {
                          await ScheduledBackupService.disableScheduledBackup();
                          await _loadSchedule();
                        }
                      },
                    ),
                  ],
                ),
                if (_currentSchedule?.enabled == true) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Current Schedule',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Frequency: ${_currentSchedule!.frequency.name}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        Text(
                          'Time: ${_currentSchedule!.time}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  const SizedBox(height: 8),
                  Text(
                    'Enable automatic backups to keep your data safe',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _showScheduleDialog(BuildContext context) async {
    BackupFrequency? selectedFrequency;
    String selectedTime = '02:00';

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Schedule Backup'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<BackupFrequency>(
                value: selectedFrequency,
                decoration: const InputDecoration(
                  labelText: 'Frequency',
                  border: OutlineInputBorder(),
                ),
                items: BackupFrequency.values.map((freq) {
                  return DropdownMenuItem(
                    value: freq,
                    child: Text(freq.name.toUpperCase()),
                  );
                }).toList(),
                onChanged: (value) {
                  setDialogState(() {
                    selectedFrequency = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: selectedTime,
                decoration: const InputDecoration(
                  labelText: 'Time (HH:mm)',
                  border: OutlineInputBorder(),
                  hintText: '02:00',
                ),
                onChanged: (value) {
                  selectedTime = value;
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: selectedFrequency == null
                  ? null
                  : () async {
                      await ScheduledBackupService.enableScheduledBackup(
                        frequency: selectedFrequency!,
                        time: selectedTime,
                      );
                      Navigator.pop(context);
                      await _loadSchedule();
                    },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 28),
            const SizedBox(width: 12),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...children,
      ],
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
    required bool isLoading,
    Color? color,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
      child: InkWell(
        onTap: isLoading ? null : onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: (color ?? Theme.of(context).colorScheme.primary)
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: color ?? Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              if (isLoading)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                Icon(
                  Icons.chevron_right,
                  color: Theme.of(context).colorScheme.outline,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceVariant,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              Icons.info_outline,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Backup files are saved to your device. Make sure to keep them in a safe place.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

