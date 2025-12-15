import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/announcement.dart';
import '../../domain/messaging_type.dart';

class AnnouncementListItem extends StatelessWidget {
  final Announcement announcement;

  const AnnouncementListItem({
    super.key,
    required this.announcement,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: ListTile(
        title: Text(
          announcement.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              announcement.content,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Chip(
                  label: Text(announcement.priority.displayName),
                  labelStyle: const TextStyle(fontSize: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                ),
                const SizedBox(width: 4),
                Chip(
                  label: Text(announcement.announcementType.displayName),
                  labelStyle: const TextStyle(fontSize: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                ),
              ],
            ),
          ],
        ),
        trailing: announcement.publishedAt != null
            ? Text(
                DateFormat('MMM d, y').format(announcement.publishedAt!),
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              )
            : null,
        onTap: () {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text(announcement.title),
              content: SingleChildScrollView(
                child: Text(announcement.content),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

