import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../application/online_class_providers.dart';
import '../../domain/online_class.dart';
import '../../domain/online_class_platform.dart';

class OnlineClassesTab extends ConsumerWidget {
  const OnlineClassesTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onlineClassesAsync = ref.watch(onlineClassesProvider);

    return onlineClassesAsync.when(
      data: (classes) {
        if (classes.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.video_library_outlined,
                  size: 64,
                  color: Colors.grey,
                ),
                SizedBox(height: 16),
                Text(
                  'No online classes yet',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
                SizedBox(height: 8),
                Text(
                  'Create your first online class to get started',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: classes.length,
          itemBuilder: (context, index) {
            final onlineClass = classes[index];
            return _OnlineClassCard(onlineClass: onlineClass);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) =>
          Center(child: Text('Error loading online classes: \$error')),
    );
  }
}

class _OnlineClassCard extends StatelessWidget {
  final OnlineClass onlineClass;

  const _OnlineClassCard({required this.onlineClass});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _PlatformIcon(platform: onlineClass.platform),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    onlineClass.title,
                    style: Theme.of(context).textTheme.titleLarge,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Chip(
                  label: Text(
                    onlineClass.isActive ? 'Active' : 'Inactive',
                    style: TextStyle(
                      color: onlineClass.isActive
                          ? Colors.white
                          : Colors.grey[700],
                      fontSize: 12,
                    ),
                  ),
                  backgroundColor: onlineClass.isActive
                      ? Theme.of(context).colorScheme.primary
                      : Colors.grey[300],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              onlineClass.description,
              style: Theme.of(context).textTheme.bodyMedium,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  'Starts: \${_formatDate(onlineClass.scheduledStart)}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(width: 16),
                const Icon(Icons.access_time, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  'Duration: \${onlineClass.duration.inMinutes} min',
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
                  'Participants: \${onlineClass.expectedParticipants}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const Spacer(),
                if (onlineClass.recordSession)
                  const Chip(
                    label: Text('Recording', style: TextStyle(fontSize: 10)),
                    backgroundColor: Colors.green,
                    labelStyle: TextStyle(color: Colors.white),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: () {
                    // View details
                    _showClassDetails(context, onlineClass);
                  },
                  child: const Text('View Details'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    // Join/Start session
                    _joinClass(context, onlineClass);
                  },
                  child: const Text('Join Class'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '\\${date.day}/\\${date.month}/\\${date.year} at \\${date.hour}:\\${date.minute.toString().padLeft(2, '0')}';
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
              Text('Password: \\${onlineClass.meetingPassword}'),
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

  Future<void> _joinClass(BuildContext context, OnlineClass onlineClass) async {
    // Determine the URL to open
    String? urlToOpen;

    if (onlineClass.customMeetingUrl != null &&
        onlineClass.customMeetingUrl!.isNotEmpty) {
      urlToOpen = onlineClass.customMeetingUrl!;
    } else if (onlineClass.meetingUrl.isNotEmpty) {
      urlToOpen = onlineClass.meetingUrl;
    } else {
      // No URL available
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Meeting URL is not available. Please contact the class organizer.',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // Validate URL format
    final uri = Uri.tryParse(urlToOpen);
    if (uri == null || (!uri.hasScheme)) {
      // Try to add https:// if no scheme
      if (!urlToOpen.startsWith('http://') &&
          !urlToOpen.startsWith('https://')) {
        urlToOpen = 'https://$urlToOpen';
      }
    }

    // Launch the URL
    try {
      final finalUri = Uri.parse(urlToOpen);
      final launched = await launchUrl(
        finalUri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched) {
        throw Exception('Could not launch URL');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to open meeting: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

class _PlatformIcon extends StatelessWidget {
  final OnlineClassPlatform platform;

  const _PlatformIcon({required this.platform});

  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color color;

    switch (platform) {
      case OnlineClassPlatform.zoom:
        icon = Icons.videocam;
        color = Colors.blue;
        break;
      case OnlineClassPlatform.googleMeet:
        icon = Icons.video_call;
        color = Colors.green;
        break;
      case OnlineClassPlatform.custom:
        icon = Icons.video_label;
        color = Colors.orange;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, size: 24, color: color),
    );
  }
}
