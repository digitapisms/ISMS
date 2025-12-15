import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../application/examination_providers.dart';
import '../../domain/exam_grade.dart';

/// Tab for performance analytics
class PerformanceAnalyticsTab extends ConsumerWidget {
  const PerformanceAnalyticsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gradesAsync = ref.watch(examGradesProvider);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Performance Analytics',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 24),
            gradesAsync.when(
              data: (grades) {
                if (grades.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.analytics_outlined,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No grade data available',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Enter grades to see analytics',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  );
                }

                // Calculate statistics
                final totalGrades = grades.length;
                final passedGrades = grades.where((g) {
                  return g.percentage != null && g.percentage! >= 33;
                }).length;
                final failedGrades = totalGrades - passedGrades;
                final avgPercentage =
                    grades
                        .where((g) => g.percentage != null)
                        .fold<double>(
                          0,
                          (sum, g) => sum + (g.percentage ?? 0),
                        ) /
                    (grades.where((g) => g.percentage != null).length);

                return Column(
                  children: [
                    // Summary Cards
                    Row(
                      children: [
                        Expanded(
                          child: _SummaryCard(
                            title: 'Total Grades',
                            value: totalGrades.toString(),
                            icon: Icons.grade,
                            color: Colors.blue,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _SummaryCard(
                            title: 'Passed',
                            value: passedGrades.toString(),
                            icon: Icons.check_circle,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _SummaryCard(
                            title: 'Failed',
                            value: failedGrades.toString(),
                            icon: Icons.cancel,
                            color: Colors.red,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _SummaryCard(
                            title: 'Average %',
                            value: avgPercentage.toStringAsFixed(2),
                            icon: Icons.trending_up,
                            color: Colors.orange,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Grade Distribution Chart
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Grade Distribution',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              height: 200,
                              child: _buildGradeDistributionChart(grades),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
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
                      'Error loading analytics',
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
          ],
        ),
      ),
    );
  }

  Widget _buildGradeDistributionChart(List<ExamGrade> grades) {
    final gradeCounts = <String, int>{};
    for (final grade in grades) {
      if (grade.grade != null) {
        gradeCounts[grade.grade!] = (gradeCounts[grade.grade!] ?? 0) + 1;
      }
    }

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: gradeCounts.values.isEmpty
            ? 10.0
            : gradeCounts.values.reduce((a, b) => a > b ? a : b).toDouble() *
                  1.2,
        barTouchData: BarTouchData(enabled: false),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final grades = ['A+', 'A', 'B+', 'B', 'C+', 'C', 'D', 'F'];
                if (value.toInt() < grades.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      grades[value.toInt()],
                      style: const TextStyle(fontSize: 10),
                    ),
                  );
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),
                  style: const TextStyle(fontSize: 10),
                );
              },
            ),
          ),
        ),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        barGroups: ['A+', 'A', 'B+', 'B', 'C+', 'C', 'D', 'F']
            .asMap()
            .entries
            .map((entry) {
              final index = entry.key;
              final grade = entry.value;
              return BarChartGroupData(
                x: index,
                barRods: [
                  BarChartRodData(
                    toY: gradeCounts[grade]?.toDouble() ?? 0,
                    color: _getGradeColor(grade),
                    width: 20,
                  ),
                ],
              );
            })
            .toList(),
      ),
    );
  }

  Color _getGradeColor(String grade) {
    switch (grade) {
      case 'A+':
        return Colors.green;
      case 'A':
        return Colors.lightGreen;
      case 'B+':
        return Colors.blue;
      case 'B':
        return Colors.lightBlue;
      case 'C+':
        return Colors.orange;
      case 'C':
        return Colors.deepOrange;
      case 'D':
        return Colors.red;
      case 'F':
        return Colors.red.shade900;
      default:
        return Colors.grey;
    }
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: color.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: color),
                Text(title, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
