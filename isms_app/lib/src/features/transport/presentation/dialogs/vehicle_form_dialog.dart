import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/transport_providers.dart';
import '../../domain/vehicle.dart';
import '../../domain/transport_type.dart';
import '../../../school_registration/application/school_providers.dart';

class VehicleFormDialog extends ConsumerStatefulWidget {
  const VehicleFormDialog({this.vehicle, super.key});

  final Vehicle? vehicle;

  @override
  ConsumerState<VehicleFormDialog> createState() => _VehicleFormDialogState();
}

class _VehicleFormDialogState extends ConsumerState<VehicleFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _vehicleNumberController = TextEditingController();
  final _registrationController = TextEditingController();
  final _chassisController = TextEditingController();
  final _engineController = TextEditingController();
  final _fitnessNumberController = TextEditingController();
  final _insuranceNumberController = TextEditingController();
  final _makeController = TextEditingController();
  final _modelController = TextEditingController();
  final _colorController = TextEditingController();
  final _capacityController = TextEditingController();
  final _purchasePriceController = TextEditingController();
  final _currentValueController = TextEditingController();
  final _notesController = TextEditingController();

  VehicleType _selectedType = VehicleType.bus;
  VehicleStatus _selectedStatus = VehicleStatus.active;
  int? _year;
  DateTime? _fitnessExpiry;
  DateTime? _insuranceExpiry;
  DateTime? _purchaseDate;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.vehicle != null) {
      final v = widget.vehicle!;
      _vehicleNumberController.text = v.vehicleNumber;
      _registrationController.text = v.registrationNumber ?? '';
      _chassisController.text = v.chassisNumber ?? '';
      _engineController.text = v.engineNumber ?? '';
      _fitnessNumberController.text = v.fitnessCertificateNumber ?? '';
      _insuranceNumberController.text = v.insuranceNumber ?? '';
      _makeController.text = v.make ?? '';
      _modelController.text = v.model ?? '';
      _colorController.text = v.color ?? '';
      _capacityController.text = v.capacity.toString();
      _purchasePriceController.text = v.purchasePrice?.toString() ?? '';
      _currentValueController.text = v.currentValue?.toString() ?? '';
      _notesController.text = v.notes ?? '';
      _selectedType = v.vehicleType;
      _selectedStatus = v.status;
      _year = v.year;
      _fitnessExpiry = v.fitnessCertificateExpiry;
      _insuranceExpiry = v.insuranceExpiry;
      _purchaseDate = v.purchaseDate;
    }
  }

  @override
  void dispose() {
    _vehicleNumberController.dispose();
    _registrationController.dispose();
    _chassisController.dispose();
    _engineController.dispose();
    _fitnessNumberController.dispose();
    _insuranceNumberController.dispose();
    _makeController.dispose();
    _modelController.dispose();
    _colorController.dispose();
    _capacityController.dispose();
    _purchasePriceController.dispose();
    _currentValueController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final repo = ref.read(transportRepositoryProvider);
      final school = ref.read(currentSchoolProvider);
      if (school == null) {
        throw Exception('School context required');
      }

      final vehicle = Vehicle(
        id: widget.vehicle?.id ?? 0,
        schoolId: school.id,
        vehicleNumber: _vehicleNumberController.text.trim(),
        vehicleType: _selectedType,
        make: _makeController.text.trim().isEmpty
            ? null
            : _makeController.text.trim(),
        model: _modelController.text.trim().isEmpty
            ? null
            : _modelController.text.trim(),
        year: _year,
        color: _colorController.text.trim().isEmpty
            ? null
            : _colorController.text.trim(),
        capacity: int.parse(_capacityController.text.trim()),
        registrationNumber: _registrationController.text.trim().isEmpty
            ? null
            : _registrationController.text.trim(),
        chassisNumber: _chassisController.text.trim().isEmpty
            ? null
            : _chassisController.text.trim(),
        engineNumber: _engineController.text.trim().isEmpty
            ? null
            : _engineController.text.trim(),
        fitnessCertificateNumber:
            _fitnessNumberController.text.trim().isEmpty
                ? null
                : _fitnessNumberController.text.trim(),
        fitnessCertificateExpiry: _fitnessExpiry,
        insuranceNumber: _insuranceNumberController.text.trim().isEmpty
            ? null
            : _insuranceNumberController.text.trim(),
        insuranceExpiry: _insuranceExpiry,
        status: _selectedStatus,
        purchaseDate: _purchaseDate,
        purchasePrice: _purchasePriceController.text.trim().isEmpty
            ? null
            : double.tryParse(_purchasePriceController.text.trim()),
        currentValue: _currentValueController.text.trim().isEmpty
            ? null
            : double.tryParse(_currentValueController.text.trim()),
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );

      if (widget.vehicle == null) {
        await repo.createVehicle(vehicle);
      } else {
        await repo.updateVehicle(vehicle);
      }

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.vehicle == null
                  ? 'Vehicle added successfully'
                  : 'Vehicle updated successfully',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 700,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppBar(
                title: Text(widget.vehicle == null ? 'Add Vehicle' : 'Edit Vehicle'),
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
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _vehicleNumberController,
                              decoration: const InputDecoration(
                                labelText: 'Vehicle Number *',
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Vehicle number is required';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: DropdownButtonFormField<VehicleType>(
                              initialValue: _selectedType,
                              decoration: const InputDecoration(
                                labelText: 'Vehicle Type',
                                border: OutlineInputBorder(),
                              ),
                              items: VehicleType.values.map((type) {
                                return DropdownMenuItem<VehicleType>(
                                  value: type,
                                  child: Text(type.displayName),
                                );
                              }).toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() => _selectedType = value);
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _registrationController,
                              decoration: const InputDecoration(
                                labelText: 'Registration Number',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _capacityController,
                              decoration: const InputDecoration(
                                labelText: 'Capacity *',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Capacity is required';
                                }
                                if (int.tryParse(value.trim()) == null) {
                                  return 'Invalid number';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _makeController,
                              decoration: const InputDecoration(
                                labelText: 'Make',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _modelController,
                              decoration: const InputDecoration(
                                labelText: 'Model',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: TextEditingController(
                                text: _year?.toString() ?? '',
                              ),
                              decoration: const InputDecoration(
                                labelText: 'Year',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                              onChanged: (value) {
                                _year = int.tryParse(value);
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _fitnessNumberController,
                              decoration: const InputDecoration(
                                labelText: 'Fitness Certificate Number',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: InkWell(
                              onTap: () async {
                                final date = await showDatePicker(
                                  context: context,
                                  initialDate: _fitnessExpiry ?? DateTime.now(),
                                  firstDate: DateTime(2000),
                                  lastDate: DateTime(2100),
                                );
                                if (date != null) {
                                  setState(() => _fitnessExpiry = date);
                                }
                              },
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  labelText: 'Fitness Expiry',
                                  border: OutlineInputBorder(),
                                  suffixIcon: Icon(Icons.calendar_today),
                                ),
                                child: Text(
                                  _fitnessExpiry != null
                                      ? '${_fitnessExpiry!.day}/${_fitnessExpiry!.month}/${_fitnessExpiry!.year}'
                                      : 'Select date',
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _insuranceNumberController,
                              decoration: const InputDecoration(
                                labelText: 'Insurance Number',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: InkWell(
                              onTap: () async {
                                final date = await showDatePicker(
                                  context: context,
                                  initialDate: _insuranceExpiry ?? DateTime.now(),
                                  firstDate: DateTime(2000),
                                  lastDate: DateTime(2100),
                                );
                                if (date != null) {
                                  setState(() => _insuranceExpiry = date);
                                }
                              },
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  labelText: 'Insurance Expiry',
                                  border: OutlineInputBorder(),
                                  suffixIcon: Icon(Icons.calendar_today),
                                ),
                                child: Text(
                                  _insuranceExpiry != null
                                      ? '${_insuranceExpiry!.day}/${_insuranceExpiry!.month}/${_insuranceExpiry!.year}'
                                      : 'Select date',
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<VehicleStatus>(
                        initialValue: _selectedStatus,
                        decoration: const InputDecoration(
                          labelText: 'Status',
                          border: OutlineInputBorder(),
                        ),
                        items: VehicleStatus.values.map((status) {
                          return DropdownMenuItem<VehicleStatus>(
                            value: status,
                            child: Text(status.displayName),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _selectedStatus = value);
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _notesController,
                        decoration: const InputDecoration(
                          labelText: 'Notes',
                          border: OutlineInputBorder(),
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
                      onPressed: _isLoading
                          ? null
                          : () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _save,
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Save'),
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

