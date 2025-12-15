import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/timetable_providers.dart';
import '../../domain/room.dart';
import '../../../school_registration/application/school_providers.dart';

class RoomFormDialog extends ConsumerStatefulWidget {
  const RoomFormDialog({super.key, this.room});

  final Room? room;

  @override
  ConsumerState<RoomFormDialog> createState() => _RoomFormDialogState();
}

class _RoomFormDialogState extends ConsumerState<RoomFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _codeController = TextEditingController();
  final _capacityController = TextEditingController();
  final _floorController = TextEditingController();
  final _buildingController = TextEditingController();
  RoomType _roomType = RoomType.classroom;
  final List<String> _facilities = [];
  final TextEditingController _facilityController = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.room != null) {
      final room = widget.room!;
      _nameController.text = room.name;
      _codeController.text = room.code ?? '';
      _capacityController.text = room.capacity?.toString() ?? '';
      _floorController.text = room.floorNumber?.toString() ?? '';
      _buildingController.text = room.buildingName ?? '';
      _roomType = room.roomType;
      _facilities.addAll(room.facilities);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _capacityController.dispose();
    _floorController.dispose();
    _buildingController.dispose();
    _facilityController.dispose();
    super.dispose();
  }

  void _addFacility() {
    if (_facilityController.text.trim().isNotEmpty) {
      setState(() {
        _facilities.add(_facilityController.text.trim());
        _facilityController.clear();
      });
    }
  }

  void _removeFacility(String facility) {
    setState(() {
      _facilities.remove(facility);
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final school = ref.read(currentSchoolProvider);
      if (school == null) throw Exception('School not found');

      final repo = ref.read(timetableRepositoryProvider);
      final capacity = _capacityController.text.trim().isEmpty
          ? null
          : int.tryParse(_capacityController.text.trim());
      final floorNumber = _floorController.text.trim().isEmpty
          ? null
          : int.tryParse(_floorController.text.trim());

      if (widget.room == null) {
        await repo.createRoom(
          schoolId: school.id,
          name: _nameController.text.trim(),
          code: _codeController.text.trim().isEmpty
              ? null
              : _codeController.text.trim(),
          roomType: _roomType,
          capacity: capacity,
          floorNumber: floorNumber,
          buildingName: _buildingController.text.trim().isEmpty
              ? null
              : _buildingController.text.trim(),
          facilities: _facilities.isEmpty ? null : _facilities,
        );
      } else {
        await repo.updateRoom(
          id: widget.room!.id,
          name: _nameController.text.trim(),
          code: _codeController.text.trim().isEmpty
              ? null
              : _codeController.text.trim(),
          roomType: _roomType,
          capacity: capacity,
          floorNumber: floorNumber,
          buildingName: _buildingController.text.trim().isEmpty
              ? null
              : _buildingController.text.trim(),
          facilities: _facilities.isEmpty ? null : _facilities,
        );
      }

      if (mounted) {
        ref.invalidate(roomsProvider);
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.room == null
                  ? 'Room created successfully'
                  : 'Room updated successfully',
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
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 800),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppBar(
                title: Text(widget.room == null ? 'Add Room' : 'Edit Room'),
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
                    children: [
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Room Name *',
                          hintText: 'e.g., Room 101, Physics Lab',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.meeting_room),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Room name is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _codeController,
                        decoration: const InputDecoration(
                          labelText: 'Room Code',
                          hintText: 'e.g., R101',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.tag),
                        ),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<RoomType>(
                        decoration: const InputDecoration(
                          labelText: 'Room Type *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.category),
                        ),
                        value: _roomType,
                        items: RoomType.values.map((type) {
                          return DropdownMenuItem(
                            value: type,
                            child: Text(type.displayName),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _roomType = value;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _capacityController,
                              decoration: const InputDecoration(
                                labelText: 'Capacity',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.people),
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _floorController,
                              decoration: const InputDecoration(
                                labelText: 'Floor Number',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.layers),
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _buildingController,
                        decoration: const InputDecoration(
                          labelText: 'Building Name',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.business),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Facilities',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _facilityController,
                              decoration: const InputDecoration(
                                labelText: 'Add Facility',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.add),
                              ),
                              onFieldSubmitted: (_) => _addFacility(),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.add_circle),
                            onPressed: _addFacility,
                            tooltip: 'Add Facility',
                          ),
                        ],
                      ),
                      if (_facilities.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _facilities.map((facility) {
                            return Chip(
                              label: Text(facility),
                              onDeleted: () => _removeFacility(facility),
                            );
                          }).toList(),
                        ),
                      ],
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
                          : Text(widget.room == null ? 'Create' : 'Update'),
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
