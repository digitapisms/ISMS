import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../application/fee_providers.dart';
import '../../domain/fee_frequency.dart';
import '../../domain/fee_structure.dart';
import '../../../class_management/application/class_providers.dart';
import '../../../school_registration/application/school_providers.dart';

class FeeStructureFormDialog extends ConsumerStatefulWidget {
  const FeeStructureFormDialog({super.key, this.feeStructure});

  final FeeStructure? feeStructure;

  @override
  ConsumerState<FeeStructureFormDialog> createState() =>
      _FeeStructureFormDialogState();
}

class _FeeStructureFormDialogState
    extends ConsumerState<FeeStructureFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();

  String? _selectedCategoryId;
  FeeFrequency _frequency = FeeFrequency.monthly;
  FeeApplicability _applicableTo = FeeApplicability.all;
  int? _selectedClassId;
  int? _selectedSectionId;
  DateTime? _startDate;
  DateTime? _endDate;
  double _lateFeePercentage = 0;
  double _lateFeeFixed = 0;
  double _discountPercentage = 0;
  double _discountFixed = 0;
  bool _isActive = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.feeStructure != null) {
      final fs = widget.feeStructure!;
      _nameController.text = fs.name;
      _descriptionController.text = fs.description ?? '';
      _amountController.text = fs.amount.toString();
      _selectedCategoryId = fs.categoryId;
      _frequency = fs.frequency;
      _applicableTo = fs.applicableTo;
      _selectedClassId = fs.classId;
      _selectedSectionId = fs.sectionId;
      _startDate = fs.startDate;
      _endDate = fs.endDate;
      _lateFeePercentage = fs.lateFeePercentage;
      _lateFeeFixed = fs.lateFeeFixedAmount;
      _discountPercentage = fs.discountPercentage;
      _discountFixed = fs.discountFixedAmount;
      _isActive = fs.isActive;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a fee category')),
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
      final amount = double.tryParse(_amountController.text.trim());
      if (amount == null || amount <= 0) {
        throw Exception('Invalid amount');
      }

      if (widget.feeStructure == null) {
        await repo.createFeeStructure(
          schoolId: school.id,
          categoryId: _selectedCategoryId!,
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          amount: amount,
          frequency: _frequency,
          applicableTo: _applicableTo,
          classId: _selectedClassId,
          sectionId: _selectedSectionId,
          startDate: _startDate,
          endDate: _endDate,
          lateFeePercentage: _lateFeePercentage,
          lateFeeFixedAmount: _lateFeeFixed,
          discountPercentage: _discountPercentage,
          discountFixedAmount: _discountFixed,
        );
      } else {
        await repo.updateFeeStructure(
          id: widget.feeStructure!.id,
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          amount: amount,
          frequency: _frequency,
          applicableTo: _applicableTo,
          isActive: _isActive,
          lateFeePercentage: _lateFeePercentage,
          lateFeeFixedAmount: _lateFeeFixed,
          discountPercentage: _discountPercentage,
          discountFixedAmount: _discountFixed,
        );
      }

      if (mounted) {
        ref.invalidate(feeStructuresProvider);
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.feeStructure == null
                  ? 'Fee structure created successfully'
                  : 'Fee structure updated successfully',
            ),
          ),
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

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(feeCategoriesProvider);
    final classesAsync = ref.watch(classesProvider);

    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 800),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppBar(
                title: Text(
                  widget.feeStructure == null
                      ? 'Create Fee Structure'
                      : 'Edit Fee Structure',
                ),
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
                      // Category Selection
                      categoriesAsync.when(
                        data: (categories) => DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                            labelText: 'Fee Category *',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.category),
                          ),
                          initialValue: _selectedCategoryId,
                          items: categories.map((cat) {
                            return DropdownMenuItem(
                              value: cat.id,
                              child: Text(cat.name),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedCategoryId = value;
                            });
                          },
                          validator: (value) {
                            if (value == null) {
                              return 'Please select a category';
                            }
                            return null;
                          },
                        ),
                        loading: () => const LinearProgressIndicator(),
                        error: (_, __) =>
                            const Text('Error loading categories'),
                      ),
                      const SizedBox(height: 16),
                      // Name
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Structure Name *',
                          hintText: 'e.g., Class 1 Tuition Fee',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.label),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Name is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      // Description
                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.description),
                        ),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 16),
                      // Amount
                      TextFormField(
                        controller: _amountController,
                        decoration: const InputDecoration(
                          labelText: 'Amount (PKR) *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.currency_rupee),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Amount is required';
                          }
                          final amount = double.tryParse(value.trim());
                          if (amount == null || amount <= 0) {
                            return 'Please enter a valid amount';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      // Frequency
                      DropdownButtonFormField<FeeFrequency>(
                        decoration: const InputDecoration(
                          labelText: 'Frequency *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.calendar_today),
                        ),
                        initialValue: _frequency,
                        items: FeeFrequency.values.map((freq) {
                          return DropdownMenuItem(
                            value: freq,
                            child: Text(freq.displayName),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _frequency = value;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      // Applicable To
                      DropdownButtonFormField<FeeApplicability>(
                        decoration: const InputDecoration(
                          labelText: 'Applicable To *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.people),
                        ),
                        initialValue: _applicableTo,
                        items: FeeApplicability.values.map((app) {
                          return DropdownMenuItem(
                            value: app,
                            child: Text(app.displayName),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _applicableTo = value;
                            });
                          }
                        },
                      ),
                      // Class Selection (if applicable)
                      if (_applicableTo == FeeApplicability.specificClass ||
                          _applicableTo == FeeApplicability.section)
                        Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: classesAsync.when(
                            data: (classes) => DropdownButtonFormField<int>(
                              decoration: const InputDecoration(
                                labelText: 'Class',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.class_),
                              ),
                              initialValue: _selectedClassId,
                              items: classes.map((cls) {
                                return DropdownMenuItem(
                                  value: cls.id,
                                  child: Text(cls.name),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedClassId = value;
                                  _selectedSectionId = null;
                                });
                              },
                            ),
                            loading: () => const LinearProgressIndicator(),
                            error: (_, __) =>
                                const Text('Error loading classes'),
                          ),
                        ),
                      const SizedBox(height: 16),
                      // Date Range
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () async {
                                final date = await showDatePicker(
                                  context: context,
                                  initialDate: _startDate ?? DateTime.now(),
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime(2100),
                                );
                                if (date != null) {
                                  setState(() {
                                    _startDate = date;
                                  });
                                }
                              },
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  labelText: 'Start Date',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.calendar_today),
                                ),
                                child: Text(
                                  _startDate != null
                                      ? DateFormat(
                                          'yyyy-MM-dd',
                                        ).format(_startDate!)
                                      : 'Select start date',
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: InkWell(
                              onTap: () async {
                                final date = await showDatePicker(
                                  context: context,
                                  initialDate: _endDate ?? DateTime.now(),
                                  firstDate: _startDate ?? DateTime(2020),
                                  lastDate: DateTime(2100),
                                );
                                if (date != null) {
                                  setState(() {
                                    _endDate = date;
                                  });
                                }
                              },
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  labelText: 'End Date',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.event),
                                ),
                                child: Text(
                                  _endDate != null
                                      ? DateFormat(
                                          'yyyy-MM-dd',
                                        ).format(_endDate!)
                                      : 'Select end date',
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Late Fee Settings
                      ExpansionTile(
                        title: const Text('Late Fee Settings'),
                        children: [
                          TextFormField(
                            initialValue: _lateFeePercentage.toString(),
                            decoration: const InputDecoration(
                              labelText: 'Late Fee Percentage',
                              border: OutlineInputBorder(),
                              suffixText: '%',
                            ),
                            keyboardType: TextInputType.number,
                            onChanged: (value) {
                              _lateFeePercentage = double.tryParse(value) ?? 0;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            initialValue: _lateFeeFixed.toString(),
                            decoration: const InputDecoration(
                              labelText: 'Fixed Late Fee Amount (PKR)',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                            onChanged: (value) {
                              _lateFeeFixed = double.tryParse(value) ?? 0;
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Discount Settings
                      ExpansionTile(
                        title: const Text('Discount Settings'),
                        children: [
                          TextFormField(
                            initialValue: _discountPercentage.toString(),
                            decoration: const InputDecoration(
                              labelText: 'Discount Percentage',
                              border: OutlineInputBorder(),
                              suffixText: '%',
                            ),
                            keyboardType: TextInputType.number,
                            onChanged: (value) {
                              _discountPercentage = double.tryParse(value) ?? 0;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            initialValue: _discountFixed.toString(),
                            decoration: const InputDecoration(
                              labelText: 'Fixed Discount Amount (PKR)',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                            onChanged: (value) {
                              _discountFixed = double.tryParse(value) ?? 0;
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Active Status
                      SwitchListTile(
                        title: const Text('Active'),
                        subtitle: const Text(
                          'Inactive structures won\'t be used for invoice generation',
                        ),
                        value: _isActive,
                        onChanged: (value) {
                          setState(() {
                            _isActive = value;
                          });
                        },
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
                          : Text(
                              widget.feeStructure == null ? 'Create' : 'Update',
                            ),
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
