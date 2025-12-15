class MessageAttachment {
  final String id;
  final String schoolId;
  final String messageId;
  final String fileName;
  final String filePath;
  final String? fileUrl;
  final String? fileType;
  final int? fileSize;
  final String? mimeType;
  final String? thumbnailUrl;
  final int? duration; // For voice/video messages in seconds
  final DateTime createdAt;

  MessageAttachment({
    required this.id,
    required this.schoolId,
    required this.messageId,
    required this.fileName,
    required this.filePath,
    this.fileUrl,
    this.fileType,
    this.fileSize,
    this.mimeType,
    this.thumbnailUrl,
    this.duration,
    required this.createdAt,
  });

  factory MessageAttachment.fromJson(Map<String, dynamic> json) {
    return MessageAttachment(
      id: json['id'] as String,
      schoolId: json['school_id'] as String,
      messageId: json['message_id'] as String,
      fileName: json['file_name'] as String,
      filePath: json['file_path'] as String,
      fileUrl: json['file_url'] as String?,
      fileType: json['file_type'] as String?,
      fileSize: json['file_size'] as int?,
      mimeType: json['mime_type'] as String?,
      thumbnailUrl: json['thumbnail_url'] as String?,
      duration: json['duration'] as int?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'school_id': schoolId,
      'message_id': messageId,
      'file_name': fileName,
      'file_path': filePath,
      'file_url': fileUrl,
      'file_type': fileType,
      'file_size': fileSize,
      'mime_type': mimeType,
      'thumbnail_url': thumbnailUrl,
      'duration': duration,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

