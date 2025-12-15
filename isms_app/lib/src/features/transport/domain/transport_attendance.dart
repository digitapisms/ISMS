import 'package:equatable/equatable.dart';

import 'transport_type.dart';

class TransportAttendance extends Equatable {
  const TransportAttendance({
    required this.id,
    required this.schoolId,
    required this.studentId,
    required this.routeId,
    required this.attendanceDate,
    required this.tripType,
    required this.pickupStatus,
    required this.dropoffStatus,
    this.vehicleId,
    this.pickupTime,
    this.dropoffTime,
    this.markedBy,
    this.notes,
    this.createdAt,
  });

  final String id;
  final String schoolId;
  final String studentId;
  final int routeId;
  final int? vehicleId;
  final DateTime attendanceDate;
  final TripType tripType;
  final AttendanceStatus pickupStatus;
  final AttendanceStatus dropoffStatus;
  final String? pickupTime;
  final String? dropoffTime;
  final String? markedBy;
  final String? notes;
  final DateTime? createdAt;

  factory TransportAttendance.fromMap(Map<String, dynamic> map) {
    return TransportAttendance(
      id: map['id'] as String,
      schoolId: map['school_id'] as String,
      studentId: map['student_id'] as String,
      routeId: map['route_id'] as int,
      vehicleId: map['vehicle_id'] as int?,
      attendanceDate: DateTime.parse(map['attendance_date'] as String),
      tripType: TripTypeX.fromDb(map['trip_type'] as String? ?? 'morning'),
      pickupStatus: AttendanceStatusExtension.fromDb(
        map['pickup_status'] as String? ?? 'present',
      ),
      dropoffStatus: AttendanceStatusExtension.fromDb(
        map['dropoff_status'] as String? ?? 'present',
      ),
      pickupTime: map['pickup_time'] as String?,
      dropoffTime: map['dropoff_time'] as String?,
      markedBy: map['marked_by'] as String?,
      notes: map['notes'] as String?,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'school_id': schoolId,
      'student_id': studentId,
      'route_id': routeId,
      'vehicle_id': vehicleId,
      'attendance_date': attendanceDate.toIso8601String().split('T')[0],
      'trip_type': tripType.dbValue,
      'pickup_status': pickupStatus.dbValue,
      'dropoff_status': dropoffStatus.dbValue,
      'pickup_time': pickupTime,
      'dropoff_time': dropoffTime,
      'marked_by': markedBy,
      'notes': notes,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
        id,
        schoolId,
        studentId,
        routeId,
        vehicleId,
        attendanceDate,
        tripType,
        pickupStatus,
        dropoffStatus,
        pickupTime,
        dropoffTime,
        markedBy,
        notes,
        createdAt,
      ];
}

