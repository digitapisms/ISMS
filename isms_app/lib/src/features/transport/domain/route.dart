import 'package:equatable/equatable.dart';

class Route extends Equatable {
  const Route({
    required this.id,
    required this.schoolId,
    required this.routeName,
    required this.startLocation,
    required this.endLocation,
    this.routeNumber,
    this.totalDistance,
    this.estimatedTime,
    this.vehicleId,
    this.driverId,
    this.helperId,
    this.isActive = true,
    this.morningPickupTime,
    this.morningDropoffTime,
    this.afternoonPickupTime,
    this.afternoonDropoffTime,
    this.transportFee = 0.0,
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  final int id;
  final String schoolId;
  final String routeName;
  final String? routeNumber;
  final String startLocation;
  final String endLocation;
  final double? totalDistance;
  final int? estimatedTime;
  final int? vehicleId;
  final String? driverId;
  final String? helperId;
  final bool isActive;
  final String? morningPickupTime;
  final String? morningDropoffTime;
  final String? afternoonPickupTime;
  final String? afternoonDropoffTime;
  final double transportFee;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory Route.fromMap(Map<String, dynamic> map) {
    return Route(
      id: map['id'] as int,
      schoolId: map['school_id'] as String,
      routeName: map['route_name'] as String,
      routeNumber: map['route_number'] as String?,
      startLocation: map['start_location'] as String,
      endLocation: map['end_location'] as String,
      totalDistance: (map['total_distance'] as num?)?.toDouble(),
      estimatedTime: map['estimated_time'] as int?,
      vehicleId: map['vehicle_id'] as int?,
      driverId: map['driver_id'] as String?,
      helperId: map['helper_id'] as String?,
      isActive: (map['is_active'] as bool?) ?? true,
      morningPickupTime: map['morning_pickup_time'] as String?,
      morningDropoffTime: map['morning_dropoff_time'] as String?,
      afternoonPickupTime: map['afternoon_pickup_time'] as String?,
      afternoonDropoffTime: map['afternoon_dropoff_time'] as String?,
      transportFee: (map['transport_fee'] as num?)?.toDouble() ?? 0.0,
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
      'route_name': routeName,
      'route_number': routeNumber,
      'start_location': startLocation,
      'end_location': endLocation,
      'total_distance': totalDistance,
      'estimated_time': estimatedTime,
      'vehicle_id': vehicleId,
      'driver_id': driverId,
      'helper_id': helperId,
      'is_active': isActive,
      'morning_pickup_time': morningPickupTime,
      'morning_dropoff_time': morningDropoffTime,
      'afternoon_pickup_time': afternoonPickupTime,
      'afternoon_dropoff_time': afternoonDropoffTime,
      'transport_fee': transportFee,
      'notes': notes,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
        id,
        schoolId,
        routeName,
        routeNumber,
        startLocation,
        endLocation,
        totalDistance,
        estimatedTime,
        vehicleId,
        driverId,
        helperId,
        isActive,
        morningPickupTime,
        morningDropoffTime,
        afternoonPickupTime,
        afternoonDropoffTime,
        transportFee,
        notes,
        createdAt,
        updatedAt,
      ];
}

