import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../school_registration/application/school_providers.dart';
import '../data/online_class_repository.dart';
import '../domain/online_class.dart';
import '../domain/online_class_session.dart';

/// Repository provider
final onlineClassRepositoryProvider = Provider<OnlineClassRepository>((ref) {
  final repo = OnlineClassRepository();
  final school = ref.watch(currentSchoolProvider);
  if (school != null) {
    repo.setSchoolId(school.id);
  }
  return repo;
});

/// Online Classes Providers

/// All online classes for current school
final onlineClassesProvider = FutureProvider<List<OnlineClass>>((ref) async {
  final school = ref.watch(currentSchoolProvider);
  if (school == null) return [];
  final repo = ref.read(onlineClassRepositoryProvider);
  return repo.fetchOnlineClasses(activeOnly: true);
});

/// Online classes filtered by institution type
final onlineClassesByInstitutionTypeProvider = 
    FutureProvider.family<List<OnlineClass>, String>((ref, institutionTypeId) async {
  final school = ref.watch(currentSchoolProvider);
  if (school == null) return [];
  final repo = ref.read(onlineClassRepositoryProvider);
  return repo.fetchOnlineClasses(
    activeOnly: true,
    institutionTypeId: institutionTypeId,
  );
});

/// Single online class by ID
final onlineClassProvider = 
    FutureProvider.family<OnlineClass?, String>((ref, id) async {
  final school = ref.watch(currentSchoolProvider);
  if (school == null) return null;
  final repo = ref.read(onlineClassRepositoryProvider);
  return repo.fetchOnlineClass(id);
});

/// Online Class Sessions Providers

/// Sessions for a specific online class
final onlineClassSessionsProvider = 
    FutureProvider.family<List<OnlineClassSession>, String>((ref, onlineClassId) async {
  final school = ref.watch(currentSchoolProvider);
  if (school == null) return [];
  final repo = ref.read(onlineClassRepositoryProvider);
  return repo.fetchSessions(onlineClassId);
});

/// Upcoming sessions
final upcomingSessionsProvider = FutureProvider<List<OnlineClassSession>>((ref) async {
  final school = ref.watch(currentSchoolProvider);
  if (school == null) return [];
  final repo = ref.read(onlineClassRepositoryProvider);
  return repo.fetchUpcomingSessions(limit: 10);
});

/// Upcoming sessions by institution type
final upcomingSessionsByInstitutionTypeProvider = 
    FutureProvider.family<List<OnlineClassSession>, String>((ref, institutionTypeId) async {
  final school = ref.watch(currentSchoolProvider);
  if (school == null) return [];
  final repo = ref.read(onlineClassRepositoryProvider);
  return repo.fetchUpcomingSessions(
    limit: 10,
    institutionTypeId: institutionTypeId,
  );
});

/// Notifiers for mutations

/// Notifier for creating online classes
final onlineClassCreatorProvider = 
    StateNotifierProvider<OnlineClassCreator, AsyncValue<OnlineClass?>>((ref) {
  return OnlineClassCreator(ref);
});

class OnlineClassCreator extends StateNotifier<AsyncValue<OnlineClass?>> {
  final Ref ref;
  
  OnlineClassCreator(this.ref) : super(const AsyncValue.data(null));

  Future<void> createOnlineClass(OnlineClass onlineClass) async {
    state = const AsyncValue.loading();
    try {
      final repo = ref.read(onlineClassRepositoryProvider);
      final createdClass = await repo.createOnlineClass(onlineClass);
      state = AsyncValue.data(createdClass);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  void reset() {
    state = const AsyncValue.data(null);
  }
}

/// Notifier for updating online classes
final onlineClassUpdaterProvider = 
    StateNotifierProvider<OnlineClassUpdater, AsyncValue<OnlineClass?>>((ref) {
  return OnlineClassUpdater(ref);
});

class OnlineClassUpdater extends StateNotifier<AsyncValue<OnlineClass?>> {
  final Ref ref;
  
  OnlineClassUpdater(this.ref) : super(const AsyncValue.data(null));

  Future<void> updateOnlineClass(OnlineClass onlineClass) async {
    state = const AsyncValue.loading();
    try {
      final repo = ref.read(onlineClassRepositoryProvider);
      final updatedClass = await repo.updateOnlineClass(onlineClass);
      state = AsyncValue.data(updatedClass);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  void reset() {
    state = const AsyncValue.data(null);
  }
}

/// Notifier for session management
final sessionManagerProvider = 
    StateNotifierProvider<SessionManager, AsyncValue<OnlineClassSession?>>((ref) {
  return SessionManager(ref);
});

class SessionManager extends StateNotifier<AsyncValue<OnlineClassSession?>> {
  final Ref ref;
  
  SessionManager(this.ref) : super(const AsyncValue.data(null));

  Future<void> startSession(String sessionId) async {
    state = const AsyncValue.loading();
    try {
      final repo = ref.read(onlineClassRepositoryProvider);
      final session = await repo.recordSessionStart(sessionId);
      state = AsyncValue.data(session);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> endSession(String sessionId) async {
    state = const AsyncValue.loading();
    try {
      final repo = ref.read(onlineClassRepositoryProvider);
      final session = await repo.recordSessionEnd(sessionId);
      state = AsyncValue.data(session);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateParticipantCount(String sessionId, int count) async {
    state = const AsyncValue.loading();
    try {
      final repo = ref.read(onlineClassRepositoryProvider);
      final session = await repo.updateParticipantCount(sessionId, count);
      state = AsyncValue.data(session);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  void reset() {
    state = const AsyncValue.data(null);
  }
}