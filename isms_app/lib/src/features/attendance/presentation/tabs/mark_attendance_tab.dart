import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../class_management/application/class_providers.dart';
import '../widgets/attendance_marking_widget.dart';

class MarkAttendanceTab extends ConsumerStatefulWidget {
  const MarkAttendanceTab({super.key});

  @override
  ConsumerState<MarkAttendanceTab> createState() => _MarkAttendanceTabState();
}

class _MarkAttendanceTabState extends ConsumerState<MarkAttendanceTab> {
  int? _selectedClassId;
  int? _selectedSectionId;
  DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final classesAsync = ref.watch(classesProvider);

    return Column(
      children: [
        // Filters
        Container(
          padding: const EdgeInsets.all(16),
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: Column(
            children: [
              // Date Picker
              InkWell(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime.now().subtract(
                      const Duration(days: 365),
                    ),
                    lastDate: DateTime.now().add(const Duration(days: 1)),
                  );
                  if (date != null) {
                    setState(() {
                      _selectedDate = date;
                    });
                  }
                },
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Attendance Date',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(
                    DateFormat('MMM dd, yyyy').format(_selectedDate),
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Class Selection
              classesAsync.when(
                data: (classes) {
                  if (classes.isEmpty) {
                    return const Text('No classes available');
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      DropdownButtonFormField<int>(
                        initialValue: _selectedClassId,
                        decoration: const InputDecoration(
                          labelText: 'Class *',
                          border: OutlineInputBorder(),
                        ),
                        items: classes.map((cls) {
                          return DropdownMenuItem<int>(
                            value: cls.id,
                            child: Text(cls.name),
                          );
                        }).toList(),
                        onChanged: (classId) {
                          setState(() {
                            _selectedClassId = classId;
                            _selectedSectionId = null;
                          });
                        },
                      ),
                      if (_selectedClassId != null) ...[
                        const SizedBox(height: 16),
                        _SectionSelector(
                          classId: _selectedClassId!,
                          selectedSectionId: _selectedSectionId,
                          onSectionSelected: (sectionId) {
                            setState(() {
                              _selectedSectionId = sectionId;
                            });
                          },
                        ),
                      ],
                    ],
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Text('Error: $error'),
              ),
            ],
          ),
        ),
        // Attendance Marking Widget
        if (_selectedClassId != null)
          Expanded(
            child: AttendanceMarkingWidget(
              classId: _selectedClassId!,
              sectionId: _selectedSectionId,
              attendanceDate: _selectedDate,
            ),
          )
        else
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.class_outlined, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'Select a class to mark attendance',
                    style: Theme.of(
                      context,
                    ).textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _SectionSelector extends ConsumerWidget {
  const _SectionSelector({
    required this.classId,
    this.selectedSectionId,
    required this.onSectionSelected,
  });

  final int classId;
  final int? selectedSectionId;
  final ValueChanged<int?> onSectionSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sectionsAsync = ref.watch(sectionsProvider(classId));

    return sectionsAsync.when(
      data: (sections) {
        return DropdownButtonFormField<int>(
          initialValue: selectedSectionId,
          decoration: const InputDecoration(
            labelText: 'Section (Optional)',
            border: OutlineInputBorder(),
            helperText: 'Leave empty for all sections',
          ),
          items: [
            const DropdownMenuItem<int>(
              value: null,
              child: Text('All Sections'),
            ),
            ...sections.map((section) {
              return DropdownMenuItem(
                value: section.id,
                child: Text(section.name),
              );
            }),
          ],
          onChanged: onSectionSelected,
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => const SizedBox.shrink(),
    );
  }
}
