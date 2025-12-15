import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/student_providers.dart';

class BulkImportScreen extends ConsumerStatefulWidget {
  const BulkImportScreen({super.key});

  @override
  ConsumerState<BulkImportScreen> createState() => _BulkImportScreenState();
}

class _BulkImportScreenState extends ConsumerState<BulkImportScreen> {
  List<Map<String, dynamic>> _parsedStudents = [];
  bool _isLoading = false;
  bool _isImporting = false;
  String? _error;
  Map<String, dynamic>? _importResult;

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (result != null) {
        setState(() {
          _isLoading = true;
          _error = null;
          _parsedStudents = [];
        });

        // Read file
        final file = result.files.single;
        String content;
        if (file.bytes != null) {
          // Web
          content = utf8.decode(file.bytes!);
        } else if (file.path != null) {
          // Mobile
          content = await _readFile(file.path!);
        } else {
          throw Exception('Could not read file');
        }

        // Parse CSV
        final students = _parseCSV(content);
        setState(() {
          _parsedStudents = students;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error reading file: $e';
        _isLoading = false;
      });
    }
  }

  Future<String> _readFile(String path) async {
    // For mobile platforms, use dart:io
    try {
      final file = File(path);
      return await file.readAsString();
    } catch (e) {
      throw Exception('Failed to read file: $e');
    }
  }

  List<Map<String, dynamic>> _parseCSV(String content) {
    final lines = content.split('\n');
    if (lines.isEmpty) return [];

    // Parse header with quoted field support
    final headers = _parseCSVLine(lines[0]);
    if (headers.isEmpty) return [];

    final students = <Map<String, dynamic>>[];

    for (int i = 1; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;

      final values = _parseCSVLine(line);
      if (values.length != headers.length) {
        // Skip malformed rows but log warning
        continue;
      }

      final student = <String, dynamic>{};
      for (int j = 0; j < headers.length && j < values.length; j++) {
        final header = headers[j].toLowerCase().trim();
        final value = values[j].trim();
        student[header] = value;
      }

      // Map CSV columns to student data (with multiple name variations)
      students.add({
        'admission_no':
            student['admission_no'] ??
            student['admissionno'] ??
            student['admission_number'] ??
            student['adm_no'] ??
            '',
        'full_name':
            student['full_name'] ??
            student['fullname'] ??
            student['name'] ??
            student['student_name'] ??
            '',
        'class_id': student['class_id'] != null
            ? int.tryParse(student['class_id'].toString())
            : null,
        'section_id': student['section_id'] != null
            ? int.tryParse(student['section_id'].toString())
            : null,
        'status': student['status'] ?? 'active',
        'email': student['email'] ?? student['email_address'] ?? '',
        'gender': student['gender'] ?? student['sex'] ?? null,
        'dob':
            student['dob'] ??
            student['date_of_birth'] ??
            student['birth_date'] ??
            null,
        'blood_group':
            student['blood_group'] ??
            student['bloodgroup'] ??
            student['blood'] ??
            null,
      });
    }

    return students;
  }

  /// Parse a CSV line handling quoted fields and escaped quotes
  List<String> _parseCSVLine(String line) {
    final result = <String>[];
    final buffer = StringBuffer();
    bool inQuotes = false;

    for (int i = 0; i < line.length; i++) {
      final char = line[i];

      if (char == '"') {
        if (inQuotes && i + 1 < line.length && line[i + 1] == '"') {
          // Escaped quote inside quoted field
          buffer.write('"');
          i++; // Skip next quote
        } else {
          // Toggle quote state
          inQuotes = !inQuotes;
        }
      } else if (char == ',' && !inQuotes) {
        // End of field
        result.add(buffer.toString());
        buffer.clear();
      } else {
        buffer.write(char);
      }
    }

    // Add last field
    result.add(buffer.toString());

    return result;
  }

  Future<void> _importStudents() async {
    if (_parsedStudents.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No students to import')));
      return;
    }

    setState(() {
      _isImporting = true;
      _error = null;
      _importResult = null;
    });

    try {
      final repo = ref.read(studentRepositoryProvider);
      final result = await repo.bulkImportStudents(_parsedStudents);

      setState(() {
        _importResult = result;
        _isImporting = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Import complete: ${result['success']} succeeded, ${result['failed']} failed',
            ),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _error = 'Import failed: $e';
        _isImporting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bulk Import Students')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              color: Colors.blue.withOpacity(0.1),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.info_outline, color: Colors.blue),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'CSV Format',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'CSV should have headers: admission_no, full_name, class_id, section_id, status, email',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                icon: const Icon(Icons.upload_file),
                label: const Text('Select CSV File'),
                onPressed: _isLoading ? null : _pickFile,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            if (_isLoading) ...[
              const SizedBox(height: 24),
              const Center(child: CircularProgressIndicator()),
            ],
            if (_error != null) ...[
              const SizedBox(height: 16),
              Card(
                color: Colors.red.withOpacity(0.1),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(Icons.error, color: Colors.red),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _error!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            if (_parsedStudents.isNotEmpty) ...[
              const SizedBox(height: 24),
              Text(
                'Preview (${_parsedStudents.length} students)',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              Card(
                child: Column(
                  children: [
                    ..._parsedStudents
                        .take(10)
                        .map(
                          (s) => ListTile(
                            title: Text(s['full_name'] ?? 'N/A'),
                            subtitle: Text('Adm No: ${s['admission_no']}'),
                            trailing: Text(s['status'] ?? 'active'),
                          ),
                        ),
                    if (_parsedStudents.length > 10)
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          '... and ${_parsedStudents.length - 10} more',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isImporting ? null : _importStudents,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isImporting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text('Import ${_parsedStudents.length} Students'),
                ),
              ),
            ],
            if (_importResult != null) ...[
              const SizedBox(height: 24),
              Card(
                color: Colors.green.withOpacity(0.1),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Import Results',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      Text('Success: ${_importResult!['success']}'),
                      Text('Failed: ${_importResult!['failed']}'),
                      if ((_importResult!['errors'] as List).isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(
                          'Errors:',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        ...(_importResult!['errors'] as List<String>)
                            .take(5)
                            .map(
                              (e) => Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  e,
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(color: Colors.red),
                                ),
                              ),
                            ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
