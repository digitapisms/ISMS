import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../school_registration/application/school_providers.dart';
import '../data/library_repository.dart';
import '../domain/book.dart';
import '../domain/book_category.dart';
import '../domain/book_copy.dart';
import '../domain/book_fine.dart';
import '../domain/book_issue.dart';
import '../domain/book_reservation.dart';
import '../domain/book_return.dart';
import '../domain/book_type.dart';
import '../domain/digital_resource.dart';
import '../domain/digital_resource_annotation.dart';
import '../domain/digital_resource_progress.dart';
import '../domain/annotation_reply.dart';
import '../domain/quiz_question.dart';
import '../domain/quiz_attempt.dart';

final libraryRepositoryProvider = Provider<LibraryRepository>((ref) {
  final repo = LibraryRepository();
  final school = ref.watch(currentSchoolProvider);
  if (school != null) {
    repo.setSchoolId(school.id);
  }
  return repo;
});

// ============================================================
// BOOK CATEGORIES
// ============================================================

final bookCategoriesProvider = FutureProvider<List<BookCategory>>((ref) async {
  final school = ref.watch(currentSchoolProvider);
  if (school == null) return [];
  final repo = ref.read(libraryRepositoryProvider);
  return repo.fetchCategories();
});

// ============================================================
// BOOKS
// ============================================================

final booksProvider = FutureProvider<List<Book>>((ref) async {
  final school = ref.watch(currentSchoolProvider);
  if (school == null) return [];
  final repo = ref.read(libraryRepositoryProvider);
  return repo.fetchBooks(isActive: true);
});

final booksByCategoryProvider = FutureProvider.family<List<Book>, int?>((
  ref,
  categoryId,
) async {
  final school = ref.watch(currentSchoolProvider);
  if (school == null) return [];
  final repo = ref.read(libraryRepositoryProvider);
  return repo.fetchBooks(categoryId: categoryId, isActive: true);
});

final bookProvider = FutureProvider.family<Book?, int>((ref, bookId) async {
  final repo = ref.read(libraryRepositoryProvider);
  return repo.getBook(bookId);
});

final searchBooksProvider = FutureProvider.family<List<Book>, String>((
  ref,
  query,
) async {
  final school = ref.watch(currentSchoolProvider);
  if (school == null) return [];
  final repo = ref.read(libraryRepositoryProvider);
  return repo.fetchBooks(searchQuery: query, isActive: true);
});

// ============================================================
// BOOK COPIES
// ============================================================

final bookCopiesProvider = FutureProvider.family<List<BookCopy>, int?>((
  ref,
  bookId,
) async {
  final school = ref.watch(currentSchoolProvider);
  if (school == null) return [];
  final repo = ref.read(libraryRepositoryProvider);
  return repo.fetchBookCopies(bookId: bookId);
});

final availableBookCopiesProvider = FutureProvider.family<List<BookCopy>, int>((
  ref,
  bookId,
) async {
  final school = ref.watch(currentSchoolProvider);
  if (school == null) return [];
  final repo = ref.read(libraryRepositoryProvider);
  return repo.fetchBookCopies(bookId: bookId, status: BookCopyStatus.available);
});

// ============================================================
// BOOK ISSUES
// ============================================================

final bookIssuesProvider = FutureProvider<List<BookIssue>>((ref) async {
  final school = ref.watch(currentSchoolProvider);
  if (school == null) return [];
  final repo = ref.read(libraryRepositoryProvider);
  return repo.fetchIssues();
});

final issuesByStudentProvider = FutureProvider.family<List<BookIssue>, String>((
  ref,
  studentId,
) async {
  final school = ref.watch(currentSchoolProvider);
  if (school == null) return [];
  final repo = ref.read(libraryRepositoryProvider);
  return repo.fetchIssues(studentId: studentId);
});

final overdueIssuesProvider = FutureProvider<List<BookIssue>>((ref) async {
  final school = ref.watch(currentSchoolProvider);
  if (school == null) return [];
  final repo = ref.read(libraryRepositoryProvider);
  return repo.fetchIssues(overdue: true);
});

final issueProvider = FutureProvider.family<BookIssue?, String>((
  ref,
  issueId,
) async {
  final issues = await ref.read(bookIssuesProvider.future);
  try {
    return issues.firstWhere((i) => i.id == issueId);
  } catch (e) {
    return null;
  }
});

// ============================================================
// BOOK RETURNS
// ============================================================

final bookReturnsProvider = FutureProvider<List<BookReturn>>((ref) async {
  final school = ref.watch(currentSchoolProvider);
  if (school == null) return [];
  final repo = ref.read(libraryRepositoryProvider);
  return repo.fetchReturns();
});

// ============================================================
// BOOK RESERVATIONS
// ============================================================

final bookReservationsProvider = FutureProvider<List<BookReservation>>((
  ref,
) async {
  final school = ref.watch(currentSchoolProvider);
  if (school == null) return [];
  final repo = ref.read(libraryRepositoryProvider);
  return repo.fetchReservations();
});

final reservationsByStudentProvider =
    FutureProvider.family<List<BookReservation>, String>((
      ref,
      studentId,
    ) async {
      final school = ref.watch(currentSchoolProvider);
      if (school == null) return [];
      final repo = ref.read(libraryRepositoryProvider);
      return repo.fetchReservations(studentId: studentId);
    });

// ============================================================
// BOOK FINES
// ============================================================

final bookFinesProvider = FutureProvider<List<BookFine>>((ref) async {
  final school = ref.watch(currentSchoolProvider);
  if (school == null) return [];
  final repo = ref.read(libraryRepositoryProvider);
  return repo.fetchFines();
});

final finesByStudentProvider = FutureProvider.family<List<BookFine>, String>((
  ref,
  studentId,
) async {
  final school = ref.watch(currentSchoolProvider);
  if (school == null) return [];
  final repo = ref.read(libraryRepositoryProvider);
  return repo.fetchFines(studentId: studentId);
});

final pendingFinesProvider = FutureProvider<List<BookFine>>((ref) async {
  final school = ref.watch(currentSchoolProvider);
  if (school == null) return [];
  final repo = ref.read(libraryRepositoryProvider);
  return repo.fetchFines(status: FineStatus.pending);
});

// ============================================================
// DIGITAL RESOURCES
// ============================================================

final digitalResourcesProvider = FutureProvider<List<DigitalResource>>((
  ref,
) async {
  final school = ref.watch(currentSchoolProvider);
  if (school == null) return [];
  final repo = ref.read(libraryRepositoryProvider);
  return repo.fetchDigitalResources(isActive: true);
});

final digitalResourcesByBookProvider =
    FutureProvider.family<List<DigitalResource>, int>((ref, bookId) async {
      final school = ref.watch(currentSchoolProvider);
      if (school == null) return [];
      final repo = ref.read(libraryRepositoryProvider);
      return repo.fetchDigitalResources(bookId: bookId, isActive: true);
    });

// ============================================================
// DIGITAL RESOURCE ANNOTATIONS (Modern Learning Features)
// ============================================================

final digitalResourceAnnotationsProvider =
    FutureProvider.family<List<DigitalResourceAnnotation>, String>((
      ref,
      resourceId,
    ) async {
      final school = ref.watch(currentSchoolProvider);
      if (school == null) return [];
      final repo = ref.read(libraryRepositoryProvider);
      return repo.fetchAnnotations(resourceId: resourceId);
    });

final userDigitalResourceAnnotationsProvider =
    FutureProvider.family<List<DigitalResourceAnnotation>, String>((
      ref,
      resourceId,
    ) async {
      final school = ref.watch(currentSchoolProvider);
      if (school == null) return [];
      final repo = ref.read(libraryRepositoryProvider);
      return repo.fetchAnnotations(
        resourceId: resourceId,
        userId: ref.read(libraryRepositoryProvider).schoolId,
      );
    });

final publicDigitalResourceAnnotationsProvider =
    FutureProvider.family<List<DigitalResourceAnnotation>, String>((
      ref,
      resourceId,
    ) async {
      final school = ref.watch(currentSchoolProvider);
      if (school == null) return [];
      final repo = ref.read(libraryRepositoryProvider);
      return repo.fetchAnnotations(resourceId: resourceId, isPublic: true);
    });

// ============================================================
// ANNOTATION REPLIES (Collaboration Features)
// ============================================================

final annotationRepliesProvider =
    FutureProvider.family<List<AnnotationReply>, String>((
      ref,
      annotationId,
    ) async {
      final school = ref.watch(currentSchoolProvider);
      if (school == null) return [];
      final repo = ref.read(libraryRepositoryProvider);
      return repo.fetchAnnotationReplies(annotationId: annotationId);
    });

final annotationReplyProvider = FutureProvider.family<AnnotationReply?, String>(
  (ref, replyId) async {
    final school = ref.watch(currentSchoolProvider);
    if (school == null) return null;
    final repo = ref.read(libraryRepositoryProvider);
    return repo.getAnnotationReply(replyId);
  },
);

final annotationReplyLikesCountProvider = FutureProvider.family<int, String>((
  ref,
  replyId,
) async {
  final school = ref.watch(currentSchoolProvider);
  if (school == null) return 0;
  final repo = ref.read(libraryRepositoryProvider);
  return repo.getAnnotationReplyLikesCount(replyId);
});

final hasUserLikedAnnotationReplyProvider = FutureProvider.family<bool, String>(
  (ref, replyId) async {
    final school = ref.watch(currentSchoolProvider);
    if (school == null) return false;
    final repo = ref.read(libraryRepositoryProvider);
    return repo.hasUserLikedAnnotationReply(replyId);
  },
);

// State providers for real-time collaboration
final activeAnnotationRepliesProvider =
    StateProvider.family<List<AnnotationReply>, String>(
      (ref, annotationId) => [],
    );

final annotationReplyEditStateProvider =
    StateProvider.family<AnnotationReply?, String>((ref, replyId) => null);

// Notifier providers for mutation operations
final annotationReplyControllerProvider =
    Provider.family<AnnotationReplyController, String>((ref, annotationId) {
      return AnnotationReplyController(
        repository: ref.read(libraryRepositoryProvider),
        annotationId: annotationId,
      );
    });

class AnnotationReplyController {
  final LibraryRepository repository;
  final String annotationId;

  AnnotationReplyController({
    required this.repository,
    required this.annotationId,
  });

  Future<AnnotationReply> createReply({
    required String content,
    String? parentReplyId,
  }) async {
    return repository.createAnnotationReply(
      annotationId: annotationId,
      content: content,
      parentReplyId: parentReplyId,
    );
  }

  Future<AnnotationReply> updateReply({
    required String replyId,
    required String content,
  }) async {
    return repository.updateAnnotationReply(replyId: replyId, content: content);
  }

  Future<void> deleteReply(String replyId) async {
    return repository.deleteAnnotationReply(replyId);
  }

  Future<void> toggleLikeReply(String replyId) async {
    return repository.likeAnnotationReply(replyId);
  }
}

// ============================================================
// DIGITAL RESOURCE PROGRESS TRACKING
// ============================================================

final digitalResourceProgressProvider =
    FutureProvider.family<DigitalResourceProgress?, String>((
      ref,
      resourceId,
    ) async {
      final school = ref.watch(currentSchoolProvider);
      if (school == null) return null;
      final repo = ref.read(libraryRepositoryProvider);
      return repo.getProgress(resourceId);
    });

final userDigitalResourceProgressProvider =
    FutureProvider<List<DigitalResourceProgress>>((ref) async {
      final school = ref.watch(currentSchoolProvider);
      if (school == null) return [];
      final repo = ref.read(libraryRepositoryProvider);
      return repo.getUserProgress();
    });

// ============================================================
// QUIZ INTEGRATION PROVIDERS
// ============================================================

final quizQuestionsProvider = FutureProvider.family<List<QuizQuestion>, String>(
  (ref, resourceId) async {
    final school = ref.watch(currentSchoolProvider);
    if (school == null) return [];
    final repo = ref.read(libraryRepositoryProvider);
    return repo.fetchQuizQuestions(resourceId: resourceId);
  },
);

final quizQuestionsByPageProvider =
    FutureProvider.family<List<QuizQuestion>, Map<String, dynamic>>((
      ref,
      params,
    ) async {
      final school = ref.watch(currentSchoolProvider);
      if (school == null) return [];
      final repo = ref.read(libraryRepositoryProvider);
      return repo.fetchQuizQuestions(
        resourceId: params['resourceId'] as String,
        pageNumber: params['pageNumber'] as int?,
      );
    });

final quizQuestionProvider = FutureProvider.family<QuizQuestion?, String>((
  ref,
  questionId,
) async {
  final school = ref.watch(currentSchoolProvider);
  if (school == null) return null;
  final repo = ref.read(libraryRepositoryProvider);
  return repo.getQuizQuestion(questionId);
});

final quizAttemptsProvider = FutureProvider.family<List<QuizAttempt>, String>((
  ref,
  resourceId,
) async {
  final school = ref.watch(currentSchoolProvider);
  if (school == null) return [];
  final repo = ref.read(libraryRepositoryProvider);
  return repo.getUserQuizAttempts(resourceId: resourceId);
});

final latestQuizAttemptProvider = FutureProvider.family<QuizAttempt?, String>((
  ref,
  resourceId,
) async {
  final school = ref.watch(currentSchoolProvider);
  if (school == null) return null;
  final repo = ref.read(libraryRepositoryProvider);
  return repo.getLatestQuizAttempt(resourceId);
});

final activeQuizAttemptProvider = StateProvider<QuizAttempt?>((ref) => null);

final quizResultsProvider = FutureProvider.family<Map<String, dynamic>, String>(
  (ref, resourceId) async {
    final school = ref.watch(currentSchoolProvider);
    if (school == null) return {};
    final repo = ref.read(libraryRepositoryProvider);

    final attempts = await repo.getUserQuizAttempts(resourceId: resourceId);
    final latestAttempt = attempts.isNotEmpty ? attempts.first : null;

    return {
      'totalAttempts': attempts.length,
      'latestScore': latestAttempt?.score,
      'maxScore': latestAttempt?.maxScore,
      'averageScore': attempts.isNotEmpty
          ? attempts.map((a) => a.score).reduce((a, b) => a + b) /
                attempts.length
          : 0,
      'bestScore': attempts.isNotEmpty
          ? attempts.map((a) => a.score).reduce((a, b) => a > b ? a : b)
          : 0,
      'timeSpent': latestAttempt?.timeSpent ?? Duration.zero,
      'completionRate': latestAttempt?.percentage ?? 0,
    };
  },
);
