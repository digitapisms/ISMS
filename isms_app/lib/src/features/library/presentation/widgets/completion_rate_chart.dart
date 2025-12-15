import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CompletionRateChart extends ConsumerWidget {
  const CompletionRateChart({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Completion Rate Overview',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _ProgressCircle(value: 0.53, label: 'Overall'),
                      const SizedBox(height: 16),
                      const _ProgressCircle(value: 0.78, label: 'This Week'),
                      const SizedBox(height: 16),
                      const _ProgressCircle(value: 0.45, label: 'Last Week'),
                    ],
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _CompletionMetric(label: 'Total Resources', value: '15'),
                      const SizedBox(height: 8),
                      const _CompletionMetric(label: 'Completed', value: '8'),
                      const SizedBox(height: 8),
                      const _CompletionMetric(label: 'In Progress', value: '5'),
                      const SizedBox(height: 8),
                      const _CompletionMetric(label: 'Not Started', value: '2'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgressCircle extends StatelessWidget {
  const _ProgressCircle({
    required this.value,
    required this.label,
  });

  final double value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final percentage = (value * 100).toInt();
    
    return Row(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 50,
              height: 50,
              child: CircularProgressIndicator(
                value: value,
                strokeWidth: 6,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(
                  value > 0.7 ? Colors.green : value > 0.4 ? Colors.orange : Colors.red,
                ),
              ),
            ),
            Text(
              '$percentage%',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontSize: 14)),
      ],
    );
  }
}

class _CompletionMetric extends StatelessWidget {
  const _CompletionMetric({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 14)),
        Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
      ],
    );
  }
}