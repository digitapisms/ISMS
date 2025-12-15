import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/conversation.dart';
import '../../domain/messaging_type.dart';

class ConversationListItem extends StatelessWidget {
  final Conversation conversation;
  final VoidCallback onTap;

  const ConversationListItem({
    super.key,
    required this.conversation,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        child: Icon(
          conversation.conversationType == ConversationType.direct
              ? Icons.person
              : Icons.group,
        ),
      ),
      title: Text(
        conversation.title ?? 'Conversation',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(
        conversation.lastMessagePreview ?? 'No messages yet',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: conversation.lastMessageAt != null
          ? Text(
              DateFormat('MMM d, h:mm a').format(conversation.lastMessageAt!),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            )
          : null,
      onTap: onTap,
    );
  }
}

