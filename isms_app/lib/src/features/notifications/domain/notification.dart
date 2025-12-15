import 'package:equatable/equatable.dart';

enum NotificationType { email, sms, push, inApp }

enum NotificationStatus { pending, sent, failed, delivered }

class Notification extends Equatable {
  const Notification({
    required this.id,
    required this.schoolId,
    required this.type,
    required this.status,
    required this.recipient,
    required this.body,
    this.userId,
    this.templateId,
    this.subject,
    this.metadata,
    this.errorMessage,
    this.sentAt,
    this.deliveredAt,
    this.createdAt,
  });

  final String id;
  final String schoolId;
  final String? userId;
  final String? templateId;
  final NotificationType type;
  final NotificationStatus status;
  final String recipient; // email or phone number
  final String? subject; // for email
  final String body;
  final Map<String, dynamic>? metadata;
  final String? errorMessage;
  final DateTime? sentAt;
  final DateTime? deliveredAt;
  final DateTime? createdAt;

  factory Notification.fromMap(Map<String, dynamic> map) {
    return Notification(
      id: map['id'] as String,
      schoolId: map['school_id'] as String,
      userId: map['user_id'] as String?,
      templateId: map['template_id'] as String?,
      type: _parseNotificationType(map['type'] as String),
      status: _parseNotificationStatus(map['status'] as String),
      recipient: map['recipient'] as String,
      subject: map['subject'] as String?,
      body: map['body'] as String,
      metadata: map['metadata'] != null
          ? Map<String, dynamic>.from(map['metadata'] as Map)
          : null,
      errorMessage: map['error_message'] as String?,
      sentAt: map['sent_at'] != null ? DateTime.parse(map['sent_at']) : null,
      deliveredAt: map['delivered_at'] != null
          ? DateTime.parse(map['delivered_at'])
          : null,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'school_id': schoolId,
      'user_id': userId,
      'template_id': templateId,
      'type': _typeToString(type),
      'status': _statusToString(status),
      'recipient': recipient,
      'subject': subject,
      'body': body,
      'metadata': metadata,
      'error_message': errorMessage,
      'sent_at': sentAt?.toIso8601String(),
      'delivered_at': deliveredAt?.toIso8601String(),
      'created_at': createdAt?.toIso8601String(),
    };
  }

  static NotificationType _parseNotificationType(String value) {
    switch (value.toLowerCase()) {
      case 'email':
        return NotificationType.email;
      case 'sms':
        return NotificationType.sms;
      case 'push':
        return NotificationType.push;
      case 'in_app':
        return NotificationType.inApp;
      default:
        return NotificationType.email;
    }
  }

  static NotificationStatus _parseNotificationStatus(String value) {
    switch (value.toLowerCase()) {
      case 'pending':
        return NotificationStatus.pending;
      case 'sent':
        return NotificationStatus.sent;
      case 'failed':
        return NotificationStatus.failed;
      case 'delivered':
        return NotificationStatus.delivered;
      default:
        return NotificationStatus.pending;
    }
  }

  static String _typeToString(NotificationType type) {
    switch (type) {
      case NotificationType.email:
        return 'email';
      case NotificationType.sms:
        return 'sms';
      case NotificationType.push:
        return 'push';
      case NotificationType.inApp:
        return 'in_app';
    }
  }

  static String _statusToString(NotificationStatus status) {
    switch (status) {
      case NotificationStatus.pending:
        return 'pending';
      case NotificationStatus.sent:
        return 'sent';
      case NotificationStatus.failed:
        return 'failed';
      case NotificationStatus.delivered:
        return 'delivered';
    }
  }

  @override
  List<Object?> get props => [
    id,
    schoolId,
    userId,
    templateId,
    type,
    status,
    recipient,
    subject,
    body,
    metadata,
    errorMessage,
    sentAt,
    deliveredAt,
    createdAt,
  ];
}

class NotificationPreference extends Equatable {
  const NotificationPreference({
    required this.id,
    required this.schoolId,
    required this.userId,
    required this.templateKey,
    this.emailEnabled = true,
    this.smsEnabled = false,
    this.pushEnabled = true,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String schoolId;
  final String userId;
  final String templateKey;
  final bool emailEnabled;
  final bool smsEnabled;
  final bool pushEnabled;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory NotificationPreference.fromMap(Map<String, dynamic> map) {
    return NotificationPreference(
      id: map['id'] as String,
      schoolId: map['school_id'] as String,
      userId: map['user_id'] as String,
      templateKey: map['template_key'] as String,
      emailEnabled: (map['email_enabled'] as bool?) ?? true,
      smsEnabled: (map['sms_enabled'] as bool?) ?? false,
      pushEnabled: (map['push_enabled'] as bool?) ?? true,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'])
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'school_id': schoolId,
      'user_id': userId,
      'template_key': templateKey,
      'email_enabled': emailEnabled,
      'sms_enabled': smsEnabled,
      'push_enabled': pushEnabled,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
    id,
    schoolId,
    userId,
    templateKey,
    emailEnabled,
    smsEnabled,
    pushEnabled,
    createdAt,
    updatedAt,
  ];
}
