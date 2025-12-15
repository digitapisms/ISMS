import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../fee_management/presentation/tabs/fee_invoices_tab.dart';

class FeesTab extends ConsumerWidget {
  final String? selectedStudentId;

  const FeesTab({
    super.key,
    this.selectedStudentId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // For parent portal, show fee invoices
    return const FeeInvoicesTab();
  }
}

