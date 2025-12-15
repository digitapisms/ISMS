import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'tabs/check_in_tab.dart';
import 'tabs/visitors_tab.dart';
import 'tabs/visits_tab.dart';
import 'tabs/security_tab.dart';

class VisitorManagementScreen extends ConsumerStatefulWidget {
  const VisitorManagementScreen({super.key});

  @override
  ConsumerState<VisitorManagementScreen> createState() => _VisitorManagementScreenState();
}

class _VisitorManagementScreenState extends ConsumerState<VisitorManagementScreen>
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
      appBar: AppBar(
        title: const Text('Visitor Management'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.login), text: 'Check In'),
            Tab(icon: Icon(Icons.people), text: 'Visitors'),
            Tab(icon: Icon(Icons.history), text: 'Visits'),
            Tab(icon: Icon(Icons.security), text: 'Security'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          CheckInTab(),
          VisitorsTab(),
          VisitsTab(),
          SecurityTab(),
        ],
      ),
    );
  }
}

