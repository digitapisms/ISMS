import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/network/supabase_client.dart';
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

class LibraryRepository {
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
        'School context is required for this action. Please ensure you are signed in to a school tenant.',
      );
    }
    return id;
  }

  Map<String, dynamic> _withSchoolId(Map<String, dynamic> data) {
    final id = _schoolId;
    if (id == null) return data;
    return {...data, 'school_id': id};
  }

  // ============================================================
  // BOOK CATEGORIES
  // ============================================================

  Future<BookCategory> createCategory(BookCategory category) async {
    _requireSchoolId();
    final response = await _client
        .from('book_categories')
        .insert(_withSchoolId(category.toMap()))
        .select()
        .single();
    return BookCategory.fromMap(response);
  }

  Future<List<BookCategory>> fetchCategories() async {
    final schoolId = _requireSchoolId();
    final response = await _client
        .from('book_categories')
        .select()
        .eq('school_id', schoolId)
        .eq('is_active', true)
        .order('name');
    return (response as List)
        .map((e) => BookCategory.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  Future<BookCategory> updateCategory(BookCategory category) async {
    final response = await _client
        .from('book_categories')
        .update(category.toMap())
        .eq('id', category.id)
        .select()
        .single();
    return BookCategory.fromMap(response);
  }

  Future<void> deleteCategory(int id) async {
    await _client.from('book_categories').delete().eq('id', id);
  }

  // ============================================================
  // BOOKS
  // ============================================================

  Future<Book> createBook(Book book) async {
    _requireSchoolId();
    final response = await _client
        .from('books')
        .insert(_withSchoolId(book.toMap()))
        .select()
        .single();
    return Book.fromMap(response);
  }

  Future<List<Book>> fetchBooks({
    int? categoryId,
    String? searchQuery,
    BookType? bookType,
    bool? isActive,
  }) async {
    final schoolId = _requireSchoolId();
    var query = _client.from('books').select().eq('school_id', schoolId);

    if (categoryId != null) {
      query = query.eq('category_id', categoryId);
    }
    if (searchQuery != null && searchQuery.isNotEmpty) {
      query = query.or(
        'title.ilike.%$searchQuery%,author.ilike.%$searchQuery%,isbn.ilike.%$searchQuery%',
      );
    }
    if (bookType != null) {
      query = query.eq('book_type', bookType.dbValue);
    }
    if (isActive != null) {
      query = query.eq('is_active', isActive);
    }

    final response = await query.order('title');
    return (response as List)
        .map((e) => Book.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  Future<Book?> getBook(int id) async {
    final response = await _client
        .from('books')
        .select()
        .eq('id', id)
        .maybeSingle();
    if (response == null) return null;
    return Book.fromMap(response);
  }

  Future<Book> updateBook(Book book) async {
    final response = await _client
        .from('books')
        .update(book.toMap())
        .eq('id', book.id)
        .select()
        .single();
    return Book.fromMap(response);
  }

  Future<void> deleteBook(int id) async {
    await _client.from('books').delete().eq('id', id);
  }

  // ============================================================
  // BOOK COPIES
  // ============================================================

  Future<BookCopy> createBookCopy(BookCopy copy) async {
    _requireSchoolId();
    final response = await _client
        .from('book_copies')
        .insert(_withSchoolId(copy.toMap()))
        .select()
        .single();
    return BookCopy.fromMap(response);
  }

  Future<List<BookCopy>> fetchBookCopies({
    int? bookId,
    BookCopyStatus? status,
  }) async {
    final schoolId = _requireSchoolId();
    var query = _client.from('book_copies').select().eq('school_id', schoolId);

    if (bookId != null) {
      query = query.eq('book_id', bookId);
    }
    if (status != null) {
      query = query.eq('status', status.dbValue);
    }

    final response = await query.order('copy_number');
    return (response as List)
        .map((e) => BookCopy.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  Future<BookCopy> updateBookCopy(BookCopy copy) async {
    final response = await _client
        .from('book_copies')
        .update(copy.toMap())
        .eq('id', copy.id)
        .select()
        .single();
    return BookCopy.fromMap(response);
  }

  Future<void> deleteBookCopy(int id) async {
    await _client.from('book_copies').delete().eq('id', id);
  }

  // ============================================================
  // BOOK ISSUES
  // ============================================================

  Future<BookIssue> issueBook({
    required int bookId,
    int? bookCopyId,
    String? studentId,
    String? staffId,
    required DateTime dueDate,
    int maxRenewals = 1,
    String? notes,
  }) async {
    final schoolId = _requireSchoolId();
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    // Get available copy if not specified
    int? copyId = bookCopyId;
    if (copyId == null) {
      final copies = await fetchBookCopies(
        bookId: bookId,
        status: BookCopyStatus.available,
      );
      if (copies.isEmpty) {
        throw Exception('No available copies of this book');
      }
      copyId = copies.first.id;
    }

    // Update copy status
    await _client
        .from('book_copies')
        .update({'status': 'issued'})
        .eq('id', copyId);

    final issue = BookIssue(
      id: '', // Will be generated by DB
      schoolId: schoolId,
      bookId: bookId,
      bookCopyId: copyId,
      studentId: studentId,
      staffId: staffId,
      issuedBy: userId,
      issueDate: DateTime.now(),
      dueDate: dueDate,
      maxRenewals: maxRenewals,
      notes: notes,
    );

    final response = await _client
        .from('book_issues')
        .insert(_withSchoolId(issue.toMap()))
        .select()
        .single();
    return BookIssue.fromMap(response);
  }

  Future<List<BookIssue>> fetchIssues({
    int? bookId,
    String? studentId,
    String? staffId,
    IssueStatus? status,
    bool? overdue,
  }) async {
    final schoolId = _requireSchoolId();
    var query = _client.from('book_issues').select().eq('school_id', schoolId);

    if (bookId != null) {
      query = query.eq('book_id', bookId);
    }
    if (studentId != null) {
      query = query.eq('student_id', studentId);
    }
    if (staffId != null) {
      query = query.eq('staff_id', staffId);
    }
    if (status != null) {
      query = query.eq('status', status.dbValue);
    }
    if (overdue == true) {
      query = query
          .eq('status', 'issued')
          .lt('due_date', DateTime.now().toIso8601String().split('T')[0]);
    }

    final response = await query.order('issue_date', ascending: false);
    return (response as List)
        .map((e) => BookIssue.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  Future<BookIssue> renewIssue(String issueId, DateTime newDueDate) async {
    final current = await _client
        .from('book_issues')
        .select()
        .eq('id', issueId)
        .single();
    final issue = BookIssue.fromMap(current);

    if (!issue.canRenew) {
      throw Exception('This book cannot be renewed');
    }

    final response = await _client
        .from('book_issues')
        .update({
          'due_date': newDueDate.toIso8601String().split('T')[0],
          'renewal_count': issue.renewalCount + 1,
        })
        .eq('id', issueId)
        .select()
        .single();
    return BookIssue.fromMap(response);
  }

  // ============================================================
  // BOOK RETURNS
  // ============================================================

  Future<BookReturn> returnBook({
    required String issueId,
    BookCondition? conditionOnReturn,
    String? damageNotes,
    String? notes,
  }) async {
    final schoolId = _requireSchoolId();
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    // Get issue details
    final issueData = await _client
        .from('book_issues')
        .select()
        .eq('id', issueId)
        .single();
    final issue = BookIssue.fromMap(issueData);

    if (issue.status != IssueStatus.issued) {
      throw Exception('This book is already returned');
    }

    // Calculate overdue days and fine
    final daysOverdue = issue.isOverdue ? issue.daysOverdue : 0;
    final fineAmount = daysOverdue * 5.0; // Default 5 per day

    // Create return record
    final returnRecord = BookReturn(
      id: '', // Will be generated by DB
      schoolId: schoolId,
      issueId: issueId,
      returnedBy: userId,
      returnDate: DateTime.now(),
      conditionOnReturn: conditionOnReturn ?? BookCondition.good,
      daysOverdue: daysOverdue,
      fineAmount: fineAmount,
      damageNotes: damageNotes,
      notes: notes,
    );

    final returnResponse = await _client
        .from('book_returns')
        .insert(_withSchoolId(returnRecord.toMap()))
        .select()
        .single();

    // Update issue status
    await _client
        .from('book_issues')
        .update({
          'status': 'returned',
          'return_date': DateTime.now().toIso8601String().split('T')[0],
        })
        .eq('id', issueId);

    // Update copy status
    if (issue.bookCopyId != null) {
      await _client
          .from('book_copies')
          .update({'status': 'available'})
          .eq('id', issue.bookCopyId!);
    }

    // Create fine record if applicable
    if (fineAmount > 0) {
      await _client.from('book_fines').insert({
        'school_id': schoolId,
        'issue_id': issueId,
        'return_id': returnResponse['id'],
        'student_id': issue.studentId,
        'staff_id': issue.staffId,
        'fine_type': 'overdue',
        'amount': fineAmount,
        'days_overdue': daysOverdue,
        'status': 'pending',
      });
    }

    return BookReturn.fromMap(returnResponse);
  }

  Future<List<BookReturn>> fetchReturns({
    String? issueId,
    String? studentId,
    String? staffId,
  }) async {
    final schoolId = _requireSchoolId();
    var query = _client.from('book_returns').select().eq('school_id', schoolId);

    if (issueId != null) {
      query = query.eq('issue_id', issueId);
    }

    final response = await query.order('return_date', ascending: false);
    return (response as List)
        .map((e) => BookReturn.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  // ============================================================
  // BOOK RESERVATIONS
  // ============================================================

  Future<BookReservation> createReservation({
    required int bookId,
    String? studentId,
    String? staffId,
    DateTime? expiryDate,
  }) async {
    final schoolId = _requireSchoolId();
    final reservation = BookReservation(
      id: '', // Will be generated by DB
      schoolId: schoolId,
      bookId: bookId,
      studentId: studentId,
      staffId: staffId,
      reservationDate: DateTime.now(),
      expiryDate: expiryDate,
    );

    final response = await _client
        .from('book_reservations')
        .insert(_withSchoolId(reservation.toMap()))
        .select()
        .single();
    return BookReservation.fromMap(response);
  }

  Future<List<BookReservation>> fetchReservations({
    int? bookId,
    String? studentId,
    String? staffId,
    ReservationStatus? status,
  }) async {
    final schoolId = _requireSchoolId();
    var query = _client
        .from('book_reservations')
        .select()
        .eq('school_id', schoolId);

    if (bookId != null) {
      query = query.eq('book_id', bookId);
    }
    if (studentId != null) {
      query = query.eq('student_id', studentId);
    }
    if (staffId != null) {
      query = query.eq('staff_id', staffId);
    }
    if (status != null) {
      query = query.eq('status', status.dbValue);
    }

    final response = await query.order('reservation_date', ascending: false);
    return (response as List)
        .map((e) => BookReservation.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> cancelReservation(String id) async {
    await _client
        .from('book_reservations')
        .update({'status': 'cancelled'})
        .eq('id', id);
  }

  // ============================================================
  // BOOK FINES
  // ============================================================

  Future<List<BookFine>> fetchFines({
    String? issueId,
    String? studentId,
    String? staffId,
    FineStatus? status,
  }) async {
    final schoolId = _requireSchoolId();
    var query = _client.from('book_fines').select().eq('school_id', schoolId);

    if (issueId != null) {
      query = query.eq('issue_id', issueId);
    }
    if (studentId != null) {
      query = query.eq('student_id', studentId);
    }
    if (staffId != null) {
      query = query.eq('staff_id', staffId);
    }
    if (status != null) {
      query = query.eq('status', status.dbValue);
    }

    final response = await query.order('created_at', ascending: false);
    return (response as List)
        .map((e) => BookFine.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  Future<BookFine> payFine(String fineId, String paymentMethod) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    final response = await _client
        .from('book_fines')
        .update({
          'status': 'paid',
          'paid_at': DateTime.now().toIso8601String(),
          'paid_by': userId,
          'payment_method': paymentMethod,
        })
        .eq('id', fineId)
        .select()
        .single();
    return BookFine.fromMap(response);
  }

  Future<BookFine> waiveFine(String fineId, String reason) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    final response = await _client
        .from('book_fines')
        .update({
          'status': 'waived',
          'waived_at': DateTime.now().toIso8601String(),
          'waived_by': userId,
          'waiver_reason': reason,
        })
        .eq('id', fineId)
        .select()
        .single();
    return BookFine.fromMap(response);
  }

  // ============================================================
  // DIGITAL RESOURCES
  // ============================================================

  Future<DigitalResource> createDigitalResource({
    required String title,
    required String filePath,
    required DigitalResourceType resourceType,
    int? bookId,
    String? description,
    AccessLevel accessLevel = AccessLevel.public,
    bool downloadAllowed = true,
    int? maxDownloads,
  }) async {
    final schoolId = _requireSchoolId();
    final userId = _client.auth.currentUser?.id;

    final resource = DigitalResource(
      id: '', // Will be generated by DB
      schoolId: schoolId,
      bookId: bookId,
      title: title,
      resourceType: resourceType,
      filePath: filePath,
      accessLevel: accessLevel,
      downloadAllowed: downloadAllowed,
      maxDownloads: maxDownloads,
      description: description,
      uploadedBy: userId,
    );

    final response = await _client
        .from('digital_resources')
        .insert(_withSchoolId(resource.toMap()))
        .select()
        .single();
    return DigitalResource.fromMap(response);
  }

  Future<String> uploadDigitalResourceFile({
    required String fileName,
    required Uint8List fileBytes,
    String? folder,
  }) async {
    final schoolId = _requireSchoolId();
    final path = folder != null
        ? 'library/$schoolId/$folder/$fileName'
        : 'library/$schoolId/$fileName';

    await _client.storage
        .from('library')
        .uploadBinary(
          path,
          fileBytes,
          fileOptions: const FileOptions(upsert: true),
        );

    final url = _client.storage.from('library').getPublicUrl(path);
    return url;
  }

  Future<List<DigitalResource>> fetchDigitalResources({
    int? bookId,
    DigitalResourceType? resourceType,
    AccessLevel? accessLevel,
    bool? isActive,
  }) async {
    final schoolId = _requireSchoolId();
    var query = _client
        .from('digital_resources')
        .select()
        .eq('school_id', schoolId);

    if (bookId != null) {
      query = query.eq('book_id', bookId);
    }
    if (resourceType != null) {
      query = query.eq('resource_type', resourceType.dbValue);
    }
    if (accessLevel != null) {
      query = query.eq('access_level', accessLevel.dbValue);
    }
    if (isActive != null) {
      query = query.eq('is_active', isActive);
    }

    final response = await query.order('created_at', ascending: false);
    return (response as List)
        .map((e) => DigitalResource.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> recordDigitalResourceAccess({
    required String resourceId,
    required String accessType,
  }) async {
    final schoolId = _requireSchoolId();
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    await _client.from('digital_resource_access').insert({
      'school_id': schoolId,
      'resource_id': resourceId,
      'user_id': userId,
      'access_type': accessType,
    });

    if (accessType == 'download') {
      final current = await _client
          .from('digital_resources')
          .select('current_downloads')
          .eq('id', resourceId)
          .single();
      final currentCount = (current['current_downloads'] as int?) ?? 0;
      await _client
          .from('digital_resources')
          .update({'current_downloads': currentCount + 1})
          .eq('id', resourceId);
    }
  }

  Future<void> deleteDigitalResource(String id) async {
    await _client.from('digital_resources').delete().eq('id', id);
  }

  // ============================================================
  // DIGITAL RESOURCE ANNOTATIONS (Modern Learning Features)
  // ============================================================

  Future<DigitalResourceAnnotation> createAnnotation({
    required String resourceId,
    required AnnotationType annotationType,
    required String content,
    int? pageNumber,
    double? positionX,
    double? positionY,
    String? highlightColor,
    bool isPublic = false,
  }) async {
    final schoolId = _requireSchoolId();
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('User must be authenticated to create annotations');
    }

    final annotation = DigitalResourceAnnotation(
      id: 'anno_\${DateTime.now().millisecondsSinceEpoch}',
      schoolId: schoolId,
      resourceId: resourceId,
      userId: userId,
      annotationType: annotationType,
      content: content,
      pageNumber: pageNumber,
      positionX: positionX,
      positionY: positionY,
      highlightColor: highlightColor,
      isPublic: isPublic,
      createdAt: DateTime.now(),
    );

    final response = await _client
        .from('digital_resource_annotations')
        .insert(_withSchoolId(annotation.toMap()))
        .select()
        .single();
    return DigitalResourceAnnotation.fromMap(response);
  }

  Future<List<DigitalResourceAnnotation>> fetchAnnotations({
    required String resourceId,
    AnnotationType? annotationType,
    String? userId,
    bool? isPublic,
  }) async {
    final schoolId = _requireSchoolId();
    var query = _client
        .from('digital_resource_annotations')
        .select()
        .eq('school_id', schoolId)
        .eq('resource_id', resourceId);

    if (annotationType != null) {
      query = query.eq('annotation_type', annotationType.dbValue);
    }
    if (userId != null) {
      query = query.eq('user_id', userId);
    }
    if (isPublic != null) {
      query = query.eq('is_public', isPublic);
    }

    final response = await query.order('created_at', ascending: false);
    return (response as List)
        .map(
          (e) => DigitalResourceAnnotation.fromMap(e as Map<String, dynamic>),
        )
        .toList();
  }

  Future<void> updateAnnotation({
    required String annotationId,
    String? content,
    bool? isPublic,
  }) async {
    final updates = <String, dynamic>{
      'updated_at': DateTime.now().toIso8601String(),
    };
    if (content != null) updates['content'] = content;
    if (isPublic != null) updates['is_public'] = isPublic;

    await _client
        .from('digital_resource_annotations')
        .update(updates)
        .eq('id', annotationId);
  }

  Future<void> deleteAnnotation(String annotationId) async {
    await _client
        .from('digital_resource_annotations')
        .delete()
        .eq('id', annotationId);
  }

  Future<void> likeAnnotation(String annotationId) async {
    final schoolId = _requireSchoolId();
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    // Record the like
    await _client.from('annotation_likes').insert({
      'school_id': schoolId,
      'annotation_id': annotationId,
      'user_id': userId,
      'created_at': DateTime.now().toIso8601String(),
    });

    // Update the annotation's like count
    final current = await _client
        .from('digital_resource_annotations')
        .select('likes_count')
        .eq('id', annotationId)
        .single();
    final currentCount = (current['likes_count'] as int?) ?? 0;
    await _client
        .from('digital_resource_annotations')
        .update({'likes_count': currentCount + 1})
        .eq('id', annotationId);
  }

  // ============================================================
  // DIGITAL RESOURCE PROGRESS TRACKING
  // ============================================================

  Future<DigitalResourceProgress> updateProgress({
    required String resourceId,
    int? currentPage,
    double? percentageCompleted,
    int? timeSpentSeconds,
    String? lastPosition,
    List<int>? bookmarkedPages,
  }) async {
    final schoolId = _requireSchoolId();
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('User must be authenticated to track progress');
    }

    // Check if progress record exists
    final existing = await _client
        .from('digital_resource_progress')
        .select()
        .eq('school_id', schoolId)
        .eq('resource_id', resourceId)
        .eq('user_id', userId)
        .maybeSingle();

    final now = DateTime.now();
    DigitalResourceProgress progress;

    if (existing == null) {
      // Create new progress record
      progress = DigitalResourceProgress(
        id: 'progress_\${DateTime.now().millisecondsSinceEpoch}',
        schoolId: schoolId,
        resourceId: resourceId,
        userId: userId,
        currentPage: currentPage ?? 1,
        percentageCompleted: percentageCompleted ?? 0.0,
        timeSpentSeconds: timeSpentSeconds ?? 0,
        lastPosition: lastPosition,
        bookmarkedPages: bookmarkedPages ?? [],
        lastAccessedAt: now,
        createdAt: now,
      );
    } else {
      // Update existing progress record
      progress = DigitalResourceProgress.fromMap(existing);
      final updates = <String, dynamic>{
        'updated_at': now.toIso8601String(),
        'last_accessed_at': now.toIso8601String(),
      };

      if (currentPage != null) updates['current_page'] = currentPage;
      if (percentageCompleted != null) {
        updates['percentage_completed'] = percentageCompleted;
      }
      if (timeSpentSeconds != null) {
        updates['time_spent_seconds'] =
            (progress.timeSpentSeconds + timeSpentSeconds);
      }
      if (lastPosition != null) updates['last_position'] = lastPosition;
      if (bookmarkedPages != null) {
        updates['bookmarked_pages'] = bookmarkedPages;
      }

      // Mark as completed if percentage reaches 95%
      if (percentageCompleted != null && percentageCompleted >= 95.0) {
        updates['completed_at'] = now.toIso8601String();
      }

      await _client
          .from('digital_resource_progress')
          .update(updates)
          .eq('id', progress.id);

      // Re-fetch the updated progress
      final updated = await _client
          .from('digital_resource_progress')
          .select()
          .eq('id', progress.id)
          .single();
      progress = DigitalResourceProgress.fromMap(updated);
    }

    return progress;
  }

  Future<DigitalResourceProgress?> getProgress(String resourceId) async {
    final schoolId = _requireSchoolId();
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return null;

    final response = await _client
        .from('digital_resource_progress')
        .select()
        .eq('school_id', schoolId)
        .eq('resource_id', resourceId)
        .eq('user_id', userId)
        .maybeSingle();

    if (response == null) return null;
    return DigitalResourceProgress.fromMap(response);
  }

  Future<List<DigitalResourceProgress>> getUserProgress() async {
    final schoolId = _requireSchoolId();
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];

    final response = await _client
        .from('digital_resource_progress')
        .select()
        .eq('school_id', schoolId)
        .eq('user_id', userId)
        .order('last_accessed_at', ascending: false);

    return (response as List)
        .map((e) => DigitalResourceProgress.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> updateAnnotationCounts(String resourceId) async {
    final schoolId = _requireSchoolId();
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    // Get counts of notes and highlights
    final annotations = await fetchAnnotations(
      resourceId: resourceId,
      userId: userId,
    );

    final notesCount = annotations
        .where((a) => a.annotationType == AnnotationType.note)
        .length;
    final highlightsCount = annotations
        .where((a) => a.annotationType == AnnotationType.highlight)
        .length;

    // Update progress record
    final progress = await getProgress(resourceId);
    if (progress != null) {
      await _client
          .from('digital_resource_progress')
          .update({
            'notes_count': notesCount,
            'highlights_count': highlightsCount,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', progress.id);
    }
  }

  // ============================================================
  // ANNOTATION REPLIES
  // ============================================================

  Future<AnnotationReply> createAnnotationReply({
    required String annotationId,
    required String content,
    String? parentReplyId,
  }) async {
    final schoolId = _requireSchoolId();
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw Exception(
        'User must be authenticated to create annotation replies',
      );
    }

    final reply = AnnotationReply(
      id: 'reply_\${DateTime.now().millisecondsSinceEpoch}',
      schoolId: schoolId,
      annotationId: annotationId,
      userId: userId,
      content: content,
      parentReplyId: parentReplyId,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final response = await _client
        .from('annotation_replies')
        .insert(reply.toMap())
        .select()
        .single();

    return AnnotationReply.fromMap(response);
  }

  Future<AnnotationReply> updateAnnotationReply({
    required String replyId,
    required String content,
  }) async {
    final schoolId = _requireSchoolId();
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw Exception(
        'User must be authenticated to update annotation replies',
      );
    }

    final updates = {
      'content': content,
      'is_edited': true,
      'updated_at': DateTime.now().toIso8601String(),
    };

    final response = await _client
        .from('annotation_replies')
        .update(updates)
        .eq('id', replyId)
        .eq('school_id', schoolId)
        .eq('user_id', userId)
        .select()
        .single();

    return AnnotationReply.fromMap(response);
  }

  Future<void> deleteAnnotationReply(String replyId) async {
    final schoolId = _requireSchoolId();
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw Exception(
        'User must be authenticated to delete annotation replies',
      );
    }

    await _client
        .from('annotation_replies')
        .delete()
        .eq('id', replyId)
        .eq('school_id', schoolId)
        .eq('user_id', userId);
  }

  Future<List<AnnotationReply>> fetchAnnotationReplies({
    required String annotationId,
    int limit = 50,
    int offset = 0,
  }) async {
    final schoolId = _requireSchoolId();

    final response = await _client
        .from('annotation_replies')
        .select()
        .eq('school_id', schoolId)
        .eq('annotation_id', annotationId)
        .order('created_at', ascending: true)
        .range(offset, offset + limit - 1);

    return (response as List)
        .map((e) => AnnotationReply.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  Future<AnnotationReply?> getAnnotationReply(String replyId) async {
    final schoolId = _requireSchoolId();

    final response = await _client
        .from('annotation_replies')
        .select()
        .eq('id', replyId)
        .eq('school_id', schoolId)
        .maybeSingle();

    if (response == null) return null;
    return AnnotationReply.fromMap(response);
  }

  Future<void> likeAnnotationReply(String replyId) async {
    final schoolId = _requireSchoolId();
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('User must be authenticated to like annotation replies');
    }

    // Check if user already liked this reply
    final existingLike = await _client
        .from('annotation_likes')
        .select()
        .eq('school_id', schoolId)
        .eq('reply_id', replyId)
        .eq('user_id', userId)
        .maybeSingle();

    if (existingLike != null) {
      // User already liked this reply, remove the like
      await _client
          .from('annotation_likes')
          .delete()
          .eq('school_id', schoolId)
          .eq('reply_id', replyId)
          .eq('user_id', userId);

      // Decrement likes count - TODO: Use proper RPC call or fetch current count and decrement
      final currentReply = await _client
          .from('annotation_replies')
          .select('likes_count')
          .eq('id', replyId)
          .single();
      final currentCount = (currentReply['likes_count'] as num?)?.toInt() ?? 0;
      await _client
          .from('annotation_replies')
          .update({'likes_count': currentCount > 0 ? currentCount - 1 : 0})
          .eq('id', replyId);
    } else {
      // Add new like
      await _client.from('annotation_likes').insert({
        'id': 'like_\${DateTime.now().millisecondsSinceEpoch}',
        'school_id': schoolId,
        'reply_id': replyId,
        'user_id': userId,
        'created_at': DateTime.now().toIso8601String(),
      });

      // Increment likes count - TODO: Use proper RPC call or fetch current count and increment
      final currentReply = await _client
          .from('annotation_replies')
          .select('likes_count')
          .eq('id', replyId)
          .single();
      final currentCount = (currentReply['likes_count'] as num?)?.toInt() ?? 0;
      await _client
          .from('annotation_replies')
          .update({'likes_count': currentCount + 1})
          .eq('id', replyId);
    }
  }

  Future<int> getAnnotationReplyLikesCount(String replyId) async {
    final schoolId = _requireSchoolId();

    final response = await _client
        .from('annotation_replies')
        .select('likes_count')
        .eq('id', replyId)
        .eq('school_id', schoolId)
        .single();

    return (response)['likes_count'] as int;
  }

  Future<bool> hasUserLikedAnnotationReply(String replyId) async {
    final schoolId = _requireSchoolId();
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return false;

    final response = await _client
        .from('annotation_likes')
        .select()
        .eq('school_id', schoolId)
        .eq('reply_id', replyId)
        .eq('user_id', userId)
        .maybeSingle();

    return response != null;
  }

  // ============================================================
  // QUIZ INTEGRATION
  // ============================================================

  Future<QuizQuestion> createQuizQuestion(QuizQuestion question) async {
    final schoolId = _requireSchoolId();
    final response = await _client
        .from('quiz_questions')
        .insert(_withSchoolId(question.toMap()))
        .select()
        .single();
    return QuizQuestion.fromMap(response);
  }

  Future<QuizQuestion> updateQuizQuestion(QuizQuestion question) async {
    final schoolId = _requireSchoolId();
    final updates = {
      ...question.toMap(),
      'updated_at': DateTime.now().toIso8601String(),
    };

    final response = await _client
        .from('quiz_questions')
        .update(updates)
        .eq('id', question.id)
        .eq('school_id', schoolId)
        .select()
        .single();
    return QuizQuestion.fromMap(response);
  }

  Future<void> deleteQuizQuestion(String questionId) async {
    final schoolId = _requireSchoolId();
    await _client
        .from('quiz_questions')
        .delete()
        .eq('id', questionId)
        .eq('school_id', schoolId);
  }

  Future<List<QuizQuestion>> fetchQuizQuestions({
    required String resourceId,
    int? pageNumber,
  }) async {
    final schoolId = _requireSchoolId();
    var queryBuilder = _client
        .from('quiz_questions')
        .select()
        .eq('school_id', schoolId)
        .eq('resource_id', resourceId);

    if (pageNumber != null) {
      queryBuilder = queryBuilder.eq('page_number', pageNumber);
    }

    final response = await queryBuilder
        .order('page_number')
        .order('created_at');
    return (response as List)
        .map((e) => QuizQuestion.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  Future<QuizQuestion?> getQuizQuestion(String questionId) async {
    final schoolId = _requireSchoolId();
    final response = await _client
        .from('quiz_questions')
        .select()
        .eq('id', questionId)
        .eq('school_id', schoolId)
        .maybeSingle();

    if (response == null) return null;
    return QuizQuestion.fromMap(response);
  }

  Future<QuizAttempt> startQuizAttempt({
    required String resourceId,
    required int totalQuestions,
    required int maxScore,
  }) async {
    final schoolId = _requireSchoolId();
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('User must be authenticated to start quiz');
    }

    final attempt = QuizAttempt(
      id: 'attempt_\${DateTime.now().millisecondsSinceEpoch}',
      schoolId: schoolId,
      resourceId: resourceId,
      userId: userId,
      status: QuizAttemptStatus.inProgress,
      totalQuestions: totalQuestions,
      correctAnswers: 0,
      score: 0,
      maxScore: maxScore,
      startedAt: DateTime.now(),
      timeSpent: Duration.zero,
      answers: {},
    );

    final response = await _client
        .from('quiz_attempts')
        .insert(attempt.toMap())
        .select()
        .single();

    return QuizAttempt.fromMap(response);
  }

  Future<QuizAttempt> updateQuizAttempt(QuizAttempt attempt) async {
    final schoolId = _requireSchoolId();
    final updates = {
      ...attempt.toMap(),
      'updated_at': DateTime.now().toIso8601String(),
    };

    final response = await _client
        .from('quiz_attempts')
        .update(updates)
        .eq('id', attempt.id)
        .eq('school_id', schoolId)
        .select()
        .single();

    return QuizAttempt.fromMap(response);
  }

  Future<QuizAttempt> submitQuizAttempt(String attemptId) async {
    final schoolId = _requireSchoolId();
    final now = DateTime.now();

    final response = await _client
        .from('quiz_attempts')
        .update({
          'status': QuizAttemptStatus.submitted.dbValue,
          'submitted_at': now.toIso8601String(),
          'updated_at': now.toIso8601String(),
        })
        .eq('id', attemptId)
        .eq('school_id', schoolId)
        .select()
        .single();

    return QuizAttempt.fromMap(response);
  }

  Future<List<QuizAttempt>> getUserQuizAttempts({
    required String resourceId,
    int limit = 10,
  }) async {
    final schoolId = _requireSchoolId();
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];

    final response = await _client
        .from('quiz_attempts')
        .select()
        .eq('school_id', schoolId)
        .eq('resource_id', resourceId)
        .eq('user_id', userId)
        .order('started_at', ascending: false)
        .limit(limit);

    return (response as List)
        .map((e) => QuizAttempt.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  Future<QuizAttempt?> getLatestQuizAttempt(String resourceId) async {
    final schoolId = _requireSchoolId();
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return null;

    final response = await _client
        .from('quiz_attempts')
        .select()
        .eq('school_id', schoolId)
        .eq('resource_id', resourceId)
        .eq('user_id', userId)
        .order('started_at', ascending: false)
        .limit(1)
        .maybeSingle();

    if (response == null) return null;
    return QuizAttempt.fromMap(response);
  }

  Future<void> updateProgressWithQuizResults({
    required String resourceId,
    required int score,
    required int maxScore,
    required Duration timeSpent,
  }) async {
    final schoolId = _requireSchoolId();
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    // Get current progress
    final progress = await getProgress(resourceId);
    final now = DateTime.now();

    if (progress != null) {
      // Update existing progress with quiz results
      await _client
          .from('digital_resource_progress')
          .update({
            'quiz_score': score,
            'quiz_max_score': maxScore,
            'quiz_time_spent_seconds': timeSpent.inSeconds,
            'quiz_completed_at': now.toIso8601String(),
            'updated_at': now.toIso8601String(),
          })
          .eq('id', progress.id);
    } else {
      // Create new progress record with quiz results
      await _client
          .from('digital_resource_progress')
          .insert(
            _withSchoolId({
              'id': 'progress_\${now.millisecondsSinceEpoch}',
              'resource_id': resourceId,
              'user_id': userId,
              'quiz_score': score,
              'quiz_max_score': maxScore,
              'quiz_time_spent_seconds': timeSpent.inSeconds,
              'quiz_completed_at': now.toIso8601String(),
              'created_at': now.toIso8601String(),
              'updated_at': now.toIso8601String(),
            }),
          );
    }
  }
}
