import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../authentication/application/auth_providers.dart';
import '../application/student_providers.dart';
import 'student_registration_screen.dart';
import 'edit_application_screen.dart';
import 'application_fee_payment_screen.dart';

class ApplicationStatusScreen extends ConsumerWidget {
  const ApplicationStatusScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authUser = ref.watch(authStateProvider);

    if (authUser == null) {
      return const Scaffold(body: Center(child: Text('Please sign in')));
    }

    final applicationAsync = ref.watch(applicationStatusProvider(authUser.id));

    return Scaffold(
      appBar: AppBar(title: const Text('Application Status')),
      body: applicationAsync.when(
        data: (application) {
          if (application == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.description_outlined,
                    size: 64,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No application found',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Please submit a student registration form',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('Start Registration'),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const StudentRegistrationScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            );
          }

          final status = application['status'] as String? ?? 'pending';
          final submittedAt = application['submitted_at'] as String?;
          final reviewedAt = application['reviewed_at'] as String?;
          final remarks = application['remarks'] as String?;
          final className = application['classes'] != null
              ? (application['classes'] as Map)['name'] as String?
              : null;

          Color statusColor;
          IconData statusIcon;
          String statusText;

          switch (status) {
            case 'approved':
              statusColor = Colors.green;
              statusIcon = Icons.check_circle;
              statusText = 'Approved';
              break;
            case 'rejected':
              statusColor = Colors.red;
              statusIcon = Icons.cancel;
              statusText = 'Rejected';
              break;
            case 'under_review':
              statusColor = Colors.orange;
              statusIcon = Icons.hourglass_empty;
              statusText = 'Under Review';
              break;
            default:
              statusColor = Colors.blue;
              statusIcon = Icons.pending;
              statusText = 'Pending';
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  color: statusColor.withOpacity(0.1),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Row(
                      children: [
                        Icon(statusIcon, color: statusColor, size: 48),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Application Status',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                statusText,
                                style: Theme.of(context).textTheme.headlineSmall
                                    ?.copyWith(color: statusColor),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Application Details',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 16),
                        _InfoRow(
                          label: 'Desired Class',
                          value: className ?? 'Not specified',
                        ),
                        if (submittedAt != null)
                          _InfoRow(
                            label: 'Submitted On',
                            value: _formatDate(submittedAt),
                          ),
                        if (reviewedAt != null)
                          _InfoRow(
                            label: 'Reviewed On',
                            value: _formatDate(reviewedAt),
                          ),
                        if (remarks != null && remarks.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Text(
                            'Remarks',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          const SizedBox(height: 8),
                          Text(remarks),
                        ],
                      ],
                    ),
                  ),
                ),
                if (status == 'pending' || status == 'under_review') ...[
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Card(
                      color: Colors.blue.withOpacity(0.1),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline, color: Colors.blue),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Your application is being reviewed. You will be notified once a decision is made.',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.edit),
                            label: const Text('Edit Application'),
                            onPressed: () {
                              Navigator.of(context)
                                  .push(
                                    MaterialPageRoute(
                                      builder: (_) => EditApplicationScreen(
                                        applicationId:
                                            application['id'] as String,
                                      ),
                                    ),
                                  )
                                  .then((_) {
                                    ref.invalidate(
                                      applicationStatusProvider(authUser.id),
                                    );
                                  });
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton.icon(
                            icon: const Icon(Icons.payment),
                            label: const Text('Pay Fee'),
                            onPressed: () async {
                              // Check if fee exists
                              final repo = ref.read(studentRepositoryProvider);
                              final fee = await repo.fetchApplicationFee(
                                application['id'] as String,
                              );

                              if (fee == null) {
                                // Create fee record
                                await repo.createApplicationFee(
                                  applicationId: application['id'] as String,
                                  amount: 1000.0, // Default fee amount
                                );
                              }

                              final result = await Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => ApplicationFeePaymentScreen(
                                    applicationId: application['id'] as String,
                                    amount: fee?['amount'] as double? ?? 1000.0,
                                  ),
                                ),
                              );

                              if (result == true) {
                                ref.invalidate(
                                  applicationStatusProvider(authUser.id),
                                );
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (status == 'approved')
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Card(
                      color: Colors.green.withOpacity(0.1),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle, color: Colors.green),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Congratulations! Your application has been approved. Please contact the school administration for further steps.',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(value, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}
