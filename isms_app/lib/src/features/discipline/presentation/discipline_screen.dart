import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../authentication/application/auth_providers.dart';
import '../../authentication/domain/user_role.dart';
import 'tabs/incidents_tab.dart';
import 'tabs/actions_tab.dart';
import 'tabs/reports_tab.dart';
import 'dialogs/incident_form_dialog.dart';

class DisciplineScreen extends ConsumerStatefulWidget {
  const DisciplineScreen({super.key});

  @override
  ConsumerState<DisciplineScreen> createState() => _DisciplineScreenState();
}

class _DisciplineScreenState extends ConsumerState<DisciplineScreen>
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
    final currentUser = ref.watch(currentUserProvider).value;
    final isAdmin = currentUser?.role == UserRole.admin ||
        currentUser?.role == UserRole.principal ||
        currentUser?.role == UserRole.teacher;

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 120,
              floating: false,
              pinned: true,
              elevation: 0,
              flexibleSpace: FlexibleSpaceBar(
                title: const Text(
                  'Discipline Management',
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
                        Colors.red[700]!,
                        Colors.orange[700]!,
                      ],
                    ),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.gavel,
                      size: 64,
                      color: Colors.white70,
                    ),
                  ),
                ),
              ),
              bottom: TabBar(
                controller: _tabController,
                indicatorColor: Colors.white,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                tabs: const [
                  Tab(icon: Icon(Icons.report_problem), text: 'Incidents'),
                  Tab(icon: Icon(Icons.assignment), text: 'Actions'),
                  Tab(icon: Icon(Icons.analytics), text: 'Reports'),
                ],
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: const [
            IncidentsTab(),
            ActionsTab(),
            ReportsTab(),
          ],
        ),
      ),
      floatingActionButton: isAdmin
          ? FloatingActionButton.extended(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => const IncidentFormDialog(),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Report Incident'),
            )
          : null,
    );
  }
}

