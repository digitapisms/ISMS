import 'package:equatable/equatable.dart';

class ChatMessage extends Equatable {
  const ChatMessage({
    required this.id,
    required this.content,
    required this.isUser,
    required this.timestamp,
    this.taskId,
    this.status,
  });

  final String id;
  final String content;
  final bool isUser;
  final DateTime timestamp;
  final String? taskId; // AI task ID if this is an AI response
  final String? status; // Task status: pending, processing, completed, failed

  factory ChatMessage.user({
    required String id,
    required String content,
    required DateTime timestamp,
  }) {
    return ChatMessage(
      id: id,
      content: content,
      isUser: true,
      timestamp: timestamp,
    );
  }

  factory ChatMessage.ai({
    required String id,
    required String content,
    required DateTime timestamp,
    String? taskId,
    String? status,
  }) {
    return ChatMessage(
      id: id,
      content: content,
      isUser: false,
      timestamp: timestamp,
      taskId: taskId,
      status: status,
    );
  }

  ChatMessage copyWith({
    String? id,
    String? content,
    bool? isUser,
    DateTime? timestamp,
    String? taskId,
    String? status,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      content: content ?? this.content,
      isUser: isUser ?? this.isUser,
      timestamp: timestamp ?? this.timestamp,
      taskId: taskId ?? this.taskId,
      status: status ?? this.status,
    );
  }

  bool get isPending => status == 'pending' || status == 'processing';
  bool get isCompleted => status == 'completed';
  bool get isFailed => status == 'failed';

  @override
  List<Object?> get props => [id, content, isUser, timestamp, taskId, status];
}
