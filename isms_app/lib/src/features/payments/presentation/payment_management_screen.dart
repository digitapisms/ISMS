import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'tabs/payment_accounts_tab.dart';
import 'tabs/payment_transactions_tab.dart';
import 'tabs/cash_receipts_tab.dart';

class PaymentManagementScreen extends ConsumerStatefulWidget {
  const PaymentManagementScreen({super.key});

  @override
  ConsumerState<PaymentManagementScreen> createState() =>
      _PaymentManagementScreenState();
}

class _PaymentManagementScreenState
    extends ConsumerState<PaymentManagementScreen>
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
        title: const Text('Payment Management'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(
              icon: Icon(Icons.account_balance_wallet_outlined),
              text: 'Accounts',
            ),
            Tab(icon: Icon(Icons.receipt_long_outlined), text: 'Transactions'),
            Tab(icon: Icon(Icons.money_outlined), text: 'Cash Receipts'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          PaymentAccountsTab(),
          PaymentTransactionsTab(),
          CashReceiptsTab(),
        ],
      ),
    );
  }
}
