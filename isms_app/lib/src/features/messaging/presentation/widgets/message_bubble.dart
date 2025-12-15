import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/message.dart';

class MessageBubble extends StatelessWidget {
  final Message message;
  final bool isMe;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isMe
              ? Theme.of(context).primaryColor
              : Colors.grey[300],
          borderRadius: BorderRadius.circular(18),
        ),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.7,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.content ?? '',
              style: TextStyle(
                color: isMe ? Colors.white : Colors.black87,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  DateFormat('h:mm a').format(message.createdAt),
                  style: TextStyle(
                    color: isMe ? Colors.white70 : Colors.black54,
                    fontSize: 12,
                  ),
                ),
                if (message.isEdited) ...[
                  const SizedBox(width: 4),
                  Text(
                    'edited',
                    style: TextStyle(
                      color: isMe ? Colors.white70 : Colors.black54,
                      fontSize: 10,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

