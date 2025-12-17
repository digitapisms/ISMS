import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/student_providers.dart';

class AdminApplicationReviewScreen extends ConsumerWidget {
  const AdminApplicationReviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final applicationsAsync = ref.watch(pendingApplicationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pending Applications'),
        actions: [
          // Bulk review action
          applicationsAsync.when(
            data: (apps) {
              if (apps.isEmpty) return const SizedBox.shrink();
              return PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                onSelected: (action) {
                  _handleBulkAction(context, ref, apps, action);
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'approve_all',
                    child: ListTile(
                      leading: Icon(Icons.check_circle, color: Colors.green),
                      title: Text('Approve All'),
                      dense: true,
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'reject_all',
                    child: ListTile(
                      leading: Icon(Icons.cancel, color: Colors.red),
                      title: Text('Reject All'),
                      dense: true,
                    ),
                  ),
                ],
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
      body: applicationsAsync.when(
        data: (applications) {
          if (applications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 64,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No pending applications',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: applications.length,
            itemBuilder: (context, index) {
              final app = applications[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(child: Text(_getInitials(app))),
                  title: Text(_getApplicantName(app)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Email: ${_getEmail(app)}'),
                      Text('Class: ${_getClassName(app)}'),
                      Text('Status: ${app['status']}'),
                      Text('Submitted: ${_formatDate(app['submitted_at'])}'),
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.visibility),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ApplicationDetailScreen(
                            applicationId: app['id'] as String,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
    );
  }

  String _getInitials(Map<String, dynamic> app) {
    final name = _getApplicantName(app);
    if (name.isEmpty) return '?';
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }

  String _getApplicantName(Map<String, dynamic> app) {
    try {
      final users = app['users'] as Map<String, dynamic>?;
      if (users == null) return 'Unknown';
      final profiles = users['user_profiles'] as Map<String, dynamic>?;
      return profiles?['full_name'] as String? ?? 'Unknown';
    } catch (e) {
      return 'Unknown';
    }
  }

  String _getEmail(Map<String, dynamic> app) {
    try {
      final users = app['users'] as Map<String, dynamic>?;
      return users?['email'] as String? ?? 'N/A';
    } catch (e) {
      return 'N/A';
    }
  }

  String _getClassName(Map<String, dynamic> app) {
    try {
      final classes = app['classes'] as Map<String, dynamic>?;
      return classes?['name'] as String? ?? 'Not specified';
    } catch (e) {
      return 'Not specified';
    }
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'N/A';
    try {
      final d = DateTime.parse(date.toString());
      return '${d.day}/${d.month}/${d.year}';
    } catch (e) {
      return date.toString();
    }
  }

  Future<void> _handleBulkAction(
    BuildContext context,
    WidgetRef ref,
    List<Map<String, dynamic>> applications,
    String action,
  ) async {
    final status = action == 'approve_all' ? 'approved' : 'rejected';
    final actionName = action == 'approve_all' ? 'approve' : 'reject';

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('$actionName All Applications'),
        content: Text(
          'Are you sure you want to $actionName all ${applications.length} pending applications? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: action == 'approve_all'
                ? null
                : FilledButton.styleFrom(backgroundColor: Colors.red),
            child: Text(actionName.toUpperCase()),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Show progress dialog
    final progressDialog = showDialog(
      context: context,
      barrierDismissible: false,
      builder: (progressContext) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text('Processing ${applications.length} applications...'),
          ],
        ),
      ),
    );

    try {
      final repo = ref.read(studentRepositoryProvider);
      final applicationIds = applications
          .map((app) => app['id'] as String)
          .toList();

      final result = await repo.bulkUpdateApplicationStatuses(
        applicationIds: applicationIds,
        status: status,
        remarks: 'Bulk $actionName action',
      );

      // Close progress dialog
      Navigator.of(context, rootNavigator: true).pop();

      if (!context.mounted) return;

      // Refresh data
      ref.invalidate(pendingApplicationsProvider);

      // Show results
      showDialog(
        context: context,
        builder: (resultContext) => AlertDialog(
          title: Text('Bulk $actionName Complete'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Total: ${result['total']}'),
              Text(
                '✓ Successful: ${result['success_count']}',
                style: const TextStyle(color: Colors.green),
              ),
              if (result['fail_count'] > 0)
                Text(
                  '✗ Failed: ${result['fail_count']}',
                  style: const TextStyle(color: Colors.red),
                ),
              if (result['errors'] != null &&
                  (result['errors'] as Map).isNotEmpty) ...[
                const SizedBox(height: 8),
                const Text('Errors:', style: TextStyle(fontWeight: FontWeight.bold)),
                ...(result['errors'] as Map<String, String>).entries.map(
                  (e) => Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '${e.key.substring(0, 8)}...: ${e.value}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ),
              ],
            ],
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(resultContext),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      // Close progress dialog
      Navigator.of(context, rootNavigator: true).pop();
      
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Bulk action failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

class ApplicationDetailScreen extends ConsumerStatefulWidget {
  const ApplicationDetailScreen({super.key, required this.applicationId});

  final String applicationId;

  @override
  ConsumerState<ApplicationDetailScreen> createState() =>
      _ApplicationDetailScreenState();
}

class _ApplicationDetailScreenState
    extends ConsumerState<ApplicationDetailScreen> {
  final _remarksController = TextEditingController();
  bool _isProcessing = false;

  @override
  void dispose() {
    _remarksController.dispose();
    super.dispose();
  }

  Future<void> _updateStatus(String status) async {
    setState(() {
      _isProcessing = true;
    });

    try {
      final repo = ref.read(studentRepositoryProvider);
      await repo.updateApplicationStatus(
        applicationId: widget.applicationId,
        status: status,
        remarks: _remarksController.text.trim().isEmpty
            ? null
            : _remarksController.text.trim(),
      );

      if (!mounted) return;
      ref.invalidate(pendingApplicationsProvider);
      ref.invalidate(applicationDetailProvider(widget.applicationId));
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Application $status successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final appAsync = ref.watch(applicationDetailProvider(widget.applicationId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Application Details'),
        actions: [
          if (_isProcessing)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
        ],
      ),
      body: appAsync.when(
        data: (app) {
          if (app == null) {
            return const Center(child: Text('Application not found'));
          }

          final studentDetails =
              app['student_details'] as Map<String, dynamic>?;
          final family = app['family_members'] as List<dynamic>? ?? [];
          final emergency = app['emergency_contacts'] as List<dynamic>? ?? [];
          final users = app['users'] as Map<String, dynamic>?;
          final profiles = users?['user_profiles'] as Map<String, dynamic>?;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Applicant Information',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 16),
                        _InfoRow('Name', profiles?['full_name'] ?? 'N/A'),
                        _InfoRow('Email', users?['email'] ?? 'N/A'),
                        if (studentDetails != null) ...[
                          _InfoRow(
                            'Date of Birth',
                            studentDetails['dob'] ?? 'N/A',
                          ),
                          _InfoRow('Gender', studentDetails['gender'] ?? 'N/A'),
                          _InfoRow(
                            'Blood Group',
                            studentDetails['blood_group'] ?? 'N/A',
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                if (family.isNotEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Family Members',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          ...family.map(
                            (f) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Text(
                                '${f['relation']}: ${f['name']} - ${f['contact'] ?? 'N/A'}',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                if (emergency.isNotEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Emergency Contact',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          ...emergency.map(
                            (e) => Text('${e['name']}: ${e['phone']}'),
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Review Remarks',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _remarksController,
                          decoration: const InputDecoration(
                            hintText: 'Add remarks (optional)',
                            border: OutlineInputBorder(),
                          ),
                          maxLines: 3,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.close),
                        label: const Text('Reject'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                        onPressed: _isProcessing
                            ? null
                            : () {
                                showDialog(
                                  context: context,
                                  builder: (dialogContext) => AlertDialog(
                                    title: const Text('Reject Application'),
                                    content: const Text(
                                      'Are you sure you want to reject this application?',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(dialogContext),
                                        child: const Text('Cancel'),
                                      ),
                                      FilledButton(
                                        onPressed: () {
                                          Navigator.pop(dialogContext);
                                          _updateStatus('rejected');
                                        },
                                        style: FilledButton.styleFrom(
                                          backgroundColor: Colors.red,
                                        ),
                                        child: const Text('Reject'),
                                      ),
                                    ],
                                  ),
                                );
                              },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: FilledButton.icon(
                        icon: const Icon(Icons.check),
                        label: const Text('Approve'),
                        onPressed: _isProcessing
                            ? null
                            : () {
                                showDialog(
                                  context: context,
                                  builder: (dialogContext) => AlertDialog(
                                    title: const Text('Approve Application'),
                                    content: const Text(
                                      'Are you sure you want to approve this application? The student will be activated.',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(dialogContext),
                                        child: const Text('Cancel'),
                                      ),
                                      FilledButton(
                                        onPressed: () {
                                          Navigator.pop(dialogContext);
                                          _updateStatus('approved');
                                        },
                                        child: const Text('Approve'),
                                      ),
                                    ],
                                  ),
                                );
                              },
                      ),
                    ),
                  ],
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
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
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
