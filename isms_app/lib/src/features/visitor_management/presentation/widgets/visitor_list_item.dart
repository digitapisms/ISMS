import 'package:flutter/material.dart';

import '../../domain/visitor.dart';
import '../../domain/visitor_type.dart';

class VisitorListItem extends StatelessWidget {
  final Visitor visitor;

  const VisitorListItem({
    super.key,
    required this.visitor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: visitor.isBlacklisted ? Colors.red[100] : Colors.blue[100],
          child: Icon(
            visitor.isBlacklisted ? Icons.block : Icons.person,
            color: visitor.isBlacklisted ? Colors.red[800] : Colors.blue[800],
          ),
        ),
        title: Text(
          visitor.fullName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (visitor.phoneNumber != null) Text(visitor.phoneNumber!),
            if (visitor.visitorIdNumber != null)
              Text(
                'ID: ${visitor.visitorIdNumber}',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            if (visitor.isBlacklisted)
              Chip(
                label: const Text(
                  'Blacklisted',
                  style: TextStyle(fontSize: 10, color: Colors.white),
                ),
                backgroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(horizontal: 4),
              ),
          ],
        ),
        trailing: Chip(
          label: Text(
            visitor.visitorType.displayName,
            style: const TextStyle(fontSize: 10),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 4),
        ),
        onTap: () {
          // TODO: Show visitor details
        },
      ),
    );
  }
}

