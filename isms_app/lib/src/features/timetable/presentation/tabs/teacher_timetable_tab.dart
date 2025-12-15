import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/timetable_providers.dart';
import '../../../authentication/domain/user_role.dart';
import '../../../staff_management/application/staff_providers.dart';
import '../widgets/teacher_timetable_view.dart';

/// Tab for viewing teacher timetables
class TeacherTimetableTab extends ConsumerStatefulWidget {
  const TeacherTimetableTab({super.key});

  @override
  ConsumerState<TeacherTimetableTab> createState() =>
      _TeacherTimetableTabState();
}

class _TeacherTimetableTabState extends ConsumerState<TeacherTimetableTab> {
  String? _selectedTeacherId;

  @override
  Widget build(BuildContext context) {
    final staffAsync = ref.watch(
      staffListProvider((query: null, role: null, status: 'active')),
    );
    final teacherTimetableAsync = _selectedTeacherId != null
        ? ref.watch(teacherTimetableProvider(_selectedTeacherId!))
        : null;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Teacher Timetable',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          staffAsync.when(
            data: (staffMembers) {
              final teachers = staffMembers
                  .where((s) => s.role == UserRole.teacher)
                  .toList();

              if (teachers.isEmpty) {
                return const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: Text('No teachers found')),
                  ),
                );
              }

              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Select Teacher',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                    ),
                    value: _selectedTeacherId,
                    items: teachers.map((teacher) {
                      return DropdownMenuItem(
                        value: teacher.id,
                        child: Text(teacher.fullName ?? teacher.email),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedTeacherId = value;
                      });
                    },
                  ),
                ),
              );
            },
            loading: () => const LinearProgressIndicator(),
            error: (_, __) => const Text('Error loading teachers'),
          ),
          const SizedBox(height: 24),
          if (_selectedTeacherId != null)
            Expanded(
              child: teacherTimetableAsync!.when(
                data: (entries) {
                  if (entries.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.calendar_today_outlined,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No schedule assigned',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'This teacher has no timetable entries',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    );
                  }

                  return TeacherTimetableView(entries: entries);
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Error loading timetable',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        error.toString(),
                        style: Theme.of(context).textTheme.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.person_outline,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Select a teacher to view timetable',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
