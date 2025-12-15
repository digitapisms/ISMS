import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/fee_providers.dart';
import '../../../student_management/application/student_providers.dart';

/// Tab for viewing student fees
class StudentFeesTab extends ConsumerStatefulWidget {
  const StudentFeesTab({super.key});

  @override
  ConsumerState<StudentFeesTab> createState() => _StudentFeesTabState();
}

class _StudentFeesTabState extends ConsumerState<StudentFeesTab> {
  String? _selectedStudentId;

  @override
  Widget build(BuildContext context) {
    final studentsAsync = ref.watch(studentsProvider);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Student Fee Management',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          // Student selector
          studentsAsync.when(
            data: (students) {
              return DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Select Student',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person_outline),
                ),
                initialValue: _selectedStudentId,
                items: students.map((student) {
                  return DropdownMenuItem(
                    value: student.id,
                    child: Text('${student.fullName} (${student.admissionNo})'),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedStudentId = value;
                  });
                },
              );
            },
            loading: () => const LinearProgressIndicator(),
            error: (_, __) => const Text('Error loading students'),
          ),
          const SizedBox(height: 24),
          // Student fee summary and invoices
          if (_selectedStudentId != null)
            Expanded(child: _StudentFeeDetails(studentId: _selectedStudentId!))
          else
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.person_outline,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Select a student to view fee details',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _StudentFeeDetails extends ConsumerWidget {
  const _StudentFeeDetails({required this.studentId});

  final String studentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(studentFeeSummaryProvider(studentId));
    final invoicesAsync = ref.watch(studentFeeInvoicesProvider(studentId));

    return Column(
      children: [
        // Fee Summary Card
        summaryAsync.when(
          data: (summary) => Card(
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Fee Summary',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _SummaryItem(
                          label: 'Total Outstanding',
                          value:
                              'PKR ${summary.totalOutstanding.toStringAsFixed(2)}',
                          color: Colors.red,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _SummaryItem(
                          label: 'Total Paid',
                          value:
                              'PKR ${summary.totalPaidAmount.toStringAsFixed(2)}',
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _SummaryItem(
                          label: 'Pending',
                          value: '${summary.pendingInvoices}',
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _SummaryItem(
                          label: 'Overdue',
                          value: '${summary.overdueInvoices}',
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          loading: () => const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
          ),
          error: (_, __) => const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('Error loading summary'),
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Invoices List
        Expanded(
          child: invoicesAsync.when(
            data: (invoices) {
              if (invoices.isEmpty) {
                return const Center(
                  child: Text('No invoices found for this student'),
                );
              }

              return ListView.builder(
                itemCount: invoices.length,
                itemBuilder: (context, index) {
                  final invoice = invoices[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: invoice.isPaid
                            ? Colors.green.withOpacity(0.1)
                            : Colors.orange.withOpacity(0.1),
                        child: Icon(
                          invoice.isPaid ? Icons.check_circle : Icons.pending,
                          color: invoice.isPaid ? Colors.green : Colors.orange,
                        ),
                      ),
                      title: Text(invoice.invoiceNumber),
                      subtitle: Text(
                        'Due: ${invoice.dueDate.toString().split(' ')[0]}',
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'PKR ${invoice.totalAmount.toStringAsFixed(2)}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          if (invoice.outstandingAmount > 0)
                            Text(
                              'Outstanding: PKR ${invoice.outstandingAmount.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.red[700],
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) =>
                const Center(child: Text('Error loading invoices')),
          ),
        ),
      ],
    );
  }
}

class _SummaryItem extends StatelessWidget {
  const _SummaryItem({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
