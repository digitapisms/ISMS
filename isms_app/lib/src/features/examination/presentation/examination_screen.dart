import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'tabs/exams_tab.dart';
import 'tabs/grade_entry_tab.dart';
import 'tabs/report_cards_tab.dart';
import 'tabs/performance_analytics_tab.dart';

/// Main Examination & Assessment Screen
class ExaminationScreen extends ConsumerStatefulWidget {
  const ExaminationScreen({super.key});

  @override
  ConsumerState<ExaminationScreen> createState() => _ExaminationScreenState();
}

class _ExaminationScreenState extends ConsumerState<ExaminationScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(icon: Icon(Icons.quiz_outlined), text: 'Exams'),
              Tab(icon: Icon(Icons.edit_note), text: 'Grade Entry'),
              Tab(icon: Icon(Icons.description_outlined), text: 'Report Cards'),
              Tab(icon: Icon(Icons.analytics_outlined), text: 'Analytics'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [
                ExamsTab(),
                GradeEntryTab(),
                ReportCardsTab(),
                PerformanceAnalyticsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
