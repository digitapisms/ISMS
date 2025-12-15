import 'package:equatable/equatable.dart';

import 'fee_frequency.dart';

/// Fee structure model - defines fee amounts for different categories
class FeeStructure extends Equatable {
  const FeeStructure({
    required this.id,
    required this.schoolId,
    required this.categoryId,
    required this.name,
    required this.amount,
    this.description,
    this.currency = 'PKR',
    this.frequency = FeeFrequency.monthly,
    this.applicableTo = FeeApplicability.all,
    this.classId,
    this.sectionId,
    this.studentId,
    this.startDate,
    this.endDate,
    this.isActive = true,
    this.lateFeePercentage = 0,
    this.lateFeeFixedAmount = 0,
    this.discountPercentage = 0,
    this.discountFixedAmount = 0,
    this.metadata,
    this.createdBy,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String schoolId;
  final String categoryId;
  final String name;
  final String? description;
  final double amount;
  final String currency;
  final FeeFrequency frequency;
  final FeeApplicability applicableTo;
  final int? classId;
  final int? sectionId;
  final String? studentId;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool isActive;
  final double lateFeePercentage;
  final double lateFeeFixedAmount;
  final double discountPercentage;
  final double discountFixedAmount;
  final Map<String, dynamic>? metadata;
  final String? createdBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory FeeStructure.fromMap(Map<String, dynamic> map) {
    return FeeStructure(
      id: map['id'] as String,
      schoolId: map['school_id'] as String,
      categoryId: map['category_id'] as String,
      name: map['name'] as String,
      description: map['description'] as String?,
      amount: (map['amount'] as num).toDouble(),
      currency: map['currency'] as String? ?? 'PKR',
      frequency: FeeFrequency.fromDb(map['frequency'] as String? ?? 'monthly'),
      applicableTo: FeeApplicability.fromDb(
        map['applicable_to'] as String? ?? 'all',
      ),
      classId: map['class_id'] as int?,
      sectionId: map['section_id'] as int?,
      studentId: map['student_id'] as String?,
      startDate: map['start_date'] != null
          ? DateTime.parse(map['start_date'] as String)
          : null,
      endDate: map['end_date'] != null
          ? DateTime.parse(map['end_date'] as String)
          : null,
      isActive: map['is_active'] as bool? ?? true,
      lateFeePercentage: (map['late_fee_percentage'] as num?)?.toDouble() ?? 0,
      lateFeeFixedAmount:
          (map['late_fee_fixed_amount'] as num?)?.toDouble() ?? 0,
      discountPercentage: (map['discount_percentage'] as num?)?.toDouble() ?? 0,
      discountFixedAmount:
          (map['discount_fixed_amount'] as num?)?.toDouble() ?? 0,
      metadata: map['metadata'] != null
          ? Map<String, dynamic>.from(map['metadata'] as Map)
          : null,
      createdBy: map['created_by'] as String?,
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
      'category_id': categoryId,
      'name': name,
      'description': description,
      'amount': amount,
      'currency': currency,
      'frequency': frequency.dbValue,
      'applicable_to': applicableTo.dbValue,
      'class_id': classId,
      'section_id': sectionId,
      'student_id': studentId,
      'start_date': startDate?.toIso8601String().split('T')[0],
      'end_date': endDate?.toIso8601String().split('T')[0],
      'is_active': isActive,
      'late_fee_percentage': lateFeePercentage,
      'late_fee_fixed_amount': lateFeeFixedAmount,
      'discount_percentage': discountPercentage,
      'discount_fixed_amount': discountFixedAmount,
      'metadata': metadata,
      'created_by': createdBy,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
    id,
    schoolId,
    categoryId,
    name,
    description,
    amount,
    currency,
    frequency,
    applicableTo,
    classId,
    sectionId,
    studentId,
    startDate,
    endDate,
    isActive,
    lateFeePercentage,
    lateFeeFixedAmount,
    discountPercentage,
    discountFixedAmount,
    metadata,
    createdBy,
    createdAt,
    updatedAt,
  ];
}
