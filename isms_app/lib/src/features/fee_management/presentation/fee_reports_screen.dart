import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../application/fee_providers.dart';
import '../domain/fee_invoice.dart';
import '../domain/invoice_status.dart';

class FeeReportsScreen extends ConsumerStatefulWidget {
  const FeeReportsScreen({super.key});

  @override
  ConsumerState<FeeReportsScreen> createState() => _FeeReportsScreenState();
}

class _FeeReportsScreenState extends ConsumerState<FeeReportsScreen> {
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  InvoiceStatus? _selectedStatus;

  @override
  Widget build(BuildContext context) {
    final invoicesAsync = ref.watch(feeInvoicesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fee Reports & Analytics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterDialog(),
          ),
        ],
      ),
      body: invoicesAsync.when(
        data: (allInvoices) {
          // Filter invoices
          final invoices = allInvoices.where((inv) {
            if (_selectedStatus != null && inv.status != _selectedStatus) {
              return false;
            }
            if (inv.dueDate.isBefore(_startDate) ||
                inv.dueDate.isAfter(_endDate)) {
              return false;
            }
            return true;
          }).toList();

          // Calculate statistics
          final totalAmount = invoices.fold<double>(
            0,
            (sum, inv) => sum + inv.totalAmount,
          );
          final paidAmount = invoices.fold<double>(
            0,
            (sum, inv) => sum + inv.paidAmount,
          );
          final outstandingAmount = totalAmount - paidAmount;

          final statusCounts = <InvoiceStatus, int>{};
          for (final status in InvoiceStatus.values) {
            statusCounts[status] = invoices
                .where((inv) => inv.status == status)
                .length;
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Summary Cards
                Row(
                  children: [
                    Expanded(
                      child: _SummaryCard(
                        title: 'Total Invoices',
                        value: invoices.length.toString(),
                        icon: Icons.receipt_long,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _SummaryCard(
                        title: 'Total Amount',
                        value: 'PKR ${totalAmount.toStringAsFixed(2)}',
                        icon: Icons.account_balance_wallet,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _SummaryCard(
                        title: 'Paid Amount',
                        value: 'PKR ${paidAmount.toStringAsFixed(2)}',
                        icon: Icons.check_circle,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _SummaryCard(
                        title: 'Outstanding',
                        value: 'PKR ${outstandingAmount.toStringAsFixed(2)}',
                        icon: Icons.warning,
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Status Distribution Chart
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Invoice Status Distribution',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 200,
                          child: PieChart(
                            PieChartData(
                              sections: statusCounts.entries.map((entry) {
                                return PieChartSectionData(
                                  value: entry.value.toDouble(),
                                  title: '${entry.value}',
                                  color: _getStatusColor(entry.key),
                                  radius: 80,
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 16,
                          runSpacing: 8,
                          children: statusCounts.entries.map((entry) {
                            return Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 16,
                                  height: 16,
                                  color: _getStatusColor(entry.key),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${entry.key.displayName}: ${entry.value}',
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Monthly Collection Chart
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Monthly Collection',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 200,
                          child: _buildMonthlyChart(invoices),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Error loading reports',
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
    );
  }

  Widget _buildMonthlyChart(List<FeeInvoice> invoices) {
    // Group by month
    final monthlyData = <String, double>{};
    for (final invoice in invoices) {
      final month = DateFormat('MMM yyyy').format(invoice.dueDate);
      monthlyData[month] = (monthlyData[month] ?? 0) + invoice.paidAmount;
    }

    final sortedMonths = monthlyData.keys.toList()..sort();
    final maxValue = monthlyData.values.isEmpty
        ? 100.0
        : monthlyData.values.reduce((a, b) => a > b ? a : b);

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxValue * 1.2,
        barTouchData: BarTouchData(enabled: false),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() < sortedMonths.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      sortedMonths[value.toInt()],
                      style: const TextStyle(fontSize: 10),
                    ),
                  );
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                return Text(
                  'PKR ${value.toInt()}',
                  style: const TextStyle(fontSize: 10),
                );
              },
            ),
          ),
        ),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        barGroups: sortedMonths.asMap().entries.map((entry) {
          final index = entry.key;
          final month = entry.value;
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: monthlyData[month] ?? 0,
                color: Colors.blue,
                width: 20,
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

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

  Future<void> _showFilterDialog() async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Reports'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Start Date'),
              subtitle: Text(DateFormat('yyyy-MM-dd').format(_startDate)),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _startDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (date != null) {
                  setState(() {
                    _startDate = date;
                  });
                }
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('End Date'),
              subtitle: Text(DateFormat('yyyy-MM-dd').format(_endDate)),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _endDate,
                  firstDate: _startDate,
                  lastDate: DateTime.now(),
                );
                if (date != null) {
                  setState(() {
                    _endDate = date;
                  });
                }
                Navigator.pop(context);
              },
            ),
            DropdownButtonFormField<InvoiceStatus?>(
              decoration: const InputDecoration(
                labelText: 'Status Filter',
                border: OutlineInputBorder(),
              ),
              value: _selectedStatus,
              items: [
                const DropdownMenuItem<InvoiceStatus?>(
                  value: null,
                  child: Text('All Statuses'),
                ),
                ...InvoiceStatus.values.map((status) {
                  return DropdownMenuItem(
                    value: status,
                    child: Text(status.displayName),
                  );
                }),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedStatus = value;
                });
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: color.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: color),
                Text(title, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
