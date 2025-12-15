import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../authentication/application/auth_providers.dart';
import '../../../authentication/domain/user_role.dart';
import '../../application/library_providers.dart';
import '../../domain/book_type.dart';
import '../dialogs/issue_book_dialog.dart';
import '../dialogs/return_book_dialog.dart';
import '../widgets/issue_list_item.dart';

class IssuesReturnsTab extends ConsumerStatefulWidget {
  const IssuesReturnsTab({super.key});

  @override
  ConsumerState<IssuesReturnsTab> createState() => _IssuesReturnsTabState();
}

class _IssuesReturnsTabState extends ConsumerState<IssuesReturnsTab> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final authUser = ref.watch(authStateProvider);
    final isAdmin = authUser?.role == UserRole.admin ||
        authUser?.role == UserRole.principal;
    final isTeacher = authUser?.role == UserRole.teacher;
    final canIssue = isAdmin || isTeacher;

    return Column(
      children: [
        if (canIssue)
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton.icon(
              onPressed: () async {
                final result = await showDialog<bool>(
                  context: context,
                  builder: (context) => const IssueBookDialog(),
                );
                if (result == true) {
                  ref.invalidate(bookIssuesProvider);
                }
              },
              icon: const Icon(Icons.add),
              label: const Text('Issue Book'),
            ),
          ),
        DefaultTabBar(
          tabs: const [
            Tab(text: 'All Issues'),
            Tab(text: 'Active'),
            Tab(text: 'Overdue'),
            Tab(text: 'Returned'),
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
        return _buildIssuesList();
      case 1:
        return _buildActiveIssues();
      case 2:
        return _buildOverdueIssues();
      case 3:
        return _buildReturnedIssues();
      default:
        return _buildIssuesList();
    }
  }

  Widget _buildIssuesList() {
    final issuesAsync = ref.watch(bookIssuesProvider);

    return issuesAsync.when(
      data: (issues) {
        if (issues.isEmpty) {
          return _buildEmptyState('No book issues found');
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: issues.length,
          itemBuilder: (context, index) {
            final issue = issues[index];
            return IssueListItem(
              issue: issue,
              onReturn: issue.status == IssueStatus.issued
                  ? () async {
                      final result = await showDialog<bool>(
                        context: context,
                        builder: (context) => ReturnBookDialog(issue: issue),
                      );
                      if (result == true) {
                        ref.invalidate(bookIssuesProvider);
                        ref.invalidate(bookReturnsProvider);
                      }
                    }
                  : null,
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => _buildErrorState(error),
    );
  }

  Widget _buildActiveIssues() {
    final issuesAsync = ref.watch(bookIssuesProvider);

    return issuesAsync.when(
      data: (issues) {
        final active = issues
            .where((i) => i.status == IssueStatus.issued)
            .toList();
        if (active.isEmpty) {
          return _buildEmptyState('No active issues');
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: active.length,
          itemBuilder: (context, index) {
            final issue = active[index];
            return IssueListItem(
              issue: issue,
              onReturn: () async {
                final result = await showDialog<bool>(
                  context: context,
                  builder: (context) => ReturnBookDialog(issue: issue),
                );
                if (result == true) {
                  ref.invalidate(bookIssuesProvider);
                  ref.invalidate(bookReturnsProvider);
                }
              },
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => _buildErrorState(error),
    );
  }

  Widget _buildOverdueIssues() {
    final issuesAsync = ref.watch(overdueIssuesProvider);

    return issuesAsync.when(
      data: (issues) {
        if (issues.isEmpty) {
          return _buildEmptyState('No overdue books');
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: issues.length,
          itemBuilder: (context, index) {
            final issue = issues[index];
            return IssueListItem(
              issue: issue,
              onReturn: () async {
                final result = await showDialog<bool>(
                  context: context,
                  builder: (context) => ReturnBookDialog(issue: issue),
                );
                if (result == true) {
                  ref.invalidate(bookIssuesProvider);
                  ref.invalidate(overdueIssuesProvider);
                  ref.invalidate(bookReturnsProvider);
                }
              },
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => _buildErrorState(error),
    );
  }

  Widget _buildReturnedIssues() {
    final returnsAsync = ref.watch(bookReturnsProvider);

    return returnsAsync.when(
      data: (returns) {
        if (returns.isEmpty) {
          return _buildEmptyState('No returned books');
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: returns.length,
          itemBuilder: (context, index) {
            final returnRecord = returns[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                title: Text('Returned on ${_formatDate(returnRecord.returnDate)}'),
                subtitle: Text(
                  'Days overdue: ${returnRecord.daysOverdue}\n'
                  'Fine: ${returnRecord.fineAmount.toStringAsFixed(2)}',
                ),
                trailing: returnRecord.finePaid
                    ? const Chip(
                        label: Text('Paid'),
                        backgroundColor: Colors.green,
                      )
                    : const Chip(
                        label: Text('Unpaid'),
                        backgroundColor: Colors.orange,
                      ),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => _buildErrorState(error),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.book_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            message,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
        ],
      ),
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
            'Error loading issues',
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

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
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

