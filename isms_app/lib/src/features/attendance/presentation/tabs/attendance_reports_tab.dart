import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../application/attendance_providers.dart';
import '../../domain/attendance_stats.dart';
import '../../../class_management/application/class_providers.dart';

class AttendanceReportsTab extends ConsumerStatefulWidget {
  const AttendanceReportsTab({super.key});

  @override
  ConsumerState<AttendanceReportsTab> createState() =>
      _AttendanceReportsTabState();
}

class _AttendanceReportsTabState extends ConsumerState<AttendanceReportsTab> {
  int? _selectedClassId;
  int? _selectedSectionId;
  String? _selectedStudentId;
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Filters
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Report Filters',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
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
                              initialDate: _startDate,
                              firstDate: DateTime.now().subtract(
                                const Duration(days: 365),
                              ),
                              lastDate: _endDate,
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
                              suffixIcon: Icon(Icons.calendar_today, size: 20),
                            ),
                            child: Text(
                              DateFormat('MMM dd, yyyy').format(_startDate),
                              style: Theme.of(context).textTheme.bodyMedium,
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
                              initialDate: _endDate,
                              firstDate: _startDate,
                              lastDate: DateTime.now(),
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
                              suffixIcon: Icon(Icons.calendar_today, size: 20),
                            ),
                            child: Text(
                              DateFormat('MMM dd, yyyy').format(_endDate),
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Class Selection
                  _ClassSelector(
                    selectedClassId: _selectedClassId,
                    onClassSelected: (classId) {
                      setState(() {
                        _selectedClassId = classId;
                        _selectedSectionId = null;
                        _selectedStudentId = null;
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
                          _selectedStudentId = null;
                        });
                      },
                    ),
                  ],
                  if (_selectedClassId != null) ...[
                    const SizedBox(height: 16),
                    _StudentSelector(
                      classId: _selectedClassId!,
                      sectionId: _selectedSectionId,
                      selectedStudentId: _selectedStudentId,
                      onStudentSelected: (studentId) {
                        setState(() {
                          _selectedStudentId = studentId;
                        });
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Statistics
          if (_selectedStudentId != null)
            _StudentStatsCard(
              studentId: _selectedStudentId!,
              startDate: _startDate,
              endDate: _endDate,
            )
          else
            Card(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(
                      Icons.analytics_outlined,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Select a student to view attendance statistics',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
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

class _ClassSelector extends ConsumerWidget {
  const _ClassSelector({this.selectedClassId, required this.onClassSelected});

  final int? selectedClassId;
  final ValueChanged<int?> onClassSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final classesAsync = ref.watch(classesProvider);

    return classesAsync.when(
      data: (classes) {
        if (classes.isEmpty) {
          return const Text('No classes available');
        }
        return DropdownButtonFormField<int>(
          value: selectedClassId,
          decoration: const InputDecoration(
            labelText: 'Class',
            border: OutlineInputBorder(),
          ),
          items: classes.map((cls) {
            return DropdownMenuItem(value: cls.id, child: Text(cls.name));
          }).toList(),
          onChanged: onClassSelected,
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Text('Error: $error'),
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
          value: selectedSectionId,
          decoration: const InputDecoration(
            labelText: 'Section (Optional)',
            border: OutlineInputBorder(),
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
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _StudentSelector extends ConsumerWidget {
  const _StudentSelector({
    required this.classId,
    this.sectionId,
    this.selectedStudentId,
    required this.onStudentSelected,
  });

  final int classId;
  final int? sectionId;
  final String? selectedStudentId;
  final ValueChanged<String?> onStudentSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final studentsAsync = ref.watch(
      studentsForAttendanceProvider(
        AttendanceFilter(classId: classId, sectionId: sectionId),
      ),
    );

    return studentsAsync.when(
      data: (students) {
        return DropdownButtonFormField<String>(
          value: selectedStudentId,
          decoration: const InputDecoration(
            labelText: 'Student',
            border: OutlineInputBorder(),
          ),
          items: students.map((student) {
            return DropdownMenuItem(
              value: student.id,
              child: Text('${student.fullName} (${student.admissionNo})'),
            );
          }).toList(),
          onChanged: onStudentSelected,
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _StudentStatsCard extends ConsumerWidget {
  const _StudentStatsCard({
    required this.studentId,
    required this.startDate,
    required this.endDate,
  });

  final String studentId;
  final DateTime startDate;
  final DateTime endDate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(
      studentAttendanceStatsProvider(
        StudentAttendanceStatsFilter(
          studentId: studentId,
          startDate: startDate,
          endDate: endDate,
        ),
      ),
    );

    return statsAsync.when(
      data: (stats) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Attendance Statistics',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),
                // Percentage Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: _getPercentageColor(
                      stats.attendancePercentage,
                    ).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '${stats.attendancePercentage.toStringAsFixed(1)}%',
                        style: Theme.of(context).textTheme.headlineLarge
                            ?.copyWith(
                              color: _getPercentageColor(
                                stats.attendancePercentage,
                              ),
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      Text(
                        'Attendance Rate',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // Statistics Grid
                Row(
                  children: [
                    Expanded(
                      child: _StatItem(
                        label: 'Total Days',
                        value: stats.totalDays.toString(),
                        color: Colors.blue,
                      ),
                    ),
                    Expanded(
                      child: _StatItem(
                        label: 'Present',
                        value: stats.presentDays.toString(),
                        color: Colors.green,
                      ),
                    ),
                    Expanded(
                      child: _StatItem(
                        label: 'Absent',
                        value: stats.absentDays.toString(),
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _StatItem(
                        label: 'Late',
                        value: stats.lateDays.toString(),
                        color: Colors.orange,
                      ),
                    ),
                    Expanded(
                      child: _StatItem(
                        label: 'Excused',
                        value: stats.excusedDays.toString(),
                        color: Colors.blue,
                      ),
                    ),
                    Expanded(
                      child: _StatItem(
                        label: 'Half Day',
                        value: stats.halfDayDays.toString(),
                        color: Colors.purple,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Pie Chart
                SizedBox(
                  height: 200,
                  child: PieChart(
                    PieChartData(
                      sections: _buildPieChartSections(stats),
                      sectionsSpace: 2,
                      centerSpaceRadius: 40,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const Card(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (error, stack) => Card(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
              const SizedBox(height: 16),
              Text(
                'Failed to load statistics',
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
    );
  }

  Color _getPercentageColor(double percentage) {
    if (percentage >= 90) return Colors.green;
    if (percentage >= 75) return Colors.orange;
    return Colors.red;
  }

  List<PieChartSectionData> _buildPieChartSections(AttendanceStats stats) {
    return [
      if (stats.presentDays > 0)
        PieChartSectionData(
          value: stats.presentDays.toDouble(),
          title: '${stats.presentDays}',
          color: Colors.green,
          radius: 60,
        ),
      if (stats.absentDays > 0)
        PieChartSectionData(
          value: stats.absentDays.toDouble(),
          title: '${stats.absentDays}',
          color: Colors.red,
          radius: 60,
        ),
      if (stats.lateDays > 0)
        PieChartSectionData(
          value: stats.lateDays.toDouble(),
          title: '${stats.lateDays}',
          color: Colors.orange,
          radius: 60,
        ),
      if (stats.excusedDays > 0)
        PieChartSectionData(
          value: stats.excusedDays.toDouble(),
          title: '${stats.excusedDays}',
          color: Colors.blue,
          radius: 60,
        ),
      if (stats.halfDayDays > 0)
        PieChartSectionData(
          value: stats.halfDayDays.toDouble(),
          title: '${stats.halfDayDays}',
          color: Colors.purple,
          radius: 60,
        ),
    ];
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}
