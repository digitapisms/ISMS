import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/circular.dart';
import '../../domain/messaging_type.dart';

class CircularListItem extends StatelessWidget {
  final Circular circular;

  const CircularListItem({
    super.key,
    required this.circular,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: ListTile(
        leading: CircleAvatar(
          child: Text(
            circular.circularNumber.split('/').last,
            style: const TextStyle(fontSize: 10),
          ),
        ),
        title: Text(
          circular.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              circular.content,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Chip(
              label: Text(circular.circularType.displayName),
              labelStyle: const TextStyle(fontSize: 10),
              padding: const EdgeInsets.symmetric(horizontal: 4),
            ),
          ],
        ),
        trailing: Text(
          DateFormat('MMM d, y').format(circular.issuedDate),
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
        onTap: () {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Circular ${circular.circularNumber}'),
                  const SizedBox(height: 4),
                  Text(
                    circular.title,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Text(circular.content),
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

