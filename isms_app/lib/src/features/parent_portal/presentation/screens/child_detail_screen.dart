import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../student_management/domain/student.dart';
import '../tabs/attendance_tab.dart';
import '../tabs/fees_tab.dart';
import '../tabs/academic_tab.dart';
import '../tabs/assignments_tab.dart';

class ChildDetailScreen extends ConsumerStatefulWidget {
  final Student student;

  const ChildDetailScreen({
    super.key,
    required this.student,
  });

  @override
  ConsumerState<ChildDetailScreen> createState() => _ChildDetailScreenState();
}

class _ChildDetailScreenState extends ConsumerState<ChildDetailScreen>
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
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                widget.student.fullName,
                style: const TextStyle(
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
                child: Center(
                  child: Hero(
                    tag: 'student_${widget.student.id}',
                    child: CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.white,
                      child: Text(
                        widget.student.fullName[0].toUpperCase(),
                        style: TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
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
                Tab(icon: Icon(Icons.check_circle), text: 'Attendance'),
                Tab(icon: Icon(Icons.account_balance_wallet), text: 'Fees'),
                Tab(icon: Icon(Icons.school), text: 'Academic'),
                Tab(icon: Icon(Icons.assignment), text: 'Assignments'),
              ],
            ),
          ),
          SliverFillRemaining(
            child: TabBarView(
              controller: _tabController,
              children: const [
                AttendanceTab(),
                FeesTab(),
                AcademicTab(),
                AssignmentsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

