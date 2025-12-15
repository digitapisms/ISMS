import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'tabs/timetables_tab.dart';
import 'tabs/periods_tab.dart';
import 'tabs/rooms_tab.dart';
import 'tabs/teacher_timetable_tab.dart';
import 'tabs/conflicts_tab.dart';

/// Main Timetable/Schedule Management Screen
class TimetableScreen extends ConsumerStatefulWidget {
  const TimetableScreen({super.key});

  @override
  ConsumerState<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends ConsumerState<TimetableScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
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
            isScrollable: true,
            tabs: const [
              Tab(icon: Icon(Icons.calendar_today), text: 'Timetables'),
              Tab(icon: Icon(Icons.access_time), text: 'Periods'),
              Tab(icon: Icon(Icons.meeting_room), text: 'Rooms'),
              Tab(icon: Icon(Icons.person), text: 'Teacher Schedule'),
              Tab(icon: Icon(Icons.warning), text: 'Conflicts'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [
                TimetablesTab(),
                PeriodsTab(),
                RoomsTab(),
                TeacherTimetableTab(),
                ConflictsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
