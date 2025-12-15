import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../authentication/application/auth_providers.dart';
import '../data/messaging_repository.dart';
import '../domain/announcement.dart';
import '../domain/circular.dart';
import '../domain/conversation.dart';
import '../domain/message.dart';
import '../domain/message_template.dart';

final messagingRepositoryProvider = Provider<MessagingRepository>((ref) {
  final repo = MessagingRepository();
  final currentUser = ref.watch(currentUserProvider).value;
  if (currentUser?.schoolId != null) {
    repo.setSchoolId(currentUser!.schoolId);
  }
  return repo;
});

// Conversations
final conversationsProvider = FutureProvider<List<Conversation>>((ref) async {
  final repo = ref.read(messagingRepositoryProvider);
  final currentUser = ref.read(currentUserProvider).value;
  if (currentUser?.id == null) return [];
  return repo.fetchConversations(userId: currentUser!.id);
});

// Messages for a conversation
final conversationMessagesProvider = FutureProvider.family<List<Message>, String>(
  (ref, conversationId) async {
    final repo = ref.read(messagingRepositoryProvider);
    return repo.fetchMessages(conversationId);
  },
);

// Real-time messages stream
final conversationMessagesStreamProvider =
    StreamProvider.family<List<Message>, String>(
  (ref, conversationId) {
    final repo = ref.read(messagingRepositoryProvider);
    return repo.watchMessages(conversationId);
  },
);

// Announcements
final announcementsProvider = FutureProvider<List<Announcement>>((ref) async {
  final repo = ref.read(messagingRepositoryProvider);
  return repo.fetchAnnouncements(isPublished: true);
});

final allAnnouncementsProvider = FutureProvider<List<Announcement>>((ref) async {
  final repo = ref.read(messagingRepositoryProvider);
  return repo.fetchAnnouncements();
});

// Circulars
final circularsProvider = FutureProvider<List<Circular>>((ref) async {
  final repo = ref.read(messagingRepositoryProvider);
  return repo.fetchCirculars(isActive: true);
});

final allCircularsProvider = FutureProvider<List<Circular>>((ref) async {
  final repo = ref.read(messagingRepositoryProvider);
  return repo.fetchCirculars();
});

// Message Templates
final messageTemplatesProvider = FutureProvider<List<MessageTemplate>>((ref) async {
  final repo = ref.read(messagingRepositoryProvider);
  return repo.fetchTemplates(isActive: true);
});

final allMessageTemplatesProvider = FutureProvider<List<MessageTemplate>>((ref) async {
  final repo = ref.read(messagingRepositoryProvider);
  return repo.fetchTemplates();
});

