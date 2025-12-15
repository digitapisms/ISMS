import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../application/fee_providers.dart';
import '../../domain/fee_invoice_item.dart';
import '../../domain/fee_structure.dart';
import '../../../class_management/application/class_providers.dart';
import '../../../school_registration/application/school_providers.dart';
import '../../../student_management/application/student_providers.dart';
import '../../../student_management/domain/student.dart';

class BulkInvoiceGenerationDialog extends ConsumerStatefulWidget {
  const BulkInvoiceGenerationDialog({super.key});

  @override
  ConsumerState<BulkInvoiceGenerationDialog> createState() =>
      _BulkInvoiceGenerationDialogState();
}

class _BulkInvoiceGenerationDialogState
    extends ConsumerState<BulkInvoiceGenerationDialog> {
  FeeStructure? _selectedStructure;
  int? _selectedClassId;
  int? _selectedSectionId;
  DateTime _dueDate = DateTime.now().add(const Duration(days: 30));
  bool _isGenerating = false;
  int _generatedCount = 0;
  int _errorCount = 0;

  Future<void> _generateBulkInvoices() async {
    if (_selectedStructure == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a fee structure')),
      );
      return;
    }

    setState(() {
      _isGenerating = true;
      _generatedCount = 0;
      _errorCount = 0;
    });

    try {
      final school = ref.read(currentSchoolProvider);
      if (school == null) throw Exception('School not found');

      final repo = ref.read(feeRepositoryProvider);
      final studentsAsync = ref.read(studentsProvider);

      await studentsAsync.when(
        data: (allStudents) async {
          // Filter students by class/section
          List<Student> students = allStudents;
          if (_selectedClassId != null) {
            students = students
                .where((s) => s.classId == _selectedClassId)
                .toList();
            if (_selectedSectionId != null) {
              students = students
                  .where((s) => s.sectionId == _selectedSectionId)
                  .toList();
            }
          }

          // Generate invoice for each student
          for (final student in students) {
            try {
              await repo.createFeeInvoice(
                schoolId: school.id,
                studentId: student.id,
                dueDate: _dueDate,
                items: [
                  FeeInvoiceItem(
                    id: '',
                    invoiceId: '',
                    feeStructureId: _selectedStructure!.id,
                    categoryId: _selectedStructure!.categoryId,
                    description: _selectedStructure!.name,
                    unitAmount: _selectedStructure!.amount,
                    totalAmount: _selectedStructure!.amount,
                  ),
                ],
              );
              setState(() {
                _generatedCount++;
              });
            } catch (e) {
              setState(() {
                _errorCount++;
              });
            }
          }

          if (mounted) {
            ref.invalidate(feeInvoicesProvider);
            Navigator.of(context).pop(true);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Generated $_generatedCount invoices${_errorCount > 0 ? ' ($_errorCount errors)' : ''}',
                ),
              ),
            );
          }
        },
        loading: () async {},
        error: (_, __) async {
          throw Exception('Error loading students');
        },
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGenerating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final structuresAsync = ref.watch(feeStructuresProvider);
    final classesAsync = ref.watch(classesProvider);

    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Bulk Invoice Generation',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Fee Structure Selection
              structuresAsync.when(
                data: (structures) => DropdownButtonFormField<FeeStructure>(
                  decoration: const InputDecoration(
                    labelText: 'Fee Structure *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.account_balance_wallet),
                  ),
                  initialValue: _selectedStructure,
                  items: structures.where((s) => s.isActive).map((structure) {
                    return DropdownMenuItem(
                      value: structure,
                      child: Text(
                        '${structure.name} - PKR ${structure.amount.toStringAsFixed(2)}',
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedStructure = value;
                    });
                  },
                ),
                loading: () => const LinearProgressIndicator(),
                error: (_, __) => const Text('Error loading structures'),
              ),
              const SizedBox(height: 16),
              // Class Selection
              classesAsync.when(
                data: (classes) => DropdownButtonFormField<int>(
                  decoration: const InputDecoration(
                    labelText: 'Class (Optional - leave empty for all)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.class_),
                  ),
                  initialValue: _selectedClassId,
                  items: [
                    const DropdownMenuItem<int>(
                      value: null,
                      child: Text('All Classes'),
                    ),
                    ...classes.map((cls) {
                      return DropdownMenuItem(
                        value: cls.id,
                        child: Text(cls.name),
                      );
                    }),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedClassId = value;
                      _selectedSectionId = null;
                    });
                  },
                ),
                loading: () => const LinearProgressIndicator(),
                error: (_, __) => const Text('Error loading classes'),
              ),
              const SizedBox(height: 16),
              // Due Date
              InkWell(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _dueDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (date != null) {
                    setState(() {
                      _dueDate = date;
                    });
                  }
                },
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Due Date *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(DateFormat('yyyy-MM-dd').format(_dueDate)),
                ),
              ),
              if (_isGenerating) ...[
                const SizedBox(height: 24),
                const LinearProgressIndicator(),
                const SizedBox(height: 16),
                Text('Generated: $_generatedCount'),
                if (_errorCount > 0) Text('Errors: $_errorCount'),
              ],
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isGenerating
                        ? null
                        : () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _isGenerating ? null : _generateBulkInvoices,
                    child: _isGenerating
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Generate Invoices'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
