import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AnalyticsOverviewCards extends ConsumerWidget {
  const AnalyticsOverviewCards({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.5,
      children: const [
        _AnalyticsCard(
          title: 'Total Learning Time',
          value: '12h 30m',
          icon: Icons.access_time,
          color: Colors.blue,
        ),
        _AnalyticsCard(
          title: 'Resources Completed',
          value: '8/15',
          icon: Icons.check_circle,
          color: Colors.green,
        ),
        _AnalyticsCard(
          title: 'Completion Rate',
          value: '53%',
          icon: Icons.bar_chart,
          color: Colors.orange,
        ),
        _AnalyticsCard(
          title: 'Avg Engagement',
          value: '78%',
          icon: Icons.psychology,
          color: Colors.purple,
        ),
      ],
    );
  }
}

class _AnalyticsCard extends StatelessWidget {
  const _AnalyticsCard({
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
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}