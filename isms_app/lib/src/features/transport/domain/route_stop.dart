import 'package:equatable/equatable.dart';

class RouteStop extends Equatable {
  const RouteStop({
    required this.id,
    required this.schoolId,
    required this.routeId,
    required this.stopName,
    required this.stopSequence,
    this.stopAddress,
    this.latitude,
    this.longitude,
    this.estimatedTimeFromStart,
    this.isPickupPoint = true,
    this.isDropoffPoint = true,
    this.notes,
    this.createdAt,
  });

  final int id;
  final String schoolId;
  final int routeId;
  final String stopName;
  final String? stopAddress;
  final int stopSequence;
  final double? latitude;
  final double? longitude;
  final int? estimatedTimeFromStart;
  final bool isPickupPoint;
  final bool isDropoffPoint;
  final String? notes;
  final DateTime? createdAt;

  factory RouteStop.fromMap(Map<String, dynamic> map) {
    return RouteStop(
      id: map['id'] as int,
      schoolId: map['school_id'] as String,
      routeId: map['route_id'] as int,
      stopName: map['stop_name'] as String,
      stopAddress: map['stop_address'] as String?,
      stopSequence: map['stop_sequence'] as int,
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      estimatedTimeFromStart: map['estimated_time_from_start'] as int?,
      isPickupPoint: (map['is_pickup_point'] as bool?) ?? true,
      isDropoffPoint: (map['is_dropoff_point'] as bool?) ?? true,
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
      'route_id': routeId,
      'stop_name': stopName,
      'stop_address': stopAddress,
      'stop_sequence': stopSequence,
      'latitude': latitude,
      'longitude': longitude,
      'estimated_time_from_start': estimatedTimeFromStart,
      'is_pickup_point': isPickupPoint,
      'is_dropoff_point': isDropoffPoint,
      'notes': notes,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
        id,
        schoolId,
        routeId,
        stopName,
        stopAddress,
        stopSequence,
        latitude,
        longitude,
        estimatedTimeFromStart,
        isPickupPoint,
        isDropoffPoint,
        notes,
        createdAt,
      ];
}

