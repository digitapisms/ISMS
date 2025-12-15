import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/fee_providers.dart';
import '../../services/fee_reminder_service.dart';
import '../../../student_management/application/student_providers.dart';
import '../../../school_registration/application/school_providers.dart';

class FeeReminderButton extends ConsumerWidget {
  const FeeReminderButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ElevatedButton.icon(
      onPressed: () async {
        final school = ref.read(currentSchoolProvider);
        if (school == null) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('School not found')));
          return;
        }

        // Show confirmation dialog
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Send Fee Reminders'),
            content: const Text(
              'This will send reminders to all students with overdue or upcoming fee invoices. Continue?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Send Reminders'),
              ),
            ],
          ),
        );

        if (confirmed != true) return;

        // Show loading
        if (context.mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) =>
                const Center(child: CircularProgressIndicator()),
          );
        }

        try {
          final repo = ref.read(feeRepositoryProvider);
          final invoices = await repo.fetchFeeInvoices(schoolId: school.id);
          final studentsAsync = ref.read(studentsProvider);

          await studentsAsync.when(
            data: (students) async {
              final studentsMap = {
                for (var student in students) student.id: student,
              };

              // Get overdue and upcoming invoices
              final overdue = FeeReminderService.getOverdueInvoices(invoices);
              final upcoming = FeeReminderService.getUpcomingDueInvoices(
                invoices,
              );

              // Send reminders
              await FeeReminderService.sendOverdueReminders(
                schoolId: school.id,
                overdueInvoices: overdue,
                studentsMap: studentsMap,
              );

              await FeeReminderService.sendUpcomingDueReminders(
                schoolId: school.id,
                upcomingInvoices: upcoming,
                studentsMap: studentsMap,
              );

              if (context.mounted) {
                Navigator.pop(context); // Close loading
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Sent ${overdue.length + upcoming.length} fee reminders',
                    ),
                  ),
                );
              }
            },
            loading: () async {},
            error: (_, __) async {
              throw Exception('Error loading students');
            },
          );
        } catch (e) {
          if (context.mounted) {
            Navigator.pop(context); // Close loading
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error: $e'),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
          }
        }
      },
      icon: const Icon(Icons.notifications),
      label: const Text('Send Reminders'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
    );
  }
}
