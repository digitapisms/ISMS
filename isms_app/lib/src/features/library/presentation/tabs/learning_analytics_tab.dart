import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../widgets/analytics_overview_cards.dart';
import '../widgets/learning_time_chart.dart';
import '../widgets/completion_rate_chart.dart';
import '../widgets/resource_engagement_chart.dart';

class LearningAnalyticsTab extends ConsumerStatefulWidget {
  const LearningAnalyticsTab({super.key});

  @override
  ConsumerState<LearningAnalyticsTab> createState() =>
      _LearningAnalyticsTabState();
}

class _LearningAnalyticsTabState extends ConsumerState<LearningAnalyticsTab> {
  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Learning Analytics Dashboard',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16),
          AnalyticsOverviewCards(),
          SizedBox(height: 24),
          LearningTimeChart(),
          SizedBox(height: 24),
          CompletionRateChart(),
          SizedBox(height: 24),
          ResourceEngagementChart(),
        ],
      ),
    );
  }
}
