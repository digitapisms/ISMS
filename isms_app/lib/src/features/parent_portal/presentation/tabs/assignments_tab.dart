import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../assignments/presentation/tabs/student_assignments_tab.dart';

class AssignmentsTab extends ConsumerWidget {
  final String? selectedStudentId;

  const AssignmentsTab({
    super.key,
    this.selectedStudentId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // For parent portal, show student assignments
    return const StudentAssignmentsTab();
  }
}

