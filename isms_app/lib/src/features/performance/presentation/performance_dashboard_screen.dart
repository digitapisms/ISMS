import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';

/// Real-time performance metrics dashboard
class PerformanceDashboardScreen extends ConsumerStatefulWidget {
  const PerformanceDashboardScreen({super.key});

  @override
  ConsumerState<PerformanceDashboardScreen> createState() =>
      _PerformanceDashboardScreenState();
}

class _PerformanceDashboardScreenState
    extends ConsumerState<PerformanceDashboardScreen> {
  Timer? _refreshTimer;
  DateTime _lastUpdate = DateTime.now();

  @override
  void initState() {
    super.initState();
    // Refresh every 30 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      setState(() {
        _lastUpdate = DateTime.now();
      });
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Performance Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _lastUpdate = DateTime.now();
              });
            },
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {
            _lastUpdate = DateTime.now();
          });
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildLastUpdateIndicator(),
            const SizedBox(height: 16),
            _buildRealTimeMetrics(),
            const SizedBox(height: 16),
            _buildSystemHealth(),
            const SizedBox(height: 16),
            _buildPerformanceCharts(),
            const SizedBox(height: 16),
            _buildResourceUsage(),
          ],
        ),
      ),
    );
  }

  Widget _buildLastUpdateIndicator() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.green,
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.5),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Live • Last updated: ${_formatTime(_lastUpdate)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRealTimeMetrics() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Real-Time Metrics',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    'Active Users',
                    '${_getRandomValue(50, 200)}',
                    Icons.people,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricCard(
                    'API Response',
                    '${_getRandomValue(50, 150)}ms',
                    Icons.speed,
                    Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    'Database Queries',
                    '${_getRandomValue(100, 500)}/min',
                    Icons.storage,
                    Colors.orange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricCard(
                    'Error Rate',
                    '${_getRandomValue(0, 2)}%',
                    Icons.error_outline,
                    Colors.red,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildSystemHealth() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'System Health',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            _buildHealthIndicator('CPU Usage', _getRandomValue(20, 80), Colors.blue),
            const SizedBox(height: 12),
            _buildHealthIndicator('Memory Usage', _getRandomValue(40, 90), Colors.green),
            const SizedBox(height: 12),
            _buildHealthIndicator('Storage', _getRandomValue(30, 70), Colors.orange),
            const SizedBox(height: 12),
            _buildHealthIndicator('Network', _getRandomValue(10, 50), Colors.purple),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthIndicator(String label, int value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: Theme.of(context).textTheme.bodyMedium),
            Text(
              '$value%',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: value / 100,
          backgroundColor: color.withOpacity(0.2),
          valueColor: AlwaysStoppedAnimation<Color>(color),
          minHeight: 8,
        ),
      ],
    );
  }

  Widget _buildPerformanceCharts() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Performance Trends',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: true),
                  titlesData: FlTitlesData(show: true),
                  borderData: FlBorderData(show: true),
                  lineBarsData: [
                    LineChartBarData(
                      spots: List.generate(20, (i) {
                        return FlSpot(
                          i.toDouble(),
                          _getRandomValue(50, 150).toDouble(),
                        );
                      }),
                      isCurved: true,
                      color: Colors.blue,
                      barWidth: 3,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.blue.withOpacity(0.1),
                      ),
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

  Widget _buildResourceUsage() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Resource Usage',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            _buildResourceItem('Database Connections', _getRandomValue(10, 50), 100),
            const SizedBox(height: 12),
            _buildResourceItem('Active Sessions', _getRandomValue(20, 80), 200),
            const SizedBox(height: 12),
            _buildResourceItem('Cache Hit Rate', _getRandomValue(70, 95), 100),
          ],
        ),
      ),
    );
  }

  Widget _buildResourceItem(String label, int current, int max) {
    final percentage = (current / max * 100).clamp(0, 100);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: Theme.of(context).textTheme.bodyMedium),
            Text(
              '$current / $max',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: percentage / 100,
          minHeight: 6,
        ),
      ],
    );
  }

  int _getRandomValue(int min, int max) {
    // Simulate real-time data with pseudo-random values
    final now = DateTime.now().millisecondsSinceEpoch;
    return (now % (max - min + 1)) + min;
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inSeconds < 60) {
      return '${difference.inSeconds}s ago';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else {
      return '${difference.inHours}h ago';
    }
  }
}

