import 'package:equatable/equatable.dart';

enum RoomType { classroom, lab, library, hall, sports, computerLab }

extension RoomTypeX on RoomType {
  String get dbValue {
    switch (this) {
      case RoomType.classroom:
        return 'classroom';
      case RoomType.lab:
        return 'lab';
      case RoomType.library:
        return 'library';
      case RoomType.hall:
        return 'hall';
      case RoomType.sports:
        return 'sports';
      case RoomType.computerLab:
        return 'computer_lab';
    }
  }

  String get displayName {
    switch (this) {
      case RoomType.classroom:
        return 'Classroom';
      case RoomType.lab:
        return 'Lab';
      case RoomType.library:
        return 'Library';
      case RoomType.hall:
        return 'Hall';
      case RoomType.sports:
        return 'Sports';
      case RoomType.computerLab:
        return 'Computer Lab';
    }
  }

  static RoomType fromDb(String value) {
    switch (value) {
      case 'classroom':
        return RoomType.classroom;
      case 'lab':
        return RoomType.lab;
      case 'library':
        return RoomType.library;
      case 'hall':
        return RoomType.hall;
      case 'sports':
        return RoomType.sports;
      case 'computer_lab':
        return RoomType.computerLab;
      default:
        return RoomType.classroom;
    }
  }
}

class Room extends Equatable {
  const Room({
    required this.id,
    required this.schoolId,
    required this.name,
    this.code,
    this.roomType = RoomType.classroom,
    this.capacity,
    this.floorNumber,
    this.buildingName,
    this.facilities = const [],
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  final int id;
  final String schoolId;
  final String name;
  final String? code;
  final RoomType roomType;
  final int? capacity;
  final int? floorNumber;
  final String? buildingName;
  final List<String> facilities;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory Room.fromMap(Map<String, dynamic> map) {
    final facilitiesData = map['facilities'];
    return Room(
      id: map['id'] as int,
      schoolId: map['school_id'] as String,
      name: map['name'] as String,
      code: map['code'] as String?,
      roomType: RoomTypeX.fromDb(map['room_type'] as String? ?? 'classroom'),
      capacity: map['capacity'] as int?,
      floorNumber: map['floor_number'] as int?,
      buildingName: map['building_name'] as String?,
      facilities: facilitiesData != null
          ? (facilitiesData as List).map((e) => e.toString()).toList()
          : [],
      isActive: (map['is_active'] as bool?) ?? true,
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
      'name': name,
      'code': code,
      'room_type': roomType.dbValue,
      'capacity': capacity,
      'floor_number': floorNumber,
      'building_name': buildingName,
      'facilities': facilities,
      'is_active': isActive,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
    id,
    schoolId,
    name,
    code,
    roomType,
    capacity,
    floorNumber,
    buildingName,
    facilities,
    isActive,
    createdAt,
    updatedAt,
  ];
}
