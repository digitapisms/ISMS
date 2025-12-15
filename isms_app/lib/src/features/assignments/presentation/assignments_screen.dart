import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../authentication/application/auth_providers.dart';
import '../../authentication/domain/user_role.dart';
import 'tabs/teacher_assignments_tab.dart';
import 'tabs/student_assignments_tab.dart';

/// Main Homework/Assignment Management Screen
class AssignmentsScreen extends ConsumerStatefulWidget {
  const AssignmentsScreen({super.key});

  @override
  ConsumerState<AssignmentsScreen> createState() => _AssignmentsScreenState();
}

class _AssignmentsScreenState extends ConsumerState<AssignmentsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authUser = ref.watch(authStateProvider);
    final isStudent = authUser?.role == UserRole.student;

    return Scaffold(
      body: Column(
        children: [
          TabBar(
            controller: _tabController,
            tabs: isStudent
                ? [const Tab(icon: Icon(Icons.school), text: 'My Assignments')]
                : [
                    const Tab(
                      icon: Icon(Icons.assignment),
                      text: 'My Assignments',
                    ),
                    const Tab(icon: Icon(Icons.school), text: 'Student View'),
                  ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: isStudent
                  ? [const StudentAssignmentsTab()]
                  : [
                      const TeacherAssignmentsTab(),
                      const StudentAssignmentsTab(),
                    ],
            ),
          ),
        ],
      ),
    );
  }
}
