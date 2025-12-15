class ReadReceipt {
  final String id;
  final String schoolId;
  final String messageId;
  final String userId;
  final DateTime readAt;

  ReadReceipt({
    required this.id,
    required this.schoolId,
    required this.messageId,
    required this.userId,
    required this.readAt,
  });

  factory ReadReceipt.fromJson(Map<String, dynamic> json) {
    return ReadReceipt(
      id: json['id'] as String,
      schoolId: json['school_id'] as String,
      messageId: json['message_id'] as String,
      userId: json['user_id'] as String,
      readAt: DateTime.parse(json['read_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'school_id': schoolId,
      'message_id': messageId,
      'user_id': userId,
      'read_at': readAt.toIso8601String(),
    };
  }
}

