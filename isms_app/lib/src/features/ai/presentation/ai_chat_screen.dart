import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/subscription/feature_guard.dart';
import '../../school_registration/application/school_providers.dart';
import '../application/ai_providers.dart';
import '../domain/ai_prompt.dart';
import '../domain/ai_task.dart';
import '../domain/chat_message.dart';

class AiChatScreen extends ConsumerStatefulWidget {
  const AiChatScreen({super.key});

  @override
  ConsumerState<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends ConsumerState<AiChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  AiPrompt? _selectedPrompt;
  Timer? _pollingTimer;
  String? _currentTaskId;

  @override
  void initState() {
    super.initState();
    // Default to AI Chat prompt
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDefaultPrompt();
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _pollingTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadDefaultPrompt() async {
    final promptsAsync = ref.read(aiPromptsProvider);
    await promptsAsync.whenData((prompts) {
      if (prompts.isNotEmpty && _selectedPrompt == null) {
        // Find AI Chat prompt or use first one
        final chatPrompt = prompts.firstWhere(
          (p) => p.promptKey == 'ai_chat',
          orElse: () => prompts.first,
        );
        setState(() {
          _selectedPrompt = chatPrompt;
        });
      }
    });
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty || _selectedPrompt == null) return;

    final school = ref.read(currentSchoolProvider);
    if (school == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No school context available')),
      );
      return;
    }

    // Add user message to UI
    final userMessage = ChatMessage.user(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: message,
      timestamp: DateTime.now(),
    );
    setState(() {
      _messages.add(userMessage);
    });
    _messageController.clear();
    _scrollToBottom();

    try {
      // Create AI task
      final task = await ref.read(
        aiTaskCreateProvider(
          AiTaskRequest(
            promptKey: _selectedPrompt!.promptKey,
            input: {
              'message': message,
              'conversation_history': _messages
                  .where((m) => !m.isPending)
                  .map(
                    (m) => {
                      'role': m.isUser ? 'user' : 'assistant',
                      'content': m.content,
                    },
                  )
                  .toList(),
            },
          ),
        ).future,
      );

      // Add pending AI message
      final aiMessage = ChatMessage.ai(
        id: task.id,
        content: 'Thinking...',
        timestamp: DateTime.now(),
        taskId: task.id,
        status: task.status,
      );
      setState(() {
        _messages.add(aiMessage);
        _currentTaskId = task.id;
      });
      _scrollToBottom();

      // Start polling for task completion
      _startPolling(task.id);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    }
  }

  void _startPolling(String taskId) {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      final taskAsync = ref.read(aiTaskProvider(taskId));
      await taskAsync.whenData((task) {
        if (task == null) return;

        setState(() {
          final index = _messages.indexWhere((m) => m.taskId == taskId);
          if (index != -1) {
            if (task.status == 'completed' && task.output != null) {
              // Extract response from output
              final response =
                  task.output!['response'] as String? ??
                  task.output!['text'] as String? ??
                  task.output!.toString();
              _messages[index] = _messages[index].copyWith(
                content: response,
                status: task.status,
              );
              _currentTaskId = null;
              timer.cancel();
            } else if (task.status == 'failed') {
              _messages[index] = _messages[index].copyWith(
                content: task.errorMessage ?? 'Failed to get response',
                status: task.status,
              );
              _currentTaskId = null;
              timer.cancel();
            } else {
              _messages[index] = _messages[index].copyWith(
                status: task.status,
                content: task.status == 'processing'
                    ? 'Processing...'
                    : 'Thinking...',
              );
            }
          }
        });
        _scrollToBottom();
      });
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return FeatureGuard(
      featureKey: 'ai_chat',
      child: Scaffold(
        appBar: AppBar(
          title: const Text('AI Tutor Chat'),
          actions: [
            IconButton(
              icon: const Icon(Icons.history),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const _TaskHistoryScreen()),
                );
              },
              tooltip: 'View History',
            ),
            PopupMenuButton<AiPrompt>(
              icon: const Icon(Icons.settings),
              tooltip: 'Select AI Feature',
              onSelected: (prompt) {
                setState(() {
                  _selectedPrompt = prompt;
                });
              },
              itemBuilder: (context) {
                final promptsAsync = ref.watch(aiPromptsProvider);
                return promptsAsync.when(
                  data: (prompts) => prompts
                      .map(
                        (prompt) => PopupMenuItem(
                          value: prompt,
                          child: ListTile(
                            title: Text(prompt.name),
                            subtitle: prompt.description != null
                                ? Text(
                                    prompt.description!,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  )
                                : null,
                            trailing:
                                _selectedPrompt?.promptKey == prompt.promptKey
                                ? const Icon(Icons.check, size: 20)
                                : null,
                          ),
                        ),
                      )
                      .toList(),
                  loading: () => [
                    const PopupMenuItem(
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  ],
                  error: (_, __) => [
                    const PopupMenuItem(child: Text('Error loading prompts')),
                  ],
                );
              },
            ),
          ],
        ),
        body: Column(
          children: [
            // Prompt selector banner
            if (_selectedPrompt != null)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                color: Theme.of(context).colorScheme.primaryContainer,
                child: Row(
                  children: [
                    Icon(
                      Icons.auto_awesome,
                      size: 16,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _selectedPrompt!.name,
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(
                            context,
                          ).colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Messages list
            Expanded(
              child: _messages.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.chat_bubble_outline,
                            size: 64,
                            color: Theme.of(context).colorScheme.outline,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Start a conversation with AI Tutor',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Ask questions, get explanations, or request help',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final message = _messages[index];
                        return _ChatBubble(message: message);
                      },
                    ),
            ),

            // Input field
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        decoration: InputDecoration(
                          hintText: 'Type your message...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        maxLines: null,
                        textCapitalization: TextCapitalization.sentences,
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      onPressed: _currentTaskId != null ? null : _sendMessage,
                      icon: _currentTaskId != null
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.send),
                      tooltip: 'Send',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    final isPending = message.isPending;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: Icon(
                Icons.auto_awesome,
                size: 16,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isUser
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(16).copyWith(
                  bottomRight: isUser ? const Radius.circular(4) : null,
                  bottomLeft: !isUser ? const Radius.circular(4) : null,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.content,
                    style: TextStyle(
                      color: isUser
                          ? Theme.of(context).colorScheme.onPrimary
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (isPending) ...[
                    const SizedBox(height: 8),
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isUser
                              ? Theme.of(context).colorScheme.onPrimary
                              : Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
              child: Icon(
                Icons.person,
                size: 16,
                color: Theme.of(context).colorScheme.onSecondaryContainer,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TaskHistoryScreen extends ConsumerWidget {
  const _TaskHistoryScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(aiTasksProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('AI Task History')),
      body: tasksAsync.when(
        data: (tasks) {
          if (tasks.isEmpty) {
            return const Center(child: Text('No AI tasks yet'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              final task = tasks[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: _getStatusIcon(task.status),
                  title: Text(
                    task.promptKey.replaceAll('_', ' ').toUpperCase(),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (task.input['message'] != null)
                        Text(
                          task.input['message'] as String,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      const SizedBox(height: 4),
                      Text(
                        _formatTimestamp(task.createdAt),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                  trailing: task.isFinal
                      ? IconButton(
                          icon: const Icon(Icons.visibility),
                          onPressed: () {
                            _showTaskDetail(context, task);
                          },
                        )
                      : null,
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
    );
  }

  Widget _getStatusIcon(String status) {
    switch (status) {
      case 'completed':
        return const Icon(Icons.check_circle, color: Colors.green);
      case 'failed':
        return const Icon(Icons.error, color: Colors.red);
      case 'processing':
        return const SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        );
      default:
        return const Icon(Icons.pending, color: Colors.orange);
    }
  }

  String _formatTimestamp(DateTime? timestamp) {
    if (timestamp == null) return 'Unknown';
    final now = DateTime.now();
    final diff = now.difference(timestamp);

    if (diff.inDays > 0) {
      return '${diff.inDays} day${diff.inDays > 1 ? 's' : ''} ago';
    } else if (diff.inHours > 0) {
      return '${diff.inHours} hour${diff.inHours > 1 ? 's' : ''} ago';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes} minute${diff.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }

  void _showTaskDetail(BuildContext context, AiTask task) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(task.promptKey.replaceAll('_', ' ').toUpperCase()),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Status: ${task.status}'),
              const SizedBox(height: 16),
              if (task.input['message'] != null) ...[
                const Text(
                  'Input:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(task.input['message'] as String),
                const SizedBox(height: 16),
              ],
              if (task.output != null) ...[
                const Text(
                  'Response:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  task.output!['response'] as String? ??
                      task.output!['text'] as String? ??
                      task.output!.toString(),
                ),
              ],
              if (task.errorMessage != null) ...[
                const SizedBox(height: 16),
                Text(
                  'Error: ${task.errorMessage}',
                  style: const TextStyle(color: Colors.red),
                ),
              ],
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
}
