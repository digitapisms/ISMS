import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../application/fee_providers.dart';
import '../../domain/fee_invoice_item.dart';
import '../../domain/fee_structure.dart';
import '../../domain/invoice_status.dart';
import '../../../student_management/application/student_providers.dart';
import '../../../school_registration/application/school_providers.dart';

class FeeInvoiceFormDialog extends ConsumerStatefulWidget {
  const FeeInvoiceFormDialog({super.key, this.studentId, this.feeStructure});

  final String? studentId;
  final FeeStructure? feeStructure;

  @override
  ConsumerState<FeeInvoiceFormDialog> createState() =>
      _FeeInvoiceFormDialogState();
}

class _FeeInvoiceFormDialogState extends ConsumerState<FeeInvoiceFormDialog> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedStudentId;
  DateTime _dueDate = DateTime.now().add(const Duration(days: 30));
  InvoiceType _invoiceType = InvoiceType.fee;
  final List<FeeInvoiceItem> _items = [];
  double _discountAmount = 0;
  double _lateFeeAmount = 0;
  final _notesController = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _selectedStudentId = widget.studentId;
    if (widget.feeStructure != null) {
      _items.add(
        FeeInvoiceItem(
          id: '',
          invoiceId: '',
          feeStructureId: widget.feeStructure!.id,
          categoryId: widget.feeStructure!.categoryId,
          description: widget.feeStructure!.name,
          unitAmount: widget.feeStructure!.amount,
          totalAmount: widget.feeStructure!.amount,
        ),
      );
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedStudentId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a student')));
      return;
    }
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one invoice item')),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final school = ref.read(currentSchoolProvider);
      if (school == null) throw Exception('School not found');

      final repo = ref.read(feeRepositoryProvider);
      await repo.createFeeInvoice(
        schoolId: school.id,
        studentId: _selectedStudentId!,
        dueDate: _dueDate,
        items: _items,
        invoiceType: _invoiceType,
        discountAmount: _discountAmount,
        lateFeeAmount: _lateFeeAmount,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );

      if (mounted) {
        ref.invalidate(feeInvoicesProvider);
        ref.invalidate(studentFeeInvoicesProvider(_selectedStudentId!));
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invoice created successfully')),
        );
      }
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
          _isSaving = false;
        });
      }
    }
  }

  void _addItemFromStructure(FeeStructure structure) {
    setState(() {
      _items.add(
        FeeInvoiceItem(
          id: '',
          invoiceId: '',
          feeStructureId: structure.id,
          categoryId: structure.categoryId,
          description: structure.name,
          unitAmount: structure.amount,
          totalAmount: structure.amount,
        ),
      );
    });
  }

  void _removeItem(int index) {
    setState(() {
      _items.removeAt(index);
    });
  }

  double get _totalAmount {
    return _items.fold<double>(
          0,
          (sum, item) => sum + item.totalAmount - item.discountAmount,
        ) -
        _discountAmount +
        _lateFeeAmount;
  }

  @override
  Widget build(BuildContext context) {
    final studentsAsync = ref.watch(studentsProvider);
    final structuresAsync = ref.watch(feeStructuresProvider);

    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 700, maxHeight: 900),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppBar(
                title: const Text('Create Fee Invoice / Challan'),
                automaticallyImplyLeading: false,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Student Selection
                      studentsAsync.when(
                        data: (students) => DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                            labelText: 'Student *',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.person),
                          ),
                          initialValue: _selectedStudentId,
                          items: students.map((student) {
                            return DropdownMenuItem(
                              value: student.id,
                              child: Text(
                                '${student.fullName} (${student.admissionNo})',
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedStudentId = value;
                            });
                          },
                          validator: (value) {
                            if (value == null) {
                              return 'Please select a student';
                            }
                            return null;
                          },
                        ),
                        loading: () => const LinearProgressIndicator(),
                        error: (_, __) => const Text('Error loading students'),
                      ),
                      const SizedBox(height: 16),
                      // Invoice Type
                      DropdownButtonFormField<InvoiceType>(
                        decoration: const InputDecoration(
                          labelText: 'Invoice Type *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.category),
                        ),
                        initialValue: _invoiceType,
                        items: InvoiceType.values.map((type) {
                          return DropdownMenuItem(
                            value: type,
                            child: Text(type.displayName),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _invoiceType = value;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      // Due Date
                      InkWell(
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: _dueDate,
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(
                              const Duration(days: 365),
                            ),
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
                          child: Text(
                            DateFormat('yyyy-MM-dd').format(_dueDate),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Add Items Section
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Invoice Items',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          structuresAsync.when(
                            data: (structures) => PopupMenuButton<FeeStructure>(
                              icon: const Icon(Icons.add),
                              tooltip: 'Add Fee Structure',
                              itemBuilder: (context) {
                                return structures.where((s) => s.isActive).map((
                                  structure,
                                ) {
                                  return PopupMenuItem(
                                    value: structure,
                                    child: ListTile(
                                      title: Text(structure.name),
                                      subtitle: Text(
                                        'PKR ${structure.amount.toStringAsFixed(2)}',
                                      ),
                                    ),
                                  );
                                }).toList();
                              },
                              onSelected: _addItemFromStructure,
                            ),
                            loading: () => const SizedBox.shrink(),
                            error: (_, __) => const SizedBox.shrink(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Items List
                      if (_items.isEmpty)
                        const Card(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: Center(child: Text('No items added yet')),
                          ),
                        )
                      else
                        ..._items.asMap().entries.map((entry) {
                          final index = entry.key;
                          final item = entry.value;
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              title: Text(item.description),
                              subtitle: Text(
                                'PKR ${item.totalAmount.toStringAsFixed(2)}',
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () => _removeItem(index),
                              ),
                            ),
                          );
                        }),
                      const SizedBox(height: 16),
                      // Discount and Late Fee
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              initialValue: _discountAmount.toString(),
                              decoration: const InputDecoration(
                                labelText: 'Discount Amount (PKR)',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.discount),
                              ),
                              keyboardType: TextInputType.number,
                              onChanged: (value) {
                                _discountAmount = double.tryParse(value) ?? 0;
                                setState(() {});
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              initialValue: _lateFeeAmount.toString(),
                              decoration: const InputDecoration(
                                labelText: 'Late Fee Amount (PKR)',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.warning),
                              ),
                              keyboardType: TextInputType.number,
                              onChanged: (value) {
                                _lateFeeAmount = double.tryParse(value) ?? 0;
                                setState(() {});
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Total Amount Display
                      Card(
                        color: Theme.of(context).primaryColor.withOpacity(0.1),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Total Amount:',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              Text(
                                'PKR ${_totalAmount.toStringAsFixed(2)}',
                                style: Theme.of(context).textTheme.headlineSmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context).primaryColor,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Notes
                      TextFormField(
                        controller: _notesController,
                        decoration: const InputDecoration(
                          labelText: 'Notes',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.note),
                        ),
                        maxLines: 3,
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _isSaving
                          ? null
                          : () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: _isSaving ? null : _save,
                      child: _isSaving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Create Invoice'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
