import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../examination/presentation/tabs/report_cards_tab.dart';

class AcademicTab extends ConsumerWidget {
  final String? selectedStudentId;

  const AcademicTab({
    super.key,
    this.selectedStudentId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // For parent portal, show report cards
    return const ReportCardsTab();
  }
}

