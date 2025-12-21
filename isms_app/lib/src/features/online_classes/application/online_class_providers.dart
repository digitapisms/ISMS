import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_error.dart';
import '../../../core/errors/error_handler.dart';
import '../../../core/errors/provider_helpers.dart';
import '../../school_registration/application/school_providers.dart';
import '../data/online_class_repository.dart';
import '../domain/online_class.dart';
import '../domain/online_class_platform.dart';
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
  return safeProviderOperation<List<OnlineClass>>(
    ref: ref,
    operation: (schoolId) async {
      final repo = ref.read(onlineClassRepositoryProvider);
      return await repo
          .fetchOnlineClasses(activeOnly: true)
          .timeout(const Duration(seconds: 10));
    },
    onError: () => <OnlineClass>[],
    context: 'OnlineClassesProvider',
  );
});

/// Online classes filtered by institution type
final onlineClassesByInstitutionTypeProvider =
    FutureProvider.family<List<OnlineClass>, String>((
      ref,
      institutionTypeId,
    ) async {
      return safeProviderOperation<List<OnlineClass>>(
        ref: ref,
        operation: (schoolId) async {
          final repo = ref.read(onlineClassRepositoryProvider);
          return await repo
              .fetchOnlineClasses(
                activeOnly: true,
                institutionTypeId: institutionTypeId,
              )
              .timeout(const Duration(seconds: 10));
        },
        onError: () => <OnlineClass>[],
        context: 'OnlineClassesByInstitutionTypeProvider',
      );
    });

/// Single online class by ID
final onlineClassProvider = FutureProvider.family<OnlineClass?, String>((
  ref,
  id,
) async {
  final correlationId = ErrorHandler.generateCorrelationId();

  try {
    final schoolId = await getSchoolIdSafely(ref);
    if (schoolId == null) return null;

    final repo = ref.read(onlineClassRepositoryProvider);
    return await repo
        .fetchOnlineClass(id)
        .timeout(const Duration(seconds: 10), onTimeout: () => null);
  } catch (e) {
    final error = ErrorHandler.handleException(
      e,
      correlationId: correlationId,
      context: 'OnlineClassProvider',
    );
    ErrorHandler.logError(error);
    return null;
  }
});

/// Online Class Sessions Providers

/// Sessions for a specific online class
final onlineClassSessionsProvider =
    FutureProvider.family<List<OnlineClassSession>, String>((
      ref,
      onlineClassId,
    ) async {
      return safeProviderOperation<List<OnlineClassSession>>(
        ref: ref,
        operation: (schoolId) async {
          final repo = ref.read(onlineClassRepositoryProvider);
          return await repo
              .fetchSessions(onlineClassId)
              .timeout(const Duration(seconds: 10));
        },
        onError: () => <OnlineClassSession>[],
        context: 'OnlineClassSessionsProvider',
      );
    });

/// Upcoming sessions
final upcomingSessionsProvider = FutureProvider<List<OnlineClassSession>>((
  ref,
) async {
  return safeProviderOperation<List<OnlineClassSession>>(
    ref: ref,
    operation: (schoolId) async {
      final repo = ref.read(onlineClassRepositoryProvider);
      return await repo
          .fetchUpcomingSessions(limit: 10)
          .timeout(const Duration(seconds: 10));
    },
    onError: () => <OnlineClassSession>[],
    context: 'UpcomingSessionsProvider',
  );
});

/// Upcoming sessions by institution type
final upcomingSessionsByInstitutionTypeProvider =
    FutureProvider.family<List<OnlineClassSession>, String>((
      ref,
      institutionTypeId,
    ) async {
      return safeProviderOperation<List<OnlineClassSession>>(
        ref: ref,
        operation: (schoolId) async {
          final repo = ref.read(onlineClassRepositoryProvider);
          return await repo
              .fetchUpcomingSessions(
                limit: 10,
                institutionTypeId: institutionTypeId,
              )
              .timeout(const Duration(seconds: 10));
        },
        onError: () => <OnlineClassSession>[],
        context: 'UpcomingSessionsByInstitutionTypeProvider',
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

  Future<void> createOnlineClass({
    required String title,
    required String description,
    required OnlineClassPlatform platform,
    required Duration duration,
    required DateTime scheduledStart,
    required DateTime scheduledEnd,
    required int expectedParticipants,
    required bool recordSession,
    required bool breakoutRoomsEnabled,
    required bool waitingRoomEnabled,
    required bool chatEnabled,
    required bool screenSharingEnabled,
    required bool handRaiseEnabled,
    required bool pollingEnabled,
    required bool qaEnabled,
  }) async {
    state = const AsyncValue.loading();
    try {
      final schoolId = await getSchoolIdSafely(ref);
      if (schoolId == null) {
        throw ValidationError.missingField('school_id');
      }

      final school = ref.read(currentSchoolProvider);
      if (school == null) {
        throw ValidationError.missingField('school');
      }

      // Create OnlineClass object from parameters
      final onlineClass = OnlineClass(
        id: '', // Will be generated by database
        institutionTypeId: school.institutionTypeId ?? 'school',
        title: title,
        description: description,
        platform: platform,
        duration: duration,
        scheduledStart: scheduledStart,
        scheduledEnd: scheduledEnd,
        meetingUrl: '', // Will be generated by engine
        meetingPassword: '', // Will be generated by engine
        expectedParticipants: expectedParticipants,
        recordSession: recordSession,
        breakoutRoomsEnabled: breakoutRoomsEnabled,
        waitingRoomEnabled: waitingRoomEnabled,
        chatEnabled: chatEnabled,
        screenSharingEnabled: screenSharingEnabled,
        handRaiseEnabled: handRaiseEnabled,
        pollingEnabled: pollingEnabled,
        qaEnabled: qaEnabled,
        createdBy: '', // Will be set by repository
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isActive: true,
      );

      final repo = ref.read(onlineClassRepositoryProvider);
      final createdClass = await repo
          .createOnlineClass(onlineClass)
          .timeout(const Duration(seconds: 30));
      state = AsyncValue.data(createdClass);
    } catch (e, st) {
      final error = ErrorHandler.handleException(
        e,
        correlationId: ErrorHandler.generateCorrelationId(),
        context: 'OnlineClassCreator',
      );
      ErrorHandler.logError(error);
      state = AsyncValue.error(error, st);
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
      final updatedClass = await repo
          .updateOnlineClass(onlineClass)
          .timeout(const Duration(seconds: 30));
      state = AsyncValue.data(updatedClass);
    } catch (e, st) {
      final error = ErrorHandler.handleException(
        e,
        correlationId: ErrorHandler.generateCorrelationId(),
        context: 'OnlineClassUpdater',
      );
      ErrorHandler.logError(error);
      state = AsyncValue.error(error, st);
    }
  }

  void reset() {
    state = const AsyncValue.data(null);
  }
}

/// Notifier for session management
final sessionManagerProvider =
    StateNotifierProvider<SessionManager, AsyncValue<OnlineClassSession?>>((
      ref,
    ) {
      return SessionManager(ref);
    });

class SessionManager extends StateNotifier<AsyncValue<OnlineClassSession?>> {
  final Ref ref;

  SessionManager(this.ref) : super(const AsyncValue.data(null));

  Future<void> startSession(String sessionId) async {
    state = const AsyncValue.loading();
    try {
      final repo = ref.read(onlineClassRepositoryProvider);
      final session = await repo
          .recordSessionStart(sessionId)
          .timeout(const Duration(seconds: 10));
      state = AsyncValue.data(session);
    } catch (e, st) {
      final error = ErrorHandler.handleException(
        e,
        correlationId: ErrorHandler.generateCorrelationId(),
        context: 'SessionManager.startSession',
      );
      ErrorHandler.logError(error);
      state = AsyncValue.error(error, st);
    }
  }

  Future<void> endSession(String sessionId) async {
    state = const AsyncValue.loading();
    try {
      final repo = ref.read(onlineClassRepositoryProvider);
      final session = await repo
          .recordSessionEnd(sessionId)
          .timeout(const Duration(seconds: 10));
      state = AsyncValue.data(session);
    } catch (e, st) {
      final error = ErrorHandler.handleException(
        e,
        correlationId: ErrorHandler.generateCorrelationId(),
        context: 'SessionManager.endSession',
      );
      ErrorHandler.logError(error);
      state = AsyncValue.error(error, st);
    }
  }

  Future<void> updateParticipantCount(String sessionId, int count) async {
    state = const AsyncValue.loading();
    try {
      final repo = ref.read(onlineClassRepositoryProvider);
      final session = await repo
          .updateParticipantCount(sessionId, count)
          .timeout(const Duration(seconds: 10));
      state = AsyncValue.data(session);
    } catch (e, st) {
      final error = ErrorHandler.handleException(
        e,
        correlationId: ErrorHandler.generateCorrelationId(),
        context: 'SessionManager.updateParticipantCount',
      );
      ErrorHandler.logError(error);
      state = AsyncValue.error(error, st);
    }
  }

  void reset() {
    state = const AsyncValue.data(null);
  }
}
