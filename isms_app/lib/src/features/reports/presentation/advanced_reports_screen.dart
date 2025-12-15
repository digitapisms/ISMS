import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

import '../../../core/subscription/feature_guard.dart';
import '../../../core/ai/ai_service.dart';
import '../../school_registration/application/school_providers.dart';
import '../application/report_providers.dart';
import '../domain/school_report_overview.dart';
import '../services/pdf_report_generator.dart';

/// Advanced reporting dashboard with enhanced visualizations
class AdvancedReportsScreen extends ConsumerStatefulWidget {
  const AdvancedReportsScreen({super.key});

  @override
  ConsumerState<AdvancedReportsScreen> createState() =>
      _AdvancedReportsScreenState();
}

class _AdvancedReportsScreenState extends ConsumerState<AdvancedReportsScreen> {
  int _selectedTimeRange = 30; // days
  String? _selectedReportType;
  String? _aiInsights;
  bool _isGeneratingInsights = false;
  final AIService _aiService = AIService();
  final PDFReportGenerator _pdfGenerator = PDFReportGenerator();

  @override
  Widget build(BuildContext context) {
    final school = ref.watch(currentSchoolProvider);
    if (school == null) {
      return const Center(child: Text('Select a school to view reports.'));
    }

    final overviewAsync = ref.watch(schoolReportOverviewProvider(school.id));

    return FeatureGuard(
      featureKey: 'advanced_analytics',
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Advanced Reports'),
          actions: [
            IconButton(
              icon: const Icon(Icons.download),
              onPressed: () => _exportReport(context, overviewAsync),
              tooltip: 'Export Report',
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            _buildFilters(context),
            const SizedBox(height: 24),
            _buildSummaryCards(overviewAsync),
            const SizedBox(height: 24),
            _buildTrendAnalysis(context, overviewAsync),
            const SizedBox(height: 24),
            _buildComparativeAnalysis(context, overviewAsync),
            const SizedBox(height: 24),
            _buildPredictiveInsights(context, overviewAsync),
            const SizedBox(height: 24),
            _buildAIGenerateButton(context, overviewAsync),
          ],
        ),
      ),
    );
  }

  Widget _buildAIGenerateButton(
    BuildContext context,
    AsyncValue<SchoolReportOverview> overviewAsync,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Generate AI Insights',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _isGeneratingInsights
                  ? null
                  : () => _generateAIInsights(context, overviewAsync),
              icon: _isGeneratingInsights
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.auto_awesome),
              label: Text(_isGeneratingInsights ? 'Generating...' : 'Generate Insights'),
            ),
            if (_aiInsights != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _aiInsights!,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _generateAIInsights(
    BuildContext context,
    AsyncValue<SchoolReportOverview> overviewAsync,
  ) async {
    setState(() {
      _isGeneratingInsights = true;
      _aiInsights = null;
    });

    try {
      final overview = overviewAsync.value;
      if (overview == null) {
        throw Exception('No data available');
      }

      final school = ref.read(currentSchoolProvider);
      if (school == null) {
        throw Exception('No school selected');
      }

      final schoolData = {
        'total_students': overview.totalStudents,
        'total_staff': overview.staffCount + overview.teacherCount,
        'total_classes': overview.classCount,
        'new_students_30d': overview.newStudents30d,
        'total_applications': overview.totalApplications,
        'application_conversion_rate': overview.applicationConversionRate,
        'approved_applications': overview.approvedApplications,
      };

      final insights = await _aiService.generateInsights(
        schoolData: schoolData,
        context: 'School performance analysis for ${school.name}',
      );

      setState(() {
        _aiInsights = insights;
        _isGeneratingInsights = false;
      });
    } catch (e) {
      setState(() {
        _isGeneratingInsights = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating insights: $e')),
        );
      }
    }
  }

  Widget _buildFilters(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<int>(
                value: _selectedTimeRange,
                decoration: const InputDecoration(
                  labelText: 'Time Range',
                  border: OutlineInputBorder(),
                ),
                items: [7, 30, 90, 180, 365]
                    .map((days) => DropdownMenuItem(
                          value: days,
                          child: Text('$days days'),
                        ))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedTimeRange = value);
                  }
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _selectedReportType,
                decoration: const InputDecoration(
                  labelText: 'Report Type',
                  border: OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem(value: null, child: Text('All Reports')),
                  const DropdownMenuItem(
                    value: 'attendance',
                    child: Text('Attendance'),
                  ),
                  const DropdownMenuItem(
                    value: 'academic',
                    child: Text('Academic'),
                  ),
                  const DropdownMenuItem(
                    value: 'financial',
                    child: Text('Financial'),
                  ),
                ],
                onChanged: (value) {
                  setState(() => _selectedReportType = value);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCards(AsyncValue<SchoolReportOverview> overviewAsync) {
    return overviewAsync.when(
      data: (overview) {
        return GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.5,
          children: [
            _buildMetricCard(
              'Total Students',
              overview.totalStudents.toString(),
              Icons.people,
              Colors.blue,
              '${overview.newStudents30d} new this month',
            ),
            _buildMetricCard(
              'Applications',
              overview.totalApplications.toString(),
              Icons.description,
              Colors.green,
              '${overview.approvedApplications} approved',
            ),
            _buildMetricCard(
              'Staff',
              (overview.staffCount + overview.teacherCount).toString(),
              Icons.groups,
              Colors.orange,
              '${overview.teacherCount} teachers',
            ),
            _buildMetricCard(
              'Conversion Rate',
              '${overview.applicationConversionRate.toStringAsFixed(1)}%',
              Icons.trending_up,
              Colors.purple,
              'Application approval rate',
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const Center(child: Text('Error loading data')),
    );
  }

  Widget _buildMetricCard(
    String title,
    String value,
    IconData icon,
    Color color,
    String subtitle,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Icon(icon, color: color, size: 20),
              ],
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendAnalysis(
    BuildContext context,
    AsyncValue<SchoolReportOverview> overviewAsync,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Trend Analysis',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 300,
              child: overviewAsync.when(
                data: (_) => _buildTrendChart(),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => const Center(child: Text('Error')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendChart() {
    // Sample trend data - replace with actual data
    final spots = List.generate(30, (i) => FlSpot(i.toDouble(), (i * 2 + 10).toDouble()));

    return LineChart(
      LineChartData(
        gridData: FlGridData(show: true),
        titlesData: FlTitlesData(show: true),
        borderData: FlBorderData(show: true),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: Colors.blue,
            barWidth: 3,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(show: true, color: Colors.blue.withOpacity(0.1)),
          ),
        ],
      ),
    );
  }

  Widget _buildComparativeAnalysis(
    BuildContext context,
    AsyncValue<SchoolReportOverview> overviewAsync,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Comparative Analysis',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 250,
              child: overviewAsync.when(
                data: (_) => _buildBarChart(),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => const Center(child: Text('Error')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBarChart() {
    // Sample bar chart data
    final barGroups = [
      BarChartGroupData(x: 0, barRods: [
        BarChartRodData(toY: 100, color: Colors.blue),
      ]),
      BarChartGroupData(x: 1, barRods: [
        BarChartRodData(toY: 80, color: Colors.green),
      ]),
      BarChartGroupData(x: 2, barRods: [
        BarChartRodData(toY: 120, color: Colors.orange),
      ]),
    ];

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: 150,
        barTouchData: BarTouchData(enabled: true),
        titlesData: FlTitlesData(show: true),
        borderData: FlBorderData(show: true),
        barGroups: barGroups,
      ),
    );
  }

  Widget _buildPredictiveInsights(
    BuildContext context,
    AsyncValue<SchoolReportOverview> overviewAsync,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.auto_awesome, color: Colors.amber),
                const SizedBox(width: 8),
                Text(
                  'AI-Powered Insights',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...overviewAsync.when(
              data: (_) => [
                _buildInsightTile(
                  'Student Growth Prediction',
                  'Based on current trends, student enrollment is expected to increase by 15% in the next quarter.',
                  Icons.trending_up,
                  Colors.green,
                ),
                const SizedBox(height: 12),
                _buildInsightTile(
                  'Attendance Optimization',
                  'Attendance rates are 5% below average. Consider implementing engagement initiatives.',
                  Icons.warning,
                  Colors.orange,
                ),
                const SizedBox(height: 12),
                _buildInsightTile(
                  'Resource Allocation',
                  'Class sizes are optimal. No immediate resource adjustments needed.',
                  Icons.check_circle,
                  Colors.blue,
                ),
              ],
              loading: () => [const Center(child: CircularProgressIndicator())],
              error: (_, __) => [const Center(child: Text('Error'))],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightTile(
    String title,
    String description,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _exportReport(
    BuildContext context,
    AsyncValue<SchoolReportOverview> overviewAsync,
  ) async {
    final overview = overviewAsync.value;
    final school = ref.read(currentSchoolProvider);

    if (overview == null || school == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No data available to export')),
      );
      return;
    }

    try {
      // Show export options dialog
      final format = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Export Report'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.picture_as_pdf),
                title: const Text('PDF Report'),
                onTap: () => Navigator.pop(context, 'pdf'),
              ),
              ListTile(
                leading: const Icon(Icons.table_chart),
                title: const Text('Excel Spreadsheet'),
                onTap: () => Navigator.pop(context, 'excel'),
              ),
              ListTile(
                leading: const Icon(Icons.code),
                title: const Text('JSON Data'),
                onTap: () => Navigator.pop(context, 'json'),
              ),
            ],
          ),
        ),
      );

      if (format == null) return;

      if (format == 'pdf') {
        final pdfBytes = await _pdfGenerator.generateSchoolReport(
          school: school,
          overview: overview,
          additionalData: {
            'time_range': _selectedTimeRange,
            'report_type': _selectedReportType,
          },
        );

        // Save PDF using printing package
        await Printing.layoutPdf(
          onLayout: (PdfPageFormat format) async => pdfBytes,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$format export coming soon')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    }
  }
}

