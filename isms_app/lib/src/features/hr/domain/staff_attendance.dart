import 'package:equatable/equatable.dart';

class StaffAttendance extends Equatable {
  const StaffAttendance({
    required this.id,
    required this.schoolId,
    required this.staffId,
    required this.attendanceDate,
    this.checkInTime,
    this.checkOutTime,
    this.status = 'present',
    this.sessionIdentifier,
    this.shiftType,
    this.totalHours = 0.0,
    this.checkInLatitude,
    this.checkInLongitude,
    this.checkOutLatitude,
    this.checkOutLongitude,
    this.checkInMethod,
    this.checkOutMethod,
    this.verifiedBy,
    this.notes,
    this.adjustmentReason,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String schoolId;
  final String staffId;
  final DateTime attendanceDate;
  final DateTime? checkInTime;
  final DateTime? checkOutTime;
  final String status;
  final String? sessionIdentifier;
  final String? shiftType;
  final double totalHours;
  final double? checkInLatitude;
  final double? checkInLongitude;
  final double? checkOutLatitude;
  final double? checkOutLongitude;
  final String? checkInMethod;
  final String? checkOutMethod;
  final String? verifiedBy;
  final String? notes;
  final String? adjustmentReason;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory StaffAttendance.fromMap(Map<String, dynamic> map) {
    return StaffAttendance(
      id: map['id'] as String,
      schoolId: map['school_id'] as String,
      staffId: map['staff_id'] as String,
      attendanceDate: DateTime.parse(map['attendance_date'] as String),
      checkInTime: map['check_in_time'] != null
          ? DateTime.parse(map['check_in_time'] as String)
          : null,
      checkOutTime: map['check_out_time'] != null
          ? DateTime.parse(map['check_out_time'] as String)
          : null,
      status: map['status'] as String? ?? 'present',
      sessionIdentifier: map['session_identifier'] as String?,
      shiftType: map['shift_type'] as String?,
      totalHours: (map['total_hours'] as num?)?.toDouble() ?? 0.0,
      checkInLatitude: (map['check_in_latitude'] as num?)?.toDouble(),
      checkInLongitude: (map['check_in_longitude'] as num?)?.toDouble(),
      checkOutLatitude: (map['check_out_latitude'] as num?)?.toDouble(),
      checkOutLongitude: (map['check_out_longitude'] as num?)?.toDouble(),
      checkInMethod: map['check_in_method'] as String?,
      checkOutMethod: map['check_out_method'] as String?,
      verifiedBy: map['verified_by'] as String?,
      notes: map['notes'] as String?,
      adjustmentReason: map['adjustment_reason'] as String?,
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
      'staff_id': staffId,
      'attendance_date': attendanceDate.toIso8601String(),
      'check_in_time': checkInTime?.toIso8601String(),
      'check_out_time': checkOutTime?.toIso8601String(),
      'status': status,
      'session_identifier': sessionIdentifier,
      'shift_type': shiftType,
      'total_hours': totalHours,
      'check_in_latitude': checkInLatitude,
      'check_in_longitude': checkInLongitude,
      'check_out_latitude': checkOutLatitude,
      'check_out_longitude': checkOutLongitude,
      'check_in_method': checkInMethod,
      'check_out_method': checkOutMethod,
      'verified_by': verifiedBy,
      'notes': notes,
      'adjustment_reason': adjustmentReason,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  StaffAttendance copyWith({
    String? id,
    String? schoolId,
    String? staffId,
    DateTime? attendanceDate,
    DateTime? checkInTime,
    DateTime? checkOutTime,
    String? status,
    String? sessionIdentifier,
    String? shiftType,
    double? totalHours,
    double? checkInLatitude,
    double? checkInLongitude,
    double? checkOutLatitude,
    double? checkOutLongitude,
    String? checkInMethod,
    String? checkOutMethod,
    String? verifiedBy,
    String? notes,
    String? adjustmentReason,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return StaffAttendance(
      id: id ?? this.id,
      schoolId: schoolId ?? this.schoolId,
      staffId: staffId ?? this.staffId,
      attendanceDate: attendanceDate ?? this.attendanceDate,
      checkInTime: checkInTime ?? this.checkInTime,
      checkOutTime: checkOutTime ?? this.checkOutTime,
      status: status ?? this.status,
      sessionIdentifier: sessionIdentifier ?? this.sessionIdentifier,
      shiftType: shiftType ?? this.shiftType,
      totalHours: totalHours ?? this.totalHours,
      checkInLatitude: checkInLatitude ?? this.checkInLatitude,
      checkInLongitude: checkInLongitude ?? this.checkInLongitude,
      checkOutLatitude: checkOutLatitude ?? this.checkOutLatitude,
      checkOutLongitude: checkOutLongitude ?? this.checkOutLongitude,
      checkInMethod: checkInMethod ?? this.checkInMethod,
      checkOutMethod: checkOutMethod ?? this.checkOutMethod,
      verifiedBy: verifiedBy ?? this.verifiedBy,
      notes: notes ?? this.notes,
      adjustmentReason: adjustmentReason ?? this.adjustmentReason,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        schoolId,
        staffId,
        attendanceDate,
        checkInTime,
        checkOutTime,
        status,
        sessionIdentifier,
        shiftType,
        totalHours,
        checkInLatitude,
        checkInLongitude,
        checkOutLatitude,
        checkOutLongitude,
        checkInMethod,
        checkOutMethod,
        verifiedBy,
        notes,
        adjustmentReason,
        createdAt,
        updatedAt,
      ];
}