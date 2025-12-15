import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'tabs/vehicles_tab.dart';
import 'tabs/routes_tab.dart';
import 'tabs/drivers_helpers_tab.dart';
import 'tabs/assignments_tab.dart';
import 'tabs/attendance_tab.dart';
import 'tabs/fees_tab.dart';

class TransportScreen extends ConsumerStatefulWidget {
  const TransportScreen({super.key});

  @override
  ConsumerState<TransportScreen> createState() => _TransportScreenState();
}

class _TransportScreenState extends ConsumerState<TransportScreen>
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
      appBar: AppBar(
        title: const Text('Transport Management'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.directions_bus), text: 'Vehicles'),
            Tab(icon: Icon(Icons.route), text: 'Routes'),
            Tab(icon: Icon(Icons.people), text: 'Drivers & Helpers'),
            Tab(icon: Icon(Icons.assignment), text: 'Assignments'),
            Tab(icon: Icon(Icons.check_circle), text: 'Attendance'),
            Tab(icon: Icon(Icons.payment), text: 'Fees'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          VehiclesTab(),
          RoutesTab(),
          DriversHelpersTab(),
          AssignmentsTab(),
          AttendanceTab(),
          FeesTab(),
        ],
      ),
    );
  }
}

