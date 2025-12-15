import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/library_providers.dart';
import '../../domain/book_fine.dart';
import '../../domain/book_type.dart';
import '../dialogs/pay_fine_dialog.dart';
import '../dialogs/waive_fine_dialog.dart';

class FinesTab extends ConsumerStatefulWidget {
  const FinesTab({super.key});

  @override
  ConsumerState<FinesTab> createState() => _FinesTabState();
}

class _FinesTabState extends ConsumerState<FinesTab> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        DefaultTabBar(
          tabs: const [
            Tab(text: 'All Fines'),
            Tab(text: 'Pending'),
            Tab(text: 'Paid'),
            Tab(text: 'Waived'),
          ],
          onTap: (index) => setState(() => _selectedIndex = index),
        ),
        Expanded(
          child: _buildContent(),
        ),
      ],
    );
  }

  Widget _buildContent() {
    switch (_selectedIndex) {
      case 0:
        return _buildFinesList();
      case 1:
        return _buildPendingFines();
      case 2:
        return _buildPaidFines();
      case 3:
        return _buildWaivedFines();
      default:
        return _buildFinesList();
    }
  }

  Widget _buildFinesList() {
    final finesAsync = ref.watch(bookFinesProvider);

    return finesAsync.when(
      data: (fines) => _buildFinesListView(fines),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => _buildErrorState(error),
    );
  }

  Widget _buildPendingFines() {
    final finesAsync = ref.watch(pendingFinesProvider);

    return finesAsync.when(
      data: (fines) => _buildFinesListView(fines),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => _buildErrorState(error),
    );
  }

  Widget _buildPaidFines() {
    final finesAsync = ref.watch(bookFinesProvider);

    return finesAsync.when(
      data: (fines) {
        final paid = fines.where((f) => f.status == FineStatus.paid).toList();
        return _buildFinesListView(paid);
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => _buildErrorState(error),
    );
  }

  Widget _buildWaivedFines() {
    final finesAsync = ref.watch(bookFinesProvider);

    return finesAsync.when(
      data: (fines) {
        final waived = fines.where((f) => f.status == FineStatus.waived).toList();
        return _buildFinesListView(waived);
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => _buildErrorState(error),
    );
  }

  Widget _buildFinesListView(List<BookFine> fines) {
    if (fines.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.money_off, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No fines found',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: fines.length,
      itemBuilder: (context, index) {
        final fine = fines[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            title: Text('Fine: ${fine.amount.toStringAsFixed(2)}'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Type: ${fine.fineType.displayName}'),
                if (fine.daysOverdue > 0)
                  Text('Days Overdue: ${fine.daysOverdue}'),
                if (fine.description != null) Text(fine.description!),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Chip(
                  label: Text(fine.status.dbValue.toUpperCase()),
                  backgroundColor: _getStatusColor(fine.status).withOpacity(0.2),
                  labelStyle: TextStyle(
                    color: _getStatusColor(fine.status),
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
                if (fine.status == FineStatus.pending) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.payment),
                    color: Colors.green,
                    onPressed: () async {
                      final result = await showDialog<bool>(
                        context: context,
                        builder: (context) => PayFineDialog(fine: fine),
                      );
                      if (result == true) {
                        ref.invalidate(bookFinesProvider);
                        ref.invalidate(pendingFinesProvider);
                      }
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.cancel),
                    color: Colors.orange,
                    onPressed: () async {
                      final result = await showDialog<bool>(
                        context: context,
                        builder: (context) => WaiveFineDialog(fine: fine),
                      );
                      if (result == true) {
                        ref.invalidate(bookFinesProvider);
                        ref.invalidate(pendingFinesProvider);
                      }
                    },
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildErrorState(Object error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
          const SizedBox(height: 16),
          Text(
            'Error loading fines',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            error.toString(),
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(FineStatus status) {
    switch (status) {
      case FineStatus.pending:
        return Colors.orange;
      case FineStatus.paid:
        return Colors.green;
      case FineStatus.waived:
        return Colors.blue;
      case FineStatus.cancelled:
        return Colors.grey;
    }
  }
}

class DefaultTabBar extends StatelessWidget {
  const DefaultTabBar({
    super.key,
    required this.tabs,
    required this.onTap,
  });

  final List<Tab> tabs;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: Row(
        children: tabs.asMap().entries.map((entry) {
          final index = entry.key;
          final tab = entry.value;
          return Expanded(
            child: InkWell(
              onTap: () => onTap(index),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: Theme.of(context).colorScheme.primary,
                      width: 2,
                    ),
                  ),
                ),
                child: Center(child: tab.child),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

