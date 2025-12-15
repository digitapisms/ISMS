import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/online_class_providers.dart';
import '../../domain/online_class_session.dart';

class SessionHistoryTab extends ConsumerWidget {
  const SessionHistoryTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // For now, we'll use upcoming sessions provider as a placeholder
    // In a real implementation, we'd have a separate provider for completed sessions
    final sessionsAsync = ref.watch(upcomingSessionsProvider);

    return sessionsAsync.when(
      data: (sessions) {
        // Filter completed sessions (placeholder logic)
        final completedSessions = sessions.where((session) => session.isCompleted).toList();

        if (completedSessions.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No session history',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
                SizedBox(height: 8),
                Text(
                  'Completed sessions will appear here',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: completedSessions.length,
          itemBuilder: (context, index) {
            final session = completedSessions[index];
            return _SessionHistoryCard(session: session);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Text('Error loading session history: \$error'),
      ),
    );
  }
}

class _SessionHistoryCard extends StatelessWidget {
  final OnlineClassSession session;

  const _SessionHistoryCard({required this.session});

  @override
  Widget build(BuildContext context) {
    final attendanceRate = session.actualParticipants > 0 && session.expectedParticipants > 0
        ? (session.actualParticipants / session.expectedParticipants * 100).toStringAsFixed(1)
        : '0.0';

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
                    session.status.displayName,
                    style: const TextStyle(fontSize: 12, color: Colors.white),
                  ),
                  backgroundColor: _getStatusColor(session.status),
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
                  'Date: \${_formatDate(session.scheduledStart)}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(width: 16),
                const Icon(Icons.access_time, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  'Duration: \${session.duration.inMinutes} min',
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
                  'Attendance: \${session.actualParticipants}/\\${session.expectedParticipants} (\\$attendanceRate%)',
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
            if (session.recordingUrl != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.video_library, size: 16, color: Colors.green),
                  const SizedBox(width: 8),
                  Text(
                    'Recording available',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.green[700],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (session.recordingUrl != null)
                  OutlinedButton(
                    onPressed: () {
                      // View recording
                      _viewRecording(context, session.recordingUrl!);
                    },
                    child: const Text('View Recording'),
                  ),
                if (session.recordingUrl != null) const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    // View session details
                    _viewSessionDetails(context, session);
                  },
                  child: const Text('View Details'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '\\${date.day}/\\${date.month}/\\${date.year}';
  }

  Color _getStatusColor(SessionStatus status) {
    switch (status) {
      case SessionStatus.completed:
        return Colors.green;
      case SessionStatus.ended:
        return Colors.blue;
      case SessionStatus.cancelled:
        return Colors.red;
      case SessionStatus.scheduled:
        return Colors.orange;
      case SessionStatus.inProgress:
        return Colors.purple;
    }
  }

  void _viewRecording(BuildContext context, String recordingUrl) {
    // TODO: Implement recording view functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Opening recording...'),
        action: SnackBarAction(
          label: 'Open',
          onPressed: () {
            // Open recording URL
          },
        ),
      ),
    );
  }

  void _viewSessionDetails(BuildContext context, OnlineClassSession session) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Session Details - \\${session.onlineClass.title}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Status: \\${session.status.displayName}'),
              const SizedBox(height: 8),
              if (session.actualStart != null)
                Text('Started: \\${_formatDateTime(session.actualStart!)}'),
              if (session.actualEnd != null)
                Text('Ended: \\${_formatDateTime(session.actualEnd!)}'),
              const SizedBox(height: 8),
              Text('Duration: \\${session.duration.inMinutes} minutes'),
              Text('Participants: \\${session.actualParticipants}/\\${session.expectedParticipants}'),
              const SizedBox(height: 8),
              if (session.recordingUrl != null)
                Text('Recording: \\${session.recordingUrl}'),
              if (session.moderatorNotes != null)
                Text('Notes: \\${session.moderatorNotes}'),
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

  String _formatDateTime(DateTime dateTime) {
    return '\\${dateTime.day}/\\${dateTime.month}/\\${dateTime.year} \\${dateTime.hour}:\\${dateTime.minute.toString().padLeft(2, '0')}';
  }
}