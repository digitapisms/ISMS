import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/visit.dart';
import '../../domain/visitor_type.dart';

class VisitListItem extends StatelessWidget {
  final Visit visit;

  const VisitListItem({
    super.key,
    required this.visit,
  });

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    IconData statusIcon;
    
    switch (visit.visitStatus) {
      case VisitStatus.checkedIn:
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case VisitStatus.checkedOut:
        statusColor = Colors.blue;
        statusIcon = Icons.logout;
        break;
      case VisitStatus.scheduled:
        statusColor = Colors.orange;
        statusIcon = Icons.schedule;
        break;
      case VisitStatus.cancelled:
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help_outline;
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: statusColor.withOpacity(0.2),
          child: Icon(statusIcon, color: statusColor),
        ),
        title: Text(
          visit.hostName ?? 'Unknown Host',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(visit.visitPurpose.displayName),
            if (visit.checkInTime != null)
              Text(
                'In: ${DateFormat('MMM d, h:mm a').format(visit.checkInTime!)}',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            if (visit.checkOutTime != null)
              Text(
                'Out: ${DateFormat('MMM d, h:mm a').format(visit.checkOutTime!)}',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            if (visit.badgeNumber != null)
              Chip(
                label: Text(
                  'Badge: ${visit.badgeNumber}',
                  style: const TextStyle(fontSize: 10),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 4),
              ),
          ],
        ),
        trailing: Chip(
          label: Text(
            visit.visitStatus.displayName,
            style: TextStyle(fontSize: 10, color: statusColor),
          ),
          backgroundColor: statusColor.withOpacity(0.1),
          padding: const EdgeInsets.symmetric(horizontal: 4),
        ),
      ),
    );
  }
}

