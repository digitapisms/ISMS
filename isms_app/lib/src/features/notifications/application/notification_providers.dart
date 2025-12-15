import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/tenant/tenant_context.dart';
import '../../authentication/application/auth_providers.dart';
import '../data/notification_repository.dart';
import '../domain/notification.dart';
import '../domain/notification_template.dart';
import '../services/email_service.dart';
import '../services/notification_service.dart';
import '../services/sms_service.dart';

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  final repo = NotificationRepository();
  final tenantSchool = ref.watch(tenantContextProvider);
  final authUser = ref.watch(authStateProvider);
  repo.setSchoolId(tenantSchool?.id ?? authUser?.schoolId);
  return repo;
});

final emailServiceProvider = Provider<EmailService>((ref) => EmailService());

final smsServiceProvider = Provider<SMSService>((ref) => SMSService());

final notificationServiceProvider = Provider<NotificationService>((ref) {
  final repo = ref.read(notificationRepositoryProvider);
  final emailService = ref.read(emailServiceProvider);
  final smsService = ref.read(smsServiceProvider);
  return NotificationService(
    repository: repo,
    emailService: emailService,
    smsService: smsService,
  );
});

final notificationTemplatesProvider =
    FutureProvider.family<List<NotificationTemplate>, String?>((
      ref,
      category,
    ) async {
      final repo = ref.read(notificationRepositoryProvider);
      return repo.getTemplates(category: category);
    });

final userNotificationsProvider =
    FutureProvider.family<
      List<Notification>,
      ({String? userId, NotificationType? type, int? limit})
    >((ref, params) async {
      final repo = ref.read(notificationRepositoryProvider);
      return repo.getUserNotifications(
        userId: params.userId,
        type: params.type,
        limit: params.limit,
      );
    });

final notificationPreferencesProvider =
    FutureProvider.family<List<NotificationPreference>, String>((
      ref,
      userId,
    ) async {
      final repo = ref.read(notificationRepositoryProvider);
      return repo.getUserPreferences(userId);
    });

final notificationStatsProvider = FutureProvider<Map<String, dynamic>>((
  ref,
) async {
  final repo = ref.read(notificationRepositoryProvider);
  return repo.getNotificationStats();
});
