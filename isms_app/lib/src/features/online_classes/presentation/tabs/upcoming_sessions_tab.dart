import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/online_class_providers.dart';
import '../../domain/online_class.dart';
import '../../domain/online_class_platform.dart';
import '../../domain/online_class_session.dart';

class UpcomingSessionsTab extends ConsumerWidget {
  const UpcomingSessionsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final upcomingSessionsAsync = ref.watch(upcomingSessionsProvider);

    return upcomingSessionsAsync.when(
      data: (sessions) {
        if (sessions.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.access_time, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No upcoming sessions',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
                SizedBox(height: 8),
                Text(
                  'Scheduled sessions will appear here',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: sessions.length,
          itemBuilder: (context, index) {
            final session = sessions[index];
            return _SessionCard(session: session);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) =>
          Center(child: Text('Error loading upcoming sessions: \$error')),
    );
  }
}

class _SessionCard extends StatelessWidget {
  final OnlineClassSession session;

  const _SessionCard({required this.session});

  @override
  Widget build(BuildContext context) {
    final timeUntil = session.scheduledStart.difference(DateTime.now());
    final hoursUntil = timeUntil.inHours;
    final minutesUntil = timeUntil.inMinutes % 60;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    session.onlineClass.title,
                    style: Theme.of(context).textTheme.titleLarge,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Chip(
                  label: Text(
                    _getTimeUntilText(timeUntil),
                    style: const TextStyle(fontSize: 12, color: Colors.white),
                  ),
                  backgroundColor: _getTimeUntilColor(timeUntil),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              session.onlineClass.description,
              style: Theme.of(context).textTheme.bodyMedium,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  'Starts: \${_formatDate(session.scheduledStart)}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(width: 16),
                const Icon(Icons.access_time, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  'Ends: \${_formatDate(session.scheduledEnd)}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.people, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  'Expected: \${session.expectedParticipants} participants',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const Spacer(),
                const Icon(Icons.videocam, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  session.onlineClass.platform.displayName,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: () {
                    // View class details
                    _showClassDetails(context, session.onlineClass);
                  },
                  child: const Text('Class Details'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    // Join session
                    _joinSession(context, session);
                  },
                  child: const Text('Join Session'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '\\${date.day}/\\${date.month}/\\${date.year} \\${date.hour}:\\${date.minute.toString().padLeft(2, '0')}';
  }

  String _getTimeUntilText(Duration timeUntil) {
    if (timeUntil.isNegative) {
      return 'Started';
    } else if (timeUntil.inHours > 24) {
      return '\\${timeUntil.inDays}d';
    } else if (timeUntil.inHours > 1) {
      return '\\${timeUntil.inHours}h';
    } else if (timeUntil.inMinutes > 1) {
      return '\\${timeUntil.inMinutes}m';
    } else {
      return 'Now';
    }
  }

  Color _getTimeUntilColor(Duration timeUntil) {
    if (timeUntil.isNegative) {
      return Colors.green;
    } else if (timeUntil.inMinutes < 15) {
      return Colors.orange;
    } else if (timeUntil.inHours < 1) {
      return Colors.blue;
    } else {
      return Colors.grey;
    }
  }

  void _showClassDetails(BuildContext context, OnlineClass onlineClass) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(onlineClass.title),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Description: \\${onlineClass.description}'),
              const SizedBox(height: 12),
              Text('Platform: \\${onlineClass.platform.displayName}'),
              Text('Meeting URL: \\${onlineClass.meetingUrl}'),
              Text('Duration: \\${onlineClass.duration.inMinutes} minutes'),
            ],
          ),
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

  void _joinSession(BuildContext context, OnlineClassSession session) {
    // TODO: Implement join session functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Joining \\${session.onlineClass.title}...'),
        action: SnackBarAction(
          label: 'Open',
          onPressed: () {
            // Open meeting URL
          },
        ),
      ),
    );
  }
}
