import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/error_handler.dart';
import '../../../core/errors/provider_helpers.dart';
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
  return safeProviderOperation<List<BookCategory>>(
    ref: ref,
    operation: (schoolId) async {
      final repo = ref.read(libraryRepositoryProvider);
      return await repo.fetchCategories().timeout(const Duration(seconds: 10));
    },
    onError: () => <BookCategory>[],
    context: 'BookCategoriesProvider',
  );
});

// ============================================================
// BOOKS
// ============================================================

final booksProvider = FutureProvider<List<Book>>((ref) async {
  return safeProviderOperation<List<Book>>(
    ref: ref,
    operation: (schoolId) async {
      final repo = ref.read(libraryRepositoryProvider);
      return await repo
          .fetchBooks(isActive: true)
          .timeout(const Duration(seconds: 10));
    },
    onError: () => <Book>[],
    context: 'BooksProvider',
  );
});

final booksByCategoryProvider = FutureProvider.family<List<Book>, int?>((
  ref,
  categoryId,
) async {
  return safeProviderOperation<List<Book>>(
    ref: ref,
    operation: (schoolId) async {
      final repo = ref.read(libraryRepositoryProvider);
      return await repo
          .fetchBooks(categoryId: categoryId, isActive: true)
          .timeout(const Duration(seconds: 10));
    },
    onError: () => <Book>[],
    context: 'BooksByCategoryProvider',
  );
});

final bookProvider = FutureProvider.family<Book?, int>((ref, bookId) async {
  final correlationId = ErrorHandler.generateCorrelationId();

  try {
    final repo = ref.read(libraryRepositoryProvider);
    return await repo
        .getBook(bookId)
        .timeout(const Duration(seconds: 10), onTimeout: () => null);
  } catch (e) {
    final error = ErrorHandler.handleException(
      e,
      correlationId: correlationId,
      context: 'BookProvider',
    );
    ErrorHandler.logError(error);
    return null;
  }
});

final searchBooksProvider = FutureProvider.family<List<Book>, String>((
  ref,
  query,
) async {
  return safeProviderOperation<List<Book>>(
    ref: ref,
    operation: (schoolId) async {
      final repo = ref.read(libraryRepositoryProvider);
      return await repo
          .fetchBooks(searchQuery: query, isActive: true)
          .timeout(const Duration(seconds: 10));
    },
    onError: () => <Book>[],
    context: 'SearchBooksProvider',
  );
});

// ============================================================
// BOOK COPIES
// ============================================================

final bookCopiesProvider = FutureProvider.family<List<BookCopy>, int?>((
  ref,
  bookId,
) async {
  return safeProviderOperation<List<BookCopy>>(
    ref: ref,
    operation: (schoolId) async {
      final repo = ref.read(libraryRepositoryProvider);
      return await repo
          .fetchBookCopies(bookId: bookId)
          .timeout(const Duration(seconds: 10));
    },
    onError: () => <BookCopy>[],
    context: 'BookCopiesProvider',
  );
});

final availableBookCopiesProvider = FutureProvider.family<List<BookCopy>, int>((
  ref,
  bookId,
) async {
  return safeProviderOperation<List<BookCopy>>(
    ref: ref,
    operation: (schoolId) async {
      final repo = ref.read(libraryRepositoryProvider);
      return await repo
          .fetchBookCopies(bookId: bookId, status: BookCopyStatus.available)
          .timeout(const Duration(seconds: 10));
    },
    onError: () => <BookCopy>[],
    context: 'AvailableBookCopiesProvider',
  );
});

// ============================================================
// BOOK ISSUES
// ============================================================

final bookIssuesProvider = FutureProvider<List<BookIssue>>((ref) async {
  return safeProviderOperation<List<BookIssue>>(
    ref: ref,
    operation: (schoolId) async {
      final repo = ref.read(libraryRepositoryProvider);
      return await repo.fetchIssues().timeout(const Duration(seconds: 10));
    },
    onError: () => <BookIssue>[],
    context: 'BookIssuesProvider',
  );
});

final issuesByStudentProvider = FutureProvider.family<List<BookIssue>, String>((
  ref,
  studentId,
) async {
  return safeProviderOperation<List<BookIssue>>(
    ref: ref,
    operation: (schoolId) async {
      final repo = ref.read(libraryRepositoryProvider);
      return await repo
          .fetchIssues(studentId: studentId)
          .timeout(const Duration(seconds: 10));
    },
    onError: () => <BookIssue>[],
    context: 'IssuesByStudentProvider',
  );
});

final overdueIssuesProvider = FutureProvider<List<BookIssue>>((ref) async {
  return safeProviderOperation<List<BookIssue>>(
    ref: ref,
    operation: (schoolId) async {
      final repo = ref.read(libraryRepositoryProvider);
      return await repo
          .fetchIssues(overdue: true)
          .timeout(const Duration(seconds: 10));
    },
    onError: () => <BookIssue>[],
    context: 'OverdueIssuesProvider',
  );
});

final issueProvider = FutureProvider.family<BookIssue?, String>((
  ref,
  issueId,
) async {
  final correlationId = ErrorHandler.generateCorrelationId();

  try {
    final issues = await ref.read(bookIssuesProvider.future);
    return issues.firstWhere((i) => i.id == issueId);
  } catch (e) {
    final error = ErrorHandler.handleException(
      e,
      correlationId: correlationId,
      context: 'IssueProvider',
    );
    ErrorHandler.logError(error);
    return null;
  }
});

// ============================================================
// BOOK RETURNS
// ============================================================

final bookReturnsProvider = FutureProvider<List<BookReturn>>((ref) async {
  return safeProviderOperation<List<BookReturn>>(
    ref: ref,
    operation: (schoolId) async {
      final repo = ref.read(libraryRepositoryProvider);
      return await repo.fetchReturns().timeout(const Duration(seconds: 10));
    },
    onError: () => <BookReturn>[],
    context: 'BookReturnsProvider',
  );
});

// ============================================================
// BOOK RESERVATIONS
// ============================================================

final bookReservationsProvider = FutureProvider<List<BookReservation>>((
  ref,
) async {
  return safeProviderOperation<List<BookReservation>>(
    ref: ref,
    operation: (schoolId) async {
      final repo = ref.read(libraryRepositoryProvider);
      return await repo.fetchReservations().timeout(
        const Duration(seconds: 10),
      );
    },
    onError: () => <BookReservation>[],
    context: 'BookReservationsProvider',
  );
});

final reservationsByStudentProvider =
    FutureProvider.family<List<BookReservation>, String>((
      ref,
      studentId,
    ) async {
      return safeProviderOperation<List<BookReservation>>(
        ref: ref,
        operation: (schoolId) async {
          final repo = ref.read(libraryRepositoryProvider);
          return await repo
              .fetchReservations(studentId: studentId)
              .timeout(const Duration(seconds: 10));
        },
        onError: () => <BookReservation>[],
        context: 'ReservationsByStudentProvider',
      );
    });

// ============================================================
// BOOK FINES
// ============================================================

final bookFinesProvider = FutureProvider<List<BookFine>>((ref) async {
  return safeProviderOperation<List<BookFine>>(
    ref: ref,
    operation: (schoolId) async {
      final repo = ref.read(libraryRepositoryProvider);
      return await repo.fetchFines().timeout(const Duration(seconds: 10));
    },
    onError: () => <BookFine>[],
    context: 'BookFinesProvider',
  );
});

final finesByStudentProvider = FutureProvider.family<List<BookFine>, String>((
  ref,
  studentId,
) async {
  return safeProviderOperation<List<BookFine>>(
    ref: ref,
    operation: (schoolId) async {
      final repo = ref.read(libraryRepositoryProvider);
      return await repo
          .fetchFines(studentId: studentId)
          .timeout(const Duration(seconds: 10));
    },
    onError: () => <BookFine>[],
    context: 'FinesByStudentProvider',
  );
});

final pendingFinesProvider = FutureProvider<List<BookFine>>((ref) async {
  return safeProviderOperation<List<BookFine>>(
    ref: ref,
    operation: (schoolId) async {
      final repo = ref.read(libraryRepositoryProvider);
      return await repo
          .fetchFines(status: FineStatus.pending)
          .timeout(const Duration(seconds: 10));
    },
    onError: () => <BookFine>[],
    context: 'PendingFinesProvider',
  );
});

// ============================================================
// DIGITAL RESOURCES
// ============================================================

final digitalResourcesProvider = FutureProvider<List<DigitalResource>>((
  ref,
) async {
  return safeProviderOperation<List<DigitalResource>>(
    ref: ref,
    operation: (schoolId) async {
      final repo = ref.read(libraryRepositoryProvider);
      return await repo
          .fetchDigitalResources(isActive: true)
          .timeout(const Duration(seconds: 10));
    },
    onError: () => <DigitalResource>[],
    context: 'DigitalResourcesProvider',
  );
});

final digitalResourcesByBookProvider =
    FutureProvider.family<List<DigitalResource>, int>((ref, bookId) async {
      return safeProviderOperation<List<DigitalResource>>(
        ref: ref,
        operation: (schoolId) async {
          final repo = ref.read(libraryRepositoryProvider);
          return await repo
              .fetchDigitalResources(bookId: bookId, isActive: true)
              .timeout(const Duration(seconds: 10));
        },
        onError: () => <DigitalResource>[],
        context: 'DigitalResourcesByBookProvider',
      );
    });

// ============================================================
// DIGITAL RESOURCE ANNOTATIONS (Modern Learning Features)
// ============================================================

final digitalResourceAnnotationsProvider =
    FutureProvider.family<List<DigitalResourceAnnotation>, String>((
      ref,
      resourceId,
    ) async {
      return safeProviderOperation<List<DigitalResourceAnnotation>>(
        ref: ref,
        operation: (schoolId) async {
          final repo = ref.read(libraryRepositoryProvider);
          return await repo
              .fetchAnnotations(resourceId: resourceId)
              .timeout(const Duration(seconds: 10));
        },
        onError: () => <DigitalResourceAnnotation>[],
        context: 'DigitalResourceAnnotationsProvider',
      );
    });

final userDigitalResourceAnnotationsProvider =
    FutureProvider.family<List<DigitalResourceAnnotation>, String>((
      ref,
      resourceId,
    ) async {
      return safeProviderOperation<List<DigitalResourceAnnotation>>(
        ref: ref,
        operation: (schoolId) async {
          final repo = ref.read(libraryRepositoryProvider);
          return await repo
              .fetchAnnotations(
                resourceId: resourceId,
                userId: schoolId, // Use schoolId as userId fallback
              )
              .timeout(const Duration(seconds: 10));
        },
        onError: () => <DigitalResourceAnnotation>[],
        context: 'UserDigitalResourceAnnotationsProvider',
      );
    });

final publicDigitalResourceAnnotationsProvider =
    FutureProvider.family<List<DigitalResourceAnnotation>, String>((
      ref,
      resourceId,
    ) async {
      return safeProviderOperation<List<DigitalResourceAnnotation>>(
        ref: ref,
        operation: (schoolId) async {
          final repo = ref.read(libraryRepositoryProvider);
          return await repo
              .fetchAnnotations(resourceId: resourceId, isPublic: true)
              .timeout(const Duration(seconds: 10));
        },
        onError: () => <DigitalResourceAnnotation>[],
        context: 'PublicDigitalResourceAnnotationsProvider',
      );
    });

// ============================================================
// ANNOTATION REPLIES (Collaboration Features)
// ============================================================

final annotationRepliesProvider =
    FutureProvider.family<List<AnnotationReply>, String>((
      ref,
      annotationId,
    ) async {
      return safeProviderOperation<List<AnnotationReply>>(
        ref: ref,
        operation: (schoolId) async {
          final repo = ref.read(libraryRepositoryProvider);
          return await repo
              .fetchAnnotationReplies(annotationId: annotationId)
              .timeout(const Duration(seconds: 10));
        },
        onError: () => <AnnotationReply>[],
        context: 'AnnotationRepliesProvider',
      );
    });

final annotationReplyProvider = FutureProvider.family<AnnotationReply?, String>(
  (ref, replyId) async {
    final correlationId = ErrorHandler.generateCorrelationId();

    try {
      final schoolId = await getSchoolIdSafely(ref);
      if (schoolId == null) return null;

      final repo = ref.read(libraryRepositoryProvider);
      return await repo
          .getAnnotationReply(replyId)
          .timeout(const Duration(seconds: 10), onTimeout: () => null);
    } catch (e) {
      final error = ErrorHandler.handleException(
        e,
        correlationId: correlationId,
        context: 'AnnotationReplyProvider',
      );
      ErrorHandler.logError(error);
      return null;
    }
  },
);

final annotationReplyLikesCountProvider = FutureProvider.family<int, String>((
  ref,
  replyId,
) async {
  final correlationId = ErrorHandler.generateCorrelationId();

  try {
    final schoolId = await getSchoolIdSafely(ref);
    if (schoolId == null) return 0;

    final repo = ref.read(libraryRepositoryProvider);
    return await repo
        .getAnnotationReplyLikesCount(replyId)
        .timeout(const Duration(seconds: 10), onTimeout: () => 0);
  } catch (e) {
    final error = ErrorHandler.handleException(
      e,
      correlationId: correlationId,
      context: 'AnnotationReplyLikesCountProvider',
    );
    ErrorHandler.logError(error);
    return 0;
  }
});

final hasUserLikedAnnotationReplyProvider = FutureProvider.family<bool, String>(
  (ref, replyId) async {
    final correlationId = ErrorHandler.generateCorrelationId();

    try {
      final schoolId = await getSchoolIdSafely(ref);
      if (schoolId == null) return false;

      final repo = ref.read(libraryRepositoryProvider);
      return await repo
          .hasUserLikedAnnotationReply(replyId)
          .timeout(const Duration(seconds: 10), onTimeout: () => false);
    } catch (e) {
      final error = ErrorHandler.handleException(
        e,
        correlationId: correlationId,
        context: 'HasUserLikedAnnotationReplyProvider',
      );
      ErrorHandler.logError(error);
      return false;
    }
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
      final correlationId = ErrorHandler.generateCorrelationId();

      try {
        final schoolId = await getSchoolIdSafely(ref);
        if (schoolId == null) return null;

        final repo = ref.read(libraryRepositoryProvider);
        return await repo
            .getProgress(resourceId)
            .timeout(const Duration(seconds: 10), onTimeout: () => null);
      } catch (e) {
        final error = ErrorHandler.handleException(
          e,
          correlationId: correlationId,
          context: 'DigitalResourceProgressProvider',
        );
        ErrorHandler.logError(error);
        return null;
      }
    });

final userDigitalResourceProgressProvider =
    FutureProvider<List<DigitalResourceProgress>>((ref) async {
      return safeProviderOperation<List<DigitalResourceProgress>>(
        ref: ref,
        operation: (schoolId) async {
          final repo = ref.read(libraryRepositoryProvider);
          return await repo.getUserProgress().timeout(
            const Duration(seconds: 10),
          );
        },
        onError: () => <DigitalResourceProgress>[],
        context: 'UserDigitalResourceProgressProvider',
      );
    });

// ============================================================
// QUIZ INTEGRATION PROVIDERS
// ============================================================

final quizQuestionsProvider = FutureProvider.family<List<QuizQuestion>, String>(
  (ref, resourceId) async {
    return safeProviderOperation<List<QuizQuestion>>(
      ref: ref,
      operation: (schoolId) async {
        final repo = ref.read(libraryRepositoryProvider);
        return await repo
            .fetchQuizQuestions(resourceId: resourceId)
            .timeout(const Duration(seconds: 10));
      },
      onError: () => <QuizQuestion>[],
      context: 'QuizQuestionsProvider',
    );
  },
);

final quizQuestionsByPageProvider =
    FutureProvider.family<List<QuizQuestion>, Map<String, dynamic>>((
      ref,
      params,
    ) async {
      return safeProviderOperation<List<QuizQuestion>>(
        ref: ref,
        operation: (schoolId) async {
          final repo = ref.read(libraryRepositoryProvider);
          return await repo
              .fetchQuizQuestions(
                resourceId: params['resourceId'] as String,
                pageNumber: params['pageNumber'] as int?,
              )
              .timeout(const Duration(seconds: 10));
        },
        onError: () => <QuizQuestion>[],
        context: 'QuizQuestionsByPageProvider',
      );
    });

final quizQuestionProvider = FutureProvider.family<QuizQuestion?, String>((
  ref,
  questionId,
) async {
  final correlationId = ErrorHandler.generateCorrelationId();

  try {
    final schoolId = await getSchoolIdSafely(ref);
    if (schoolId == null) return null;

    final repo = ref.read(libraryRepositoryProvider);
    return await repo
        .getQuizQuestion(questionId)
        .timeout(const Duration(seconds: 10), onTimeout: () => null);
  } catch (e) {
    final error = ErrorHandler.handleException(
      e,
      correlationId: correlationId,
      context: 'QuizQuestionProvider',
    );
    ErrorHandler.logError(error);
    return null;
  }
});

final quizAttemptsProvider = FutureProvider.family<List<QuizAttempt>, String>((
  ref,
  resourceId,
) async {
  return safeProviderOperation<List<QuizAttempt>>(
    ref: ref,
    operation: (schoolId) async {
      final repo = ref.read(libraryRepositoryProvider);
      return await repo
          .getUserQuizAttempts(resourceId: resourceId)
          .timeout(const Duration(seconds: 10));
    },
    onError: () => <QuizAttempt>[],
    context: 'QuizAttemptsProvider',
  );
});

final latestQuizAttemptProvider = FutureProvider.family<QuizAttempt?, String>((
  ref,
  resourceId,
) async {
  final correlationId = ErrorHandler.generateCorrelationId();

  try {
    final schoolId = await getSchoolIdSafely(ref);
    if (schoolId == null) return null;

    final repo = ref.read(libraryRepositoryProvider);
    return await repo
        .getLatestQuizAttempt(resourceId)
        .timeout(const Duration(seconds: 10), onTimeout: () => null);
  } catch (e) {
    final error = ErrorHandler.handleException(
      e,
      correlationId: correlationId,
      context: 'LatestQuizAttemptProvider',
    );
    ErrorHandler.logError(error);
    return null;
  }
});

final activeQuizAttemptProvider = StateProvider<QuizAttempt?>((ref) => null);

final quizResultsProvider = FutureProvider.family<Map<String, dynamic>, String>(
  (ref, resourceId) async {
    return safeProviderOperation<Map<String, dynamic>>(
      ref: ref,
      operation: (schoolId) async {
        final repo = ref.read(libraryRepositoryProvider);

        final attempts = await repo
            .getUserQuizAttempts(resourceId: resourceId)
            .timeout(const Duration(seconds: 10));
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
      onError: () => <String, dynamic>{},
      context: 'QuizResultsProvider',
    );
  },
);
