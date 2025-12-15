import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/subscription/feature_guard.dart';
import '../../school_registration/application/school_providers.dart';
import '../application/report_providers.dart';
import '../domain/report_trend_point.dart';
import '../domain/school_report_overview.dart';

class ReportsAnalyticsScreen extends ConsumerStatefulWidget {
  const ReportsAnalyticsScreen({super.key});

  @override
  ConsumerState<ReportsAnalyticsScreen> createState() =>
      _ReportsAnalyticsScreenState();
}

class _ReportsAnalyticsScreenState
    extends ConsumerState<ReportsAnalyticsScreen> {
  static const _rangeOptions = [7, 30, 90];

  int _selectedRange = 30;

  Future<void> _refresh(String schoolId) async {
    ref.invalidate(schoolReportOverviewProvider(schoolId));
    ref.invalidate(
      schoolReportTrendsProvider(
        ReportTrendRequest(schoolId: schoolId, days: _selectedRange),
      ),
    );
  }

  void _setRange(String schoolId, int value) {
    if (_selectedRange == value) return;
    setState(() {
      _selectedRange = value;
    });
    ref.invalidate(
      schoolReportTrendsProvider(
        ReportTrendRequest(schoolId: schoolId, days: value),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final school = ref.watch(currentSchoolProvider);
    if (school == null) {
      return const Center(child: Text('Select a school to view reports.'));
    }

    final overviewAsync = ref.watch(schoolReportOverviewProvider(school.id));
    final trendsAsync = ref.watch(
      schoolReportTrendsProvider(
        ReportTrendRequest(schoolId: school.id, days: _selectedRange),
      ),
    );

    return FeatureGuard(
      featureKey: 'analytics_dashboard',
      child: RefreshIndicator(
        onRefresh: () => _refresh(school.id),
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            _buildHeader(context, school.name),
            const SizedBox(height: 24),
            _buildOverviewSection(overviewAsync),
            const SizedBox(height: 24),
            _buildTrendSection(context, school.id, trendsAsync),
            const SizedBox(height: 24),
            _buildApplicationsCard(context, overviewAsync),
            const SizedBox(height: 24),
            _buildEngagementCard(context, overviewAsync),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String schoolName) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Reports & Analytics',
          style: Theme.of(
            context,
          ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          '$schoolName performance overview',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ],
    );
  }

  Widget _buildOverviewSection(AsyncValue<SchoolReportOverview> overviewAsync) {
    return overviewAsync.when(
      data: (overview) {
        final cards = [
          _AnalyticsStatCard(
            title: 'Total students',
            value: overview.totalStudents,
            subtitle: '${overview.newStudents30d} in last 30 days',
            trendColor: Colors.green,
          ),
          _AnalyticsStatCard(
            title: 'Applications',
            value: overview.totalApplications,
            subtitle:
                '${overview.pendingApplications} pending · ${overview.approvedApplications} approved',
          ),
          _AnalyticsStatCard(
            title: 'Staff & teachers',
            value: overview.staffCount + overview.teacherCount,
            subtitle:
                '${overview.staffCount} staff · ${overview.teacherCount} teachers',
          ),
          _AnalyticsStatCard(
            title: 'Classes & sections',
            value: overview.classCount,
            subtitle: '${overview.sectionCount} sections',
          ),
          _AnalyticsStatCard(
            title: 'Notifications sent',
            value: overview.notifications30d,
            subtitle: 'Last 30 days',
          ),
          _AnalyticsStatCard(
            title: 'Conversion rate',
            valueLabel:
                '${overview.applicationConversionRate.toStringAsFixed(1)}%',
            subtitle: 'Approved vs total applications',
          ),
        ];

        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: cards
              .map((card) => SizedBox(width: 280, child: card))
              .toList(),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const _ErrorPlaceholder(),
    );
  }

  Widget _buildTrendSection(
    BuildContext context,
    String schoolId,
    AsyncValue<List<ReportTrendPoint>> trendsAsync,
  ) {
    return trendsAsync.when(
      data: (points) {
        final grouped = _groupTrendPoints(points);

        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Activity trends',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Students, applications, and notification volume over time',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    Wrap(
                      spacing: 8,
                      children: _rangeOptions
                          .map(
                            (days) => ChoiceChip(
                              label: Text('$days d'),
                              selected: _selectedRange == days,
                              onSelected: (_) => _setRange(schoolId, days),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 280,
                  child: grouped.isEmpty
                      ? const Center(child: Text('No activity yet'))
                      : _TrendChart(points: grouped),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const _ErrorPlaceholder(),
    );
  }

  Widget _buildApplicationsCard(
    BuildContext context,
    AsyncValue<SchoolReportOverview> overviewAsync,
  ) {
    return overviewAsync.when(
      data: (overview) {
        final breakdown = overview.applicationStatusBreakdown;
        final total = breakdown.values.fold<int>(0, (a, b) => a + b);

        final sections = breakdown.entries
            .where((entry) => entry.value > 0)
            .map(
              (entry) => PieChartSectionData(
                value: entry.value.toDouble(),
                title: total == 0
                    ? '0%'
                    : '${((entry.value / total) * 100).round()}%',
                color: _statusColor(entry.key, context),
                radius: 70,
                titleStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
            .toList();

        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Applications breakdown',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Track the admissions funnel across statuses',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${overview.totalApplications} total',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 250,
                  child: Row(
                    children: [
                      Expanded(
                        child: sections.isEmpty
                            ? const Center(child: Text('No applications yet'))
                            : PieChart(
                                PieChartData(
                                  sections: sections,
                                  sectionsSpace: 2,
                                  centerSpaceRadius: 48,
                                  borderData: FlBorderData(show: false),
                                ),
                              ),
                      ),
                      const SizedBox(width: 24),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: breakdown.entries.map((entry) {
                          final percentage = total == 0
                              ? 0
                              : ((entry.value / total) * 100).round();
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                              children: [
                                Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: _statusColor(entry.key, context),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(entry.key),
                                const SizedBox(width: 6),
                                Text(
                                  '${entry.value} ($percentage%)',
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurfaceVariant,
                                      ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const _ErrorPlaceholder(),
    );
  }

  Widget _buildEngagementCard(
    BuildContext context,
    AsyncValue<SchoolReportOverview> overviewAsync,
  ) {
    return overviewAsync.when(
      data: (overview) {
        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Engagement insights',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    _InsightTile(
                      title: 'Notifications (30d)',
                      value: overview.notifications30d,
                      subtitle: overview.notifications30d > 0
                          ? 'Stay consistent with parent outreach.'
                          : 'No notifications sent recently.',
                      icon: Icons.notifications_active_outlined,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    _InsightTile(
                      title: 'Adult to student ratio',
                      valueLabel: _formatRatio(
                        students: overview.totalStudents,
                        adults: overview.staffCount + overview.teacherCount,
                      ),
                      subtitle: 'Students per adult user',
                      icon: Icons.groups_2_outlined,
                      color: Theme.of(context).colorScheme.tertiary,
                    ),
                    if (overview.lastActivityAt != null)
                      _InsightTile(
                        title: 'Last activity',
                        valueLabel: DateFormat.yMMMEd().add_jm().format(
                          overview.lastActivityAt!.toLocal(),
                        ),
                        subtitle:
                            'Latest student, application, or notification action',
                        icon: Icons.timeline_outlined,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const _ErrorPlaceholder(),
    );
  }

  List<ReportTrendPoint> _groupTrendPoints(List<ReportTrendPoint> points) {
    final sorted = [...points]..sort((a, b) => a.date.compareTo(b.date));
    return sorted;
  }

  String _formatRatio({required int students, required int adults}) {
    if (students == 0 || adults == 0) return '–';
    final ratio = students / adults;
    return '1:${ratio.toStringAsFixed(1)}';
  }

  Color _statusColor(String status, BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    switch (status.toLowerCase()) {
      case 'approved':
        return colorScheme.primary;
      case 'pending':
        return colorScheme.secondary;
      case 'under review':
        return colorScheme.tertiary;
      case 'rejected':
        return colorScheme.error;
      default:
        return colorScheme.outline;
    }
  }
}

class _AnalyticsStatCard extends StatelessWidget {
  const _AnalyticsStatCard({
    required this.title,
    this.value,
    this.valueLabel,
    this.subtitle,
    this.trendColor,
  }) : assert(
         value != null || valueLabel != null,
         'Either value or valueLabel must be provided',
       );

  final String title;
  final int? value;
  final String? valueLabel;
  final String? subtitle;
  final Color? trendColor;

  static final _formatter = NumberFormat.compact();

  @override
  Widget build(BuildContext context) {
    final label = valueLabel ?? _formatter.format(value ?? 0);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color:
                      trendColor ??
                      Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _InsightTile extends StatelessWidget {
  const _InsightTile({
    required this.title,
    this.value,
    this.valueLabel,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  final String title;
  final int? value;
  final String? valueLabel;
  final String subtitle;
  final IconData icon;
  final Color color;

  static final _formatter = NumberFormat.compact();

  @override
  Widget build(BuildContext context) {
    final displayValue = valueLabel ?? _formatter.format(value ?? 0);
    return Container(
      width: 280,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.labelLarge),
                Text(
                  displayValue,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TrendChart extends StatelessWidget {
  const _TrendChart({required this.points});

  final List<ReportTrendPoint> points;

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return const Center(child: Text('No data yet'));
    }

    final dates =
        points.map((point) => DateUtils.dateOnly(point.date)).toSet().toList()
          ..sort();

    final dateIndex = <DateTime, double>{
      for (var i = 0; i < dates.length; i++) dates[i]: i.toDouble(),
    };

    final students = points
        .where((p) => p.metric == 'students')
        .map(
          (p) => FlSpot(
            dateIndex[DateUtils.dateOnly(p.date)] ?? 0,
            p.value.toDouble(),
          ),
        )
        .toList();

    final applications = points
        .where((p) => p.metric == 'applications')
        .map(
          (p) => FlSpot(
            dateIndex[DateUtils.dateOnly(p.date)] ?? 0,
            p.value.toDouble(),
          ),
        )
        .toList();

    final notifications = points
        .where((p) => p.metric == 'notifications')
        .map(
          (p) => FlSpot(
            dateIndex[DateUtils.dateOnly(p.date)] ?? 0,
            p.value.toDouble(),
          ),
        )
        .toList();

    final double maxY = <double>[
      ...students.map((spot) => spot.y),
      ...applications.map((spot) => spot.y),
      ...notifications.map((spot) => spot.y),
      5.0,
    ].reduce((a, b) => a > b ? a : b);

    final metricLabels = ['Students', 'Applications', 'Notifications'];
    final double interval = maxY == 0 ? 1.0 : (maxY / 4).clamp(1.0, maxY);

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: (dates.length - 1).toDouble(),
        minY: 0,
        maxY: (maxY * 1.2).clamp(5, double.infinity),
        gridData: FlGridData(show: true, horizontalInterval: interval),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 36,
              getTitlesWidget: (value, meta) {
                final index = value.round().clamp(0, dates.length - 1);
                final date = dates[index];
                if (index == 0 ||
                    index == dates.length - 1 ||
                    index == (dates.length / 2).round()) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      DateFormat.Md().format(date),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) => Text(
                value.toInt().toString(),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        lineBarsData: [
          _line(
            context: context,
            color: Theme.of(context).colorScheme.primary,
            spots: students,
            label: 'Students',
          ),
          _line(
            context: context,
            color: Theme.of(context).colorScheme.secondary,
            spots: applications,
            label: 'Applications',
          ),
          _line(
            context: context,
            color: Theme.of(context).colorScheme.tertiary,
            spots: notifications,
            label: 'Notifications',
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) =>
                Theme.of(context).colorScheme.surface.withValues(alpha: 0.9),
            getTooltipItems: (spots) => spots.map((spot) {
              final label = metricLabels.elementAt(
                spot.barIndex.clamp(0, metricLabels.length - 1),
              );
              final date = dates[spot.x.toInt()];
              return LineTooltipItem(
                '${DateFormat.MMMd().format(date)}\n$label: ${spot.y.toInt()}',
                Theme.of(context).textTheme.bodyMedium!,
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  LineChartBarData _line({
    required BuildContext context,
    required Color color,
    required List<FlSpot> spots,
    required String label,
  }) {
    return LineChartBarData(
      spots: spots,
      color: color,
      barWidth: 3,
      isCurved: true,
      dotData: const FlDotData(show: false),
      belowBarData: BarAreaData(
        show: true,
        color: color.withValues(alpha: 0.08),
      ),
    );
  }
}

class _ErrorPlaceholder extends StatelessWidget {
  const _ErrorPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Theme.of(context).colorScheme.errorContainer,
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: Theme.of(context).colorScheme.onErrorContainer,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Unable to load reports. Pull to refresh or try again later.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onErrorContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
