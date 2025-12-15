import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/messaging_providers.dart';
import '../../domain/message.dart';
import '../../domain/messaging_type.dart';
import '../../../authentication/application/auth_providers.dart';
import '../widgets/message_bubble.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String conversationId;
  final String conversationTitle;

  const ChatScreen({
    super.key,
    required this.conversationId,
    required this.conversationTitle,
  });

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final repo = ref.read(messagingRepositoryProvider);
    final currentUser = ref.read(currentUserProvider).value;
    if (currentUser?.id == null) return;

    final message = Message(
      id: '',
      schoolId: repo.schoolId ?? '',
      conversationId: widget.conversationId,
      senderId: currentUser!.id,
      messageType: MessageType.text,
      content: text,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    try {
      await repo.sendMessage(message);
      _messageController.clear();
      // Scroll to bottom after sending
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sending message: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(conversationMessagesStreamProvider(widget.conversationId));

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.conversationTitle),
      ),
      body: Column(
        children: [
          Expanded(
            child: messagesAsync.when(
              data: (messages) {
                if (messages.isEmpty) {
                  return Center(
                    child: Text(
                      'No messages yet. Start the conversation!',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(8),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final currentUser = ref.read(currentUserProvider).value;
                    final isMe = message.senderId == currentUser?.id;
                    
                    return MessageBubble(
                      message: message,
                      isMe: isMe,
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Text(
                  'Error loading messages: $error',
                  style: TextStyle(color: Colors.red[600]),
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              border: Border(top: BorderSide(color: Colors.grey[300]!)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Type a message...',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    maxLines: null,
                    textCapitalization: TextCapitalization.sentences,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sendMessage,
                  color: Theme.of(context).primaryColor,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

