import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/tenant/tenant_context.dart';
import '../../authentication/application/auth_providers.dart';
import '../data/enrichment_repository.dart';
import '../domain/club.dart';
import '../domain/enrichment_category.dart';
import '../domain/game.dart';
import '../domain/quiz.dart';
import '../domain/reward.dart';

final enrichmentRepositoryProvider = Provider<EnrichmentRepository>((ref) {
  final repo = EnrichmentRepository();
  final tenantSchool = ref.read(tenantContextProvider);
  final authUser = ref.read(authStateProvider);
  repo.setSchoolId(tenantSchool?.id ?? authUser?.schoolId);
  return repo;
});

// Categories
final enrichmentCategoriesProvider = FutureProvider<List<EnrichmentCategory>>((
  ref,
) async {
  final repo = ref.watch(enrichmentRepositoryProvider);
  return repo.fetchCategories();
});

// Quizzes
final quizzesProvider = FutureProvider.family<List<Quiz>, Map<String, String?>>(
  (ref, filters) async {
    final repo = ref.watch(enrichmentRepositoryProvider);
    return repo.fetchQuizzes(
      categoryId: filters['categoryId'],
      status: filters['status'],
    );
  },
);

final quizProvider = FutureProvider.family<Quiz?, String>((ref, quizId) async {
  final repo = ref.watch(enrichmentRepositoryProvider);
  return repo.fetchQuizById(quizId);
});

final quizQuestionsProvider = FutureProvider.family<List<QuizQuestion>, String>(
  (ref, quizId) async {
    final repo = ref.watch(enrichmentRepositoryProvider);
    return repo.fetchQuizQuestions(quizId);
  },
);

final quizAttemptsProvider =
    FutureProvider.family<List<QuizAttempt>, Map<String, String?>>((
      ref,
      filters,
    ) async {
      final repo = ref.watch(enrichmentRepositoryProvider);
      return repo.fetchQuizAttempts(
        quizId: filters['quizId'],
        studentId: filters['studentId'],
      );
    });

// Games
final gamesProvider = FutureProvider<List<Game>>((ref) async {
  final repo = ref.watch(enrichmentRepositoryProvider);
  return repo.fetchGames();
});

final gameProvider = FutureProvider.family<Game?, String>((ref, gameId) async {
  final repo = ref.watch(enrichmentRepositoryProvider);
  return repo.fetchGameById(gameId);
});

final gameSessionsProvider =
    FutureProvider.family<List<GameSession>, Map<String, String?>>((
      ref,
      filters,
    ) async {
      final repo = ref.watch(enrichmentRepositoryProvider);
      return repo.fetchGameSessions(
        gameId: filters['gameId'],
        studentId: filters['studentId'],
      );
    });

// Clubs
final clubsProvider = FutureProvider.family<List<Club>, String?>((
  ref,
  status,
) async {
  final repo = ref.watch(enrichmentRepositoryProvider);
  return repo.fetchClubs(status: status);
});

final clubProvider = FutureProvider.family<Club?, String>((ref, clubId) async {
  final repo = ref.watch(enrichmentRepositoryProvider);
  return repo.fetchClubById(clubId);
});

final clubMembersProvider = FutureProvider.family<List<ClubMember>, String>((
  ref,
  clubId,
) async {
  final repo = ref.watch(enrichmentRepositoryProvider);
  return repo.fetchClubMembers(clubId);
});

final clubEventsProvider = FutureProvider.family<List<ClubEvent>, String>((
  ref,
  clubId,
) async {
  final repo = ref.watch(enrichmentRepositoryProvider);
  return repo.fetchClubEvents(clubId);
});

// Rewards
final activityRewardsProvider = FutureProvider<List<ActivityReward>>((
  ref,
) async {
  final repo = ref.watch(enrichmentRepositoryProvider);
  return repo.fetchActivityRewards();
});

final studentRewardsProvider =
    FutureProvider.family<List<StudentReward>, String?>((ref, studentId) async {
      final repo = ref.watch(enrichmentRepositoryProvider);
      return repo.fetchStudentRewards(studentId: studentId);
    });

final studentPointsProvider = FutureProvider.family<double, String>((
  ref,
  studentId,
) async {
  final repo = ref.watch(enrichmentRepositoryProvider);
  return repo.getStudentPoints(studentId);
});

final studentEngagementStatsProvider =
    FutureProvider.family<List<StudentEngagementStats>, Map<String, String>>((
      ref,
      params,
    ) async {
      final repo = ref.watch(enrichmentRepositoryProvider);
      return repo.fetchStudentEngagementStats(
        studentId: params['studentId']!,
        period: params['period'],
      );
    });

/// Provider for current user's database ID (from users table)
final currentUserIdProvider = FutureProvider<String?>((ref) async {
  final repo = ref.watch(enrichmentRepositoryProvider);
  return repo.getCurrentUserId();
});
