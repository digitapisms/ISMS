import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../authentication/application/auth_providers.dart';
import '../data/events_repository.dart';
import '../domain/event.dart';

final eventsRepositoryProvider = Provider<EventsRepository>((ref) {
  final repo = EventsRepository();
  final currentUser = ref.watch(currentUserProvider).value;
  if (currentUser?.schoolId != null) {
    repo.setSchoolId(currentUser!.schoolId);
  }
  return repo;
});

final eventsProvider = FutureProvider<List<Event>>((ref) async {
  final repo = ref.read(eventsRepositoryProvider);
  return repo.fetchEvents();
});

final upcomingEventsProvider = FutureProvider<List<Event>>((ref) async {
  final repo = ref.read(eventsRepositoryProvider);
  final now = DateTime.now();
  return repo.fetchEvents(
    startDate: now,
    status: 'published',
  );
});

final eventRegistrationsProvider = FutureProvider.family<List<Map<String, dynamic>>, String>((ref, eventId) async {
  final repo = ref.read(eventsRepositoryProvider);
  return repo.fetchEventRegistrations(eventId);
});

