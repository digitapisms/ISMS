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

final bookCategoriesProvider =
    FutureProvider<List<BookCategory>>((ref) async {
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

final booksByCategoryProvider =
    FutureProvider.family<List<Book>, int?>((ref, categoryId) async {
  final school = ref.watch(currentSchoolProvider);
  if (school == null) return [];
  final repo = ref.read(libraryRepositoryProvider);
  return repo.fetchBooks(categoryId: categoryId, isActive: true);
});

final bookProvider = FutureProvider.family<Book?, int>((ref, bookId) async {
  final repo = ref.read(libraryRepositoryProvider);
  return repo.getBook(bookId);
});

final searchBooksProvider =
    FutureProvider.family<List<Book>, String>((ref, query) async {
  final school = ref.watch(currentSchoolProvider);
  if (school == null) return [];
  final repo = ref.read(libraryRepositoryProvider);
  return repo.fetchBooks(searchQuery: query, isActive: true);
});

// ============================================================
// BOOK COPIES
// ============================================================

final bookCopiesProvider =
    FutureProvider.family<List<BookCopy>, int?>((ref, bookId) async {
  final school = ref.watch(currentSchoolProvider);
  if (school == null) return [];
  final repo = ref.read(libraryRepositoryProvider);
  return repo.fetchBookCopies(bookId: bookId);
});

final availableBookCopiesProvider =
    FutureProvider.family<List<BookCopy>, int>((ref, bookId) async {
  final school = ref.watch(currentSchoolProvider);
  if (school == null) return [];
  final repo = ref.read(libraryRepositoryProvider);
  return repo.fetchBookCopies(
    bookId: bookId,
    status: BookCopyStatus.available,
  );
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

final issuesByStudentProvider =
    FutureProvider.family<List<BookIssue>, String>((ref, studentId) async {
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

final issueProvider =
    FutureProvider.family<BookIssue?, String>((ref, issueId) async {
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

final bookReservationsProvider =
    FutureProvider<List<BookReservation>>((ref) async {
  final school = ref.watch(currentSchoolProvider);
  if (school == null) return [];
  final repo = ref.read(libraryRepositoryProvider);
  return repo.fetchReservations();
});

final reservationsByStudentProvider =
    FutureProvider.family<List<BookReservation>, String>((ref, studentId) async {
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

final finesByStudentProvider =
    FutureProvider.family<List<BookFine>, String>((ref, studentId) async {
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

final digitalResourcesProvider =
    FutureProvider<List<DigitalResource>>((ref) async {
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

