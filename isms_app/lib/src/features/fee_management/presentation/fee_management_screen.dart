import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'tabs/fee_structures_tab.dart';
import 'tabs/fee_invoices_tab.dart';
import 'tabs/student_fees_tab.dart';
import 'fee_reports_screen.dart';

/// Main Fee Management Screen for Pakistani Schools
class FeeManagementScreen extends ConsumerStatefulWidget {
  const FeeManagementScreen({super.key});

  @override
  ConsumerState<FeeManagementScreen> createState() =>
      _FeeManagementScreenState();
}

class _FeeManagementScreenState extends ConsumerState<FeeManagementScreen>
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
              Tab(
                icon: Icon(Icons.account_balance_wallet_outlined),
                text: 'Fee Structures',
              ),
              Tab(
                icon: Icon(Icons.receipt_long_outlined),
                text: 'Invoices/Challans',
              ),
              Tab(icon: Icon(Icons.person_outline), text: 'Student Fees'),
              Tab(icon: Icon(Icons.analytics_outlined), text: 'Reports'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [
                FeeStructuresTab(),
                FeeInvoicesTab(),
                StudentFeesTab(),
                FeeReportsScreen(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
