import 'package:equatable/equatable.dart';

import 'transport_type.dart';

class TransportAssignment extends Equatable {
  const TransportAssignment({
    required this.id,
    required this.schoolId,
    required this.studentId,
    required this.routeId,
    required this.assignmentDate,
    required this.effectiveFrom,
    this.pickupStopId,
    this.dropoffStopId,
    this.effectiveUntil,
    this.transportFee,
    this.feeStatus = FeeStatus.pending,
    this.isActive = true,
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String schoolId;
  final String studentId;
  final int routeId;
  final int? pickupStopId;
  final int? dropoffStopId;
  final DateTime assignmentDate;
  final DateTime effectiveFrom;
  final DateTime? effectiveUntil;
  final double? transportFee;
  final FeeStatus feeStatus;
  final bool isActive;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory TransportAssignment.fromMap(Map<String, dynamic> map) {
    return TransportAssignment(
      id: map['id'] as String,
      schoolId: map['school_id'] as String,
      studentId: map['student_id'] as String,
      routeId: map['route_id'] as int,
      pickupStopId: map['pickup_stop_id'] as int?,
      dropoffStopId: map['dropoff_stop_id'] as int?,
      assignmentDate: DateTime.parse(map['assignment_date'] as String),
      effectiveFrom: DateTime.parse(map['effective_from'] as String),
      effectiveUntil: map['effective_until'] != null
          ? DateTime.parse(map['effective_until'] as String)
          : null,
      transportFee: (map['transport_fee'] as num?)?.toDouble(),
      feeStatus: FeeStatusX.fromDb(map['fee_status'] as String? ?? 'pending'),
      isActive: (map['is_active'] as bool?) ?? true,
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
      'student_id': studentId,
      'route_id': routeId,
      'pickup_stop_id': pickupStopId,
      'dropoff_stop_id': dropoffStopId,
      'assignment_date': assignmentDate.toIso8601String().split('T')[0],
      'effective_from': effectiveFrom.toIso8601String().split('T')[0],
      'effective_until': effectiveUntil?.toIso8601String().split('T')[0],
      'transport_fee': transportFee,
      'fee_status': feeStatus.dbValue,
      'is_active': isActive,
      'notes': notes,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  bool get isCurrentlyActive {
    if (!isActive) return false;
    if (effectiveUntil == null) return true;
    return DateTime.now().isBefore(effectiveUntil!);
  }

  @override
  List<Object?> get props => [
        id,
        schoolId,
        studentId,
        routeId,
        pickupStopId,
        dropoffStopId,
        assignmentDate,
        effectiveFrom,
        effectiveUntil,
        transportFee,
        feeStatus,
        isActive,
        notes,
        createdAt,
        updatedAt,
      ];
}

