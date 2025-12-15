import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../application/fee_providers.dart';
import '../../domain/fee_invoice.dart';
import '../../domain/fee_invoice_item.dart';
import '../../domain/invoice_status.dart';
import '../dialogs/fee_invoice_form_dialog.dart';
import '../dialogs/bulk_invoice_generation_dialog.dart';
import '../widgets/payment_button.dart';
import '../widgets/fee_reminder_button.dart';
import '../../services/pdf_service.dart';
import '../../../student_management/application/student_providers.dart';
import '../../../student_management/domain/student.dart';
import '../../../school_registration/application/school_providers.dart';
import '../../../school_registration/domain/school.dart';

/// Tab for managing fee invoices/challans
class FeeInvoicesTab extends ConsumerWidget {
  const FeeInvoicesTab({super.key});

  Color _getStatusColor(InvoiceStatus status) {
    switch (status) {
      case InvoiceStatus.paid:
        return Colors.green;
      case InvoiceStatus.partial:
        return Colors.orange;
      case InvoiceStatus.overdue:
        return Colors.red;
      case InvoiceStatus.pending:
        return Colors.blue;
      case InvoiceStatus.cancelled:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invoicesAsync = ref.watch(feeInvoicesProvider);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Fee Invoices / Challans',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              Row(
                children: [
                  const FeeReminderButton(),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final result = await showDialog(
                        context: context,
                        builder: (_) => const BulkInvoiceGenerationDialog(),
                      );
                      if (result == true) {
                        ref.invalidate(feeInvoicesProvider);
                      }
                    },
                    icon: const Icon(Icons.batch_prediction),
                    label: const Text('Bulk Generate'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () async {
                      final result = await showDialog(
                        context: context,
                        builder: (_) => const FeeInvoiceFormDialog(),
                      );
                      if (result == true) {
                        ref.invalidate(feeInvoicesProvider);
                      }
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Create Invoice'),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: invoicesAsync.when(
              data: (invoices) {
                if (invoices.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.receipt_long_outlined,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No invoices found',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Create invoices to track fee payments',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: Colors.grey[600]),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: invoices.length,
                  itemBuilder: (context, index) {
                    final invoice = invoices[index];
                    final statusColor = _getStatusColor(invoice.status);
                    final dateFormat = DateFormat('MMM dd, yyyy');

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: statusColor.withOpacity(0.1),
                          child: Icon(Icons.receipt_long, color: statusColor),
                        ),
                        title: Text(
                          invoice.invoiceNumber,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Due: ${dateFormat.format(invoice.dueDate)}'),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: statusColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    invoice.status.displayName,
                                    style: TextStyle(
                                      color: statusColor,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'PKR ${invoice.totalAmount.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            if (invoice.paidAmount > 0)
                              Text(
                                'Paid: PKR ${invoice.paidAmount.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            const SizedBox(height: 8),
                            if (invoice.isPaid)
                              const Icon(
                                Icons.check_circle,
                                color: Colors.green,
                                size: 20,
                              )
                            else
                              PaymentButton(invoice: invoice),
                          ],
                        ),
                        onTap: () async {
                          // Show invoice details and PDF options
                          final studentsAsync = ref.read(studentsProvider);
                          final school = ref.read(currentSchoolProvider);
                          final repo = ref.read(feeRepositoryProvider);

                          await studentsAsync.when(
                            data: (students) async {
                              final student = students.firstWhere(
                                (s) => s.id == invoice.studentId,
                                orElse: () =>
                                    throw Exception('Student not found'),
                              );
                              final items = await repo.fetchInvoiceItems(
                                invoice.id,
                              );

                              if (context.mounted) {
                                showModalBottomSheet(
                                  context: context,
                                  builder: (context) => _InvoiceDetailsSheet(
                                    invoice: invoice,
                                    student: student,
                                    items: items,
                                    school: school,
                                  ),
                                );
                              }
                            },
                            loading: () async {},
                            error: (_, __) async {},
                          );
                        },
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Error loading invoices',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      error.toString(),
                      style: Theme.of(context).textTheme.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InvoiceDetailsSheet extends StatelessWidget {
  const _InvoiceDetailsSheet({
    required this.invoice,
    required this.student,
    required this.items,
    this.school,
  });

  final FeeInvoice invoice;
  final Student student;
  final List<FeeInvoiceItem> items;
  final School? school;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Invoice Details',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text('Invoice: ${invoice.invoiceNumber}'),
          Text('Student: ${student.fullName}'),
          Text(
            'Due Date: ${DateFormat('dd MMM yyyy').format(invoice.dueDate)}',
          ),
          Text('Status: ${invoice.status.displayName}'),
          const SizedBox(height: 16),
          Text('Items:', style: Theme.of(context).textTheme.titleMedium),
          ...items.map(
            (item) => ListTile(
              title: Text(item.description),
              trailing: Text('PKR ${item.totalAmount.toStringAsFixed(2)}'),
            ),
          ),
          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total:', style: Theme.of(context).textTheme.titleLarge),
              Text(
                'PKR ${invoice.totalAmount.toStringAsFixed(2)}',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () async {
                    await FeeInvoicePdfService.generateAndPrintChallan(
                      invoice: invoice,
                      student: student,
                      school: school,
                      items: items,
                    );
                  },
                  icon: const Icon(Icons.print),
                  label: const Text('Print Challan'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                  label: const Text('Close'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
