import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/network/supabase_client.dart';
import '../domain/notification.dart';
import '../domain/notification_template.dart';

class NotificationRepository {
  SupabaseClient get _client => SupabaseManager.client;
  String? _schoolId;

  void setSchoolId(String? schoolId) {
    _schoolId = schoolId;
  }

  String? get schoolId => _schoolId;

  String _requireSchoolId() {
    final id = _schoolId;
    if (id == null) {
      throw Exception(
        'School context is required. Please ensure you are signed in to a school tenant.',
      );
    }
    return id;
  }

  // =========================================================
  // TEMPLATE METHODS
  // =========================================================

  /// Get all notification templates
  Future<List<NotificationTemplate>> getTemplates({String? category}) async {
    var query = _client
        .from('notification_templates')
        .select()
        .eq('is_active', true);

    if (category != null) {
      query = query.eq('category', category);
    }

    final response = await query.order('name');
    final data = response;

    return data.map((row) => NotificationTemplate.fromMap(row)).toList();
  }

  /// Get template by key
  Future<NotificationTemplate?> getTemplateByKey(String templateKey) async {
    final response = await _client
        .from('notification_templates')
        .select()
        .eq('template_key', templateKey)
        .eq('is_active', true)
        .maybeSingle();

    if (response == null) return null;
    return NotificationTemplate.fromMap(response);
  }

  /// Render template with variables
  Future<Map<String, String>> renderTemplate({
    required String templateKey,
    required Map<String, String> variables,
  }) async {
    try {
      final result = await _client.rpc(
        'render_notification_template',
        params: {'p_template_key': templateKey, 'p_variables': variables},
      );

      if (result == null) {
        throw Exception('Template rendering returned null');
      }

      final map = result as Map<String, dynamic>;
      return {
        'email_subject': map['email_subject'] as String? ?? '',
        'email_body': map['email_body'] as String? ?? '',
        'sms_body': map['sms_body'] as String? ?? '',
      };
    } catch (e) {
      // Fallback to manual replacement
      final template = await getTemplateByKey(templateKey);
      if (template == null) {
        throw Exception('Template not found: $templateKey');
      }

      String? emailSubject = template.emailSubject;
      String? emailBody = template.emailBody;
      String? smsBody = template.smsBody;

      for (final entry in variables.entries) {
        final placeholder = '{{${entry.key}}}';
        emailSubject = emailSubject?.replaceAll(placeholder, entry.value);
        emailBody = emailBody?.replaceAll(placeholder, entry.value);
        smsBody = smsBody?.replaceAll(placeholder, entry.value);
      }

      return {
        'email_subject': emailSubject ?? '',
        'email_body': emailBody ?? '',
        'sms_body': smsBody ?? '',
      };
    }
  }

  // =========================================================
  // NOTIFICATION METHODS
  // =========================================================

  /// Create a notification record
  Future<Notification> createNotification({
    required NotificationType type,
    required String recipient,
    required String body,
    String? userId,
    String? templateId,
    String? subject,
    Map<String, dynamic>? metadata,
  }) async {
    final schoolId = _requireSchoolId();
    final response = await _client
        .from('notifications')
        .insert({
          'school_id': schoolId,
          'user_id': userId,
          'template_id': templateId,
          'type': _typeToString(type),
          'status': 'pending',
          'recipient': recipient,
          'subject': subject,
          'body': body,
          'metadata': metadata,
        })
        .select()
        .single();

    return Notification.fromMap(response);
  }

  /// Update notification status
  Future<void> updateNotificationStatus({
    required String notificationId,
    required NotificationStatus status,
    String? errorMessage,
    DateTime? sentAt,
    DateTime? deliveredAt,
  }) async {
    final updates = <String, dynamic>{'status': _statusToString(status)};
    if (errorMessage != null) updates['error_message'] = errorMessage;
    if (sentAt != null) updates['sent_at'] = sentAt.toIso8601String();
    if (deliveredAt != null) {
      updates['delivered_at'] = deliveredAt.toIso8601String();
    }

    await _client
        .from('notifications')
        .update(updates)
        .eq('id', notificationId);
  }

  /// Get notifications for a user
  Future<List<Notification>> getUserNotifications({
    String? userId,
    NotificationType? type,
    NotificationStatus? status,
    int? limit,
  }) async {
    final schoolId = _requireSchoolId();
    var baseQuery = _client
        .from('notifications')
        .select()
        .eq('school_id', schoolId);

    if (userId != null) {
      baseQuery = baseQuery.eq('user_id', userId);
    }
    if (type != null) {
      baseQuery = baseQuery.eq('type', _typeToString(type));
    }
    if (status != null) {
      baseQuery = baseQuery.eq('status', _statusToString(status));
    }

    var finalQuery = baseQuery.order('created_at', ascending: false);

    if (limit != null) {
      finalQuery = finalQuery.limit(limit);
    }

    final response = await finalQuery;
    final data = response;

    return data.map((row) => Notification.fromMap(row)).toList();
  }

  /// Get notification statistics
  Future<Map<String, dynamic>> getNotificationStats({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final schoolId = _requireSchoolId();
    var query = _client
        .from('notifications')
        .select('type, status')
        .eq('school_id', schoolId);

    if (startDate != null) {
      query = query.gte('created_at', startDate.toIso8601String());
    }
    if (endDate != null) {
      query = query.lte('created_at', endDate.toIso8601String());
    }

    final response = await query;
    final data = response;

    final stats = <String, int>{
      'total': data.length,
      'email_sent': 0,
      'email_failed': 0,
      'sms_sent': 0,
      'sms_failed': 0,
    };

    for (final row in data) {
      final type = row['type'] as String;
      final status = row['status'] as String;

      if (type == 'email') {
        if (status == 'sent' || status == 'delivered') {
          stats['email_sent'] = (stats['email_sent'] ?? 0) + 1;
        } else if (status == 'failed') {
          stats['email_failed'] = (stats['email_failed'] ?? 0) + 1;
        }
      } else if (type == 'sms') {
        if (status == 'sent' || status == 'delivered') {
          stats['sms_sent'] = (stats['sms_sent'] ?? 0) + 1;
        } else if (status == 'failed') {
          stats['sms_failed'] = (stats['sms_failed'] ?? 0) + 1;
        }
      }
    }

    return stats;
  }

  // =========================================================
  // PREFERENCE METHODS
  // =========================================================

  /// Get user notification preferences
  Future<List<NotificationPreference>> getUserPreferences(String userId) async {
    final schoolId = _requireSchoolId();
    final response = await _client
        .from('notification_preferences')
        .select()
        .eq('school_id', schoolId)
        .eq('user_id', userId)
        .order('template_key');

    final data = response;
    return data.map((row) => NotificationPreference.fromMap(row)).toList();
  }

  /// Update notification preference
  Future<void> updatePreference({
    required String userId,
    required String templateKey,
    bool? emailEnabled,
    bool? smsEnabled,
    bool? pushEnabled,
  }) async {
    final schoolId = _requireSchoolId();

    // Check if preference exists
    final existing = await _client
        .from('notification_preferences')
        .select('id')
        .eq('school_id', schoolId)
        .eq('user_id', userId)
        .eq('template_key', templateKey)
        .maybeSingle();

    final updates = <String, dynamic>{};
    if (emailEnabled != null) updates['email_enabled'] = emailEnabled;
    if (smsEnabled != null) updates['sms_enabled'] = smsEnabled;
    if (pushEnabled != null) updates['push_enabled'] = pushEnabled;

    if (existing != null) {
      // Update existing
      await _client
          .from('notification_preferences')
          .update(updates)
          .eq('id', existing['id']);
    } else {
      // Create new
      await _client.from('notification_preferences').insert({
        'school_id': schoolId,
        'user_id': userId,
        'template_key': templateKey,
        'email_enabled': emailEnabled ?? true,
        'sms_enabled': smsEnabled ?? false,
        'push_enabled': pushEnabled ?? true,
      });
    }
  }

  /// Check if user has preference enabled for a template
  Future<bool> isPreferenceEnabled({
    required String userId,
    required String templateKey,
    required NotificationType type,
  }) async {
    final schoolId = _requireSchoolId();
    final response = await _client
        .from('notification_preferences')
        .select()
        .eq('school_id', schoolId)
        .eq('user_id', userId)
        .eq('template_key', templateKey)
        .maybeSingle();

    if (response == null) {
      // Default: email enabled, SMS disabled
      return type == NotificationType.email;
    }

    switch (type) {
      case NotificationType.email:
        return (response['email_enabled'] as bool?) ?? true;
      case NotificationType.sms:
        return (response['sms_enabled'] as bool?) ?? false;
      case NotificationType.push:
        return (response['push_enabled'] as bool?) ?? true;
      case NotificationType.inApp:
        return true; // Always enabled
    }
  }

  String _typeToString(NotificationType type) {
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

  String _statusToString(NotificationStatus status) {
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
}
