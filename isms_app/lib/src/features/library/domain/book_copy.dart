import 'package:equatable/equatable.dart';

import 'book_type.dart';

class BookCopy extends Equatable {
  const BookCopy({
    required this.id,
    required this.schoolId,
    required this.bookId,
    required this.copyNumber,
    this.barcode,
    this.qrCode,
    this.status = BookCopyStatus.available,
    this.conditionStatus = BookCondition.good,
    this.purchaseDate,
    this.purchasePrice,
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  final int id;
  final String schoolId;
  final int bookId;
  final int copyNumber;
  final String? barcode;
  final String? qrCode;
  final BookCopyStatus status;
  final BookCondition conditionStatus;
  final DateTime? purchaseDate;
  final double? purchasePrice;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory BookCopy.fromMap(Map<String, dynamic> map) {
    return BookCopy(
      id: map['id'] as int,
      schoolId: map['school_id'] as String,
      bookId: map['book_id'] as int,
      copyNumber: map['copy_number'] as int,
      barcode: map['barcode'] as String?,
      qrCode: map['qr_code'] as String?,
      status: BookCopyStatusX.fromDb(map['status'] as String? ?? 'available'),
      conditionStatus:
          BookConditionX.fromDb(map['condition_status'] as String? ?? 'good'),
      purchaseDate: map['purchase_date'] != null
          ? DateTime.parse(map['purchase_date'] as String)
          : null,
      purchasePrice: (map['purchase_price'] as num?)?.toDouble(),
      notes: map['notes'] as String?,
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
      'copy_number': copyNumber,
      'barcode': barcode,
      'qr_code': qrCode,
      'status': status.dbValue,
      'condition_status': conditionStatus.dbValue,
      'purchase_date': purchaseDate?.toIso8601String().split('T')[0],
      'purchase_price': purchasePrice,
      'notes': notes,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
        id,
        schoolId,
        bookId,
        copyNumber,
        barcode,
        qrCode,
        status,
        conditionStatus,
        purchaseDate,
        purchasePrice,
        notes,
        createdAt,
        updatedAt,
      ];
}

