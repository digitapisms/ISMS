import 'package:equatable/equatable.dart';

import 'book_type.dart';

class BookReservation extends Equatable {
  const BookReservation({
    required this.id,
    required this.schoolId,
    required this.bookId,
    required this.reservationDate,
    this.studentId,
    this.staffId,
    this.expiryDate,
    this.status = ReservationStatus.pending,
    this.priority = 0,
    this.notifiedAt,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String schoolId;
  final int bookId;
  final String? studentId;
  final String? staffId;
  final DateTime reservationDate;
  final DateTime? expiryDate;
  final ReservationStatus status;
  final int priority;
  final DateTime? notifiedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory BookReservation.fromMap(Map<String, dynamic> map) {
    return BookReservation(
      id: map['id'] as String,
      schoolId: map['school_id'] as String,
      bookId: map['book_id'] as int,
      studentId: map['student_id'] as String?,
      staffId: map['staff_id'] as String?,
      reservationDate: DateTime.parse(map['reservation_date'] as String),
      expiryDate: map['expiry_date'] != null
          ? DateTime.parse(map['expiry_date'] as String)
          : null,
      status: ReservationStatusX.fromDb(
        map['status'] as String? ?? 'pending',
      ),
      priority: (map['priority'] as int?) ?? 0,
      notifiedAt: map['notified_at'] != null
          ? DateTime.parse(map['notified_at'] as String)
          : null,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'school_id': schoolId,
      'book_id': bookId,
      'student_id': studentId,
      'staff_id': staffId,
      'reservation_date': reservationDate.toIso8601String().split('T')[0],
      'expiry_date': expiryDate?.toIso8601String().split('T')[0],
      'status': status.dbValue,
      'priority': priority,
      'notified_at': notifiedAt?.toIso8601String(),
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  bool get isExpired {
    if (expiryDate == null) return false;
    return DateTime.now().isAfter(expiryDate!);
  }

  @override
  List<Object?> get props => [
        id,
        schoolId,
        bookId,
        studentId,
        staffId,
        reservationDate,
        expiryDate,
        status,
        priority,
        notifiedAt,
        createdAt,
        updatedAt,
      ];
}

