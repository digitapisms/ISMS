import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/security_entry.dart';
import '../../domain/visitor_type.dart';

class SecurityEntryListItem extends StatelessWidget {
  final SecurityEntry entry;

  const SecurityEntryListItem({
    super.key,
    required this.entry,
  });

  @override
  Widget build(BuildContext context) {
    Color alertColor;
    switch (entry.alertLevel) {
      case AlertLevel.normal:
        alertColor = Colors.green;
        break;
      case AlertLevel.low:
        alertColor = Colors.blue;
        break;
      case AlertLevel.medium:
        alertColor = Colors.orange;
        break;
      case AlertLevel.high:
        alertColor = Colors.red;
        break;
      case AlertLevel.critical:
        alertColor = Colors.purple;
        break;
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: alertColor.withOpacity(0.2),
          child: Icon(
            entry.direction == 'entry' ? Icons.login : Icons.logout,
            color: alertColor,
          ),
        ),
        title: Text(
          entry.personName ?? entry.vehicleNumber ?? 'Unknown',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${entry.entryType.dbValue.toUpperCase()} - ${entry.gateName}'),
            Text(
              DateFormat('MMM d, h:mm a').format(entry.entryTime),
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            if (entry.alertLevel != AlertLevel.normal)
              Chip(
                label: Text(
                  entry.alertLevel.displayName,
                  style: const TextStyle(fontSize: 10, color: Colors.white),
                ),
                backgroundColor: alertColor,
                padding: const EdgeInsets.symmetric(horizontal: 4),
              ),
          ],
        ),
        trailing: Icon(
          entry.isAuthorized ? Icons.check_circle : Icons.warning,
          color: entry.isAuthorized ? Colors.green : Colors.red,
        ),
      ),
    );
  }
}

