import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'tabs/mark_attendance_tab.dart';
import 'tabs/attendance_history_tab.dart';
import 'tabs/attendance_reports_tab.dart';

class AttendanceScreen extends ConsumerStatefulWidget {
  const AttendanceScreen({super.key});

  @override
  ConsumerState<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends ConsumerState<AttendanceScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance Management'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(
              icon: Icon(Icons.check_circle_outline),
              text: 'Mark Attendance',
            ),
            Tab(icon: Icon(Icons.history), text: 'History'),
            Tab(icon: Icon(Icons.analytics_outlined), text: 'Reports'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          MarkAttendanceTab(),
          AttendanceHistoryTab(),
          AttendanceReportsTab(),
        ],
      ),
    );
  }
}
