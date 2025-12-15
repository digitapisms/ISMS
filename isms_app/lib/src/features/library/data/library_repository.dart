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

    await _client.storage.from('library').uploadBinary(
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
}

