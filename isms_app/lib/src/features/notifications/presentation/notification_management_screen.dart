import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../authentication/application/auth_providers.dart';
import '../application/notification_providers.dart';
import '../domain/notification.dart' as notification_domain;
import 'send_notification_dialog.dart';
import 'notification_preferences_screen.dart';

class NotificationManagementScreen extends ConsumerStatefulWidget {
  const NotificationManagementScreen({super.key});

  @override
  ConsumerState<NotificationManagementScreen> createState() =>
      _NotificationManagementScreenState();
}

class _NotificationManagementScreenState
    extends ConsumerState<NotificationManagementScreen> {
  notification_domain.NotificationType? _filterType;
  notification_domain.NotificationStatus? _filterStatus;

  @override
  Widget build(BuildContext context) {
    final authUserAsync = ref.watch(currentUserProvider);
    final notificationsAsync = ref.watch(
      userNotificationsProvider((
        userId: null, // Get all for school
        type: _filterType,
        limit: 100,
      )),
    );
    final statsAsync = ref.watch(notificationStatsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: () => _showSendNotificationDialog(context),
            tooltip: 'Send Notification',
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              authUserAsync.whenData((authUser) {
                if (authUser != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          NotificationPreferencesScreen(userId: authUser.id),
                    ),
                  );
                }
              });
            },
            tooltip: 'Notification Preferences',
          ),
        ],
      ),
      body: Column(
        children: [
          // Statistics Cards
          statsAsync.when(
            data: (stats) => Container(
              padding: const EdgeInsets.all(16),
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      label: 'Total',
                      value: '${stats['total'] ?? 0}',
                      icon: Icons.notifications,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      label: 'Email Sent',
                      value: '${stats['email_sent'] ?? 0}',
                      icon: Icons.email,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      label: 'SMS Sent',
                      value: '${stats['sms_sent'] ?? 0}',
                      icon: Icons.sms,
                      color: Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      label: 'Failed',
                      value:
                          '${(stats['email_failed'] ?? 0) + (stats['sms_failed'] ?? 0)}',
                      icon: Icons.error_outline,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
            ),
            loading: () => const SizedBox(
              height: 100,
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (_, __) => const SizedBox.shrink(),
          ),
          // Filters
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child:
                      DropdownButtonFormField<
                        notification_domain.NotificationType?
                      >(
                        initialValue: _filterType,
                        decoration: const InputDecoration(
                          labelText: 'Type',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        items: [
                          const DropdownMenuItem(
                            value: null,
                            child: Text('All Types'),
                          ),
                          const DropdownMenuItem(
                            value: notification_domain.NotificationType.email,
                            child: Text('Email'),
                          ),
                          const DropdownMenuItem(
                            value: notification_domain.NotificationType.sms,
                            child: Text('SMS'),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _filterType = value;
                          });
                        },
                      ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child:
                      DropdownButtonFormField<
                        notification_domain.NotificationStatus?
                      >(
                        initialValue: _filterStatus,
                        decoration: const InputDecoration(
                          labelText: 'Status',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        items: [
                          const DropdownMenuItem(
                            value: null,
                            child: Text('All Status'),
                          ),
                          const DropdownMenuItem(
                            value:
                                notification_domain.NotificationStatus.pending,
                            child: Text('Pending'),
                          ),
                          const DropdownMenuItem(
                            value: notification_domain.NotificationStatus.sent,
                            child: Text('Sent'),
                          ),
                          const DropdownMenuItem(
                            value:
                                notification_domain.NotificationStatus.failed,
                            child: Text('Failed'),
                          ),
                          const DropdownMenuItem(
                            value: notification_domain
                                .NotificationStatus
                                .delivered,
                            child: Text('Delivered'),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _filterStatus = value;
                          });
                        },
                      ),
                ),
              ],
            ),
          ),
          // Notifications List
          Expanded(
            child: notificationsAsync.when(
              data: (notifications) {
                final filtered = notifications.where((n) {
                  if (_filterStatus != null && n.status != _filterStatus) {
                    return false;
                  }
                  return true;
                }).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.notifications_none,
                          size: 64,
                          color: Theme.of(context).colorScheme.outline,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No notifications',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final notification = filtered[index];
                    return _NotificationCard(notification: notification);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Error loading notifications',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '$e',
                        style: Theme.of(context).textTheme.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSendNotificationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => const SendNotificationDialog(),
    ).then((_) {
      ref.invalidate(
        userNotificationsProvider((userId: null, type: null, limit: 100)),
      );
      ref.invalidate(notificationStatsProvider);
    });
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({required this.notification});

  final notification_domain.Notification notification;

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(context, notification.status);
    final typeIcon = _getTypeIcon(notification.type);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        leading: Icon(typeIcon, color: statusColor),
        title: Text(
          notification.recipient,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        subtitle: Text(
          notification.subject ?? notification.body,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Chip(
          label: Text(notification.status.name.toUpperCase()),
          backgroundColor: statusColor.withOpacity(0.2),
          labelStyle: TextStyle(
            color: statusColor,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _InfoRow(
                  label: 'Type',
                  value: notification.type.name.toUpperCase(),
                ),
                _InfoRow(
                  label: 'Status',
                  value: notification.status.name.toUpperCase(),
                ),
                if (notification.subject != null)
                  _InfoRow(label: 'Subject', value: notification.subject!),
                _InfoRow(label: 'Recipient', value: notification.recipient),
                const SizedBox(height: 8),
                Text('Message:', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    notification.body,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                if (notification.sentAt != null) ...[
                  const SizedBox(height: 8),
                  _InfoRow(
                    label: 'Sent At',
                    value: DateFormat(
                      'MMM dd, yyyy HH:mm',
                    ).format(notification.sentAt!),
                  ),
                ],
                if (notification.errorMessage != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: Theme.of(context).colorScheme.onErrorContainer,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            notification.errorMessage!,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onErrorContainer,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(
    BuildContext context,
    notification_domain.NotificationStatus status,
  ) {
    switch (status) {
      case notification_domain.NotificationStatus.pending:
        return Colors.orange;
      case notification_domain.NotificationStatus.sent:
        return Colors.blue;
      case notification_domain.NotificationStatus.failed:
        return Theme.of(context).colorScheme.error;
      case notification_domain.NotificationStatus.delivered:
        return Colors.green;
    }
  }

  IconData _getTypeIcon(notification_domain.NotificationType type) {
    switch (type) {
      case notification_domain.NotificationType.email:
        return Icons.email;
      case notification_domain.NotificationType.sms:
        return Icons.sms;
      case notification_domain.NotificationType.push:
        return Icons.notifications;
      case notification_domain.NotificationType.inApp:
        return Icons.message;
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
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500),
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
