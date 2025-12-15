import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../attendance/presentation/tabs/attendance_history_tab.dart';

class AttendanceTab extends ConsumerWidget {
  final String? selectedStudentId;

  const AttendanceTab({
    super.key,
    this.selectedStudentId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // For parent portal, show attendance history
    // The tab has built-in filtering by student
    return const AttendanceHistoryTab();
  }
}

