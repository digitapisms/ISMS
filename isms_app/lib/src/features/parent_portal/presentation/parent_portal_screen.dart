import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'tabs/children_tab.dart';
import 'tabs/attendance_tab.dart';
import 'tabs/fees_tab.dart';
import 'tabs/academic_tab.dart';
import 'tabs/assignments_tab.dart';
import 'tabs/messages_tab.dart';

class ParentPortalScreen extends ConsumerStatefulWidget {
  const ParentPortalScreen({super.key});

  @override
  ConsumerState<ParentPortalScreen> createState() => _ParentPortalScreenState();
}

class _ParentPortalScreenState extends ConsumerState<ParentPortalScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 150,
              floating: false,
              pinned: true,
              elevation: 0,
              flexibleSpace: FlexibleSpaceBar(
                title: const Text(
                  'Parent Portal',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Theme.of(context).colorScheme.primary,
                        Theme.of(context).colorScheme.secondary,
                      ],
                    ),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.family_restroom,
                      size: 80,
                      color: Colors.white70,
                    ),
                  ),
                ),
              ),
              bottom: TabBar(
                controller: _tabController,
                isScrollable: true,
                indicatorColor: Colors.white,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                tabs: const [
                  Tab(icon: Icon(Icons.child_care), text: 'My Children'),
                  Tab(icon: Icon(Icons.check_circle), text: 'Attendance'),
                  Tab(icon: Icon(Icons.account_balance_wallet), text: 'Fees'),
                  Tab(icon: Icon(Icons.school), text: 'Academic'),
                  Tab(icon: Icon(Icons.assignment), text: 'Assignments'),
                  Tab(icon: Icon(Icons.chat), text: 'Messages'),
                ],
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: const [
            ChildrenTab(),
            AttendanceTab(),
            FeesTab(),
            AcademicTab(),
            AssignmentsTab(),
            MessagesTab(),
          ],
        ),
      ),
    );
  }
}
