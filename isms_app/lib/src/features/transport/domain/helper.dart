import 'package:equatable/equatable.dart';

import 'transport_type.dart';

class Helper extends Equatable {
  const Helper({
    required this.id,
    required this.schoolId,
    required this.fullName,
    this.userId,
    this.cnic,
    this.phoneNumber,
    this.alternatePhone,
    this.address,
    this.emergencyContact,
    this.emergencyPhone,
    this.dateOfJoining,
    this.salary,
    this.status = StaffStatus.active,
    this.routeId,
    this.vehicleId,
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String schoolId;
  final String? userId;
  final String fullName;
  final String? cnic;
  final String? phoneNumber;
  final String? alternatePhone;
  final String? address;
  final String? emergencyContact;
  final String? emergencyPhone;
  final DateTime? dateOfJoining;
  final double? salary;
  final StaffStatus status;
  final int? routeId;
  final int? vehicleId;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory Helper.fromMap(Map<String, dynamic> map) {
    return Helper(
      id: map['id'] as String,
      schoolId: map['school_id'] as String,
      userId: map['user_id'] as String?,
      fullName: map['full_name'] as String,
      cnic: map['cnic'] as String?,
      phoneNumber: map['phone_number'] as String?,
      alternatePhone: map['alternate_phone'] as String?,
      address: map['address'] as String?,
      emergencyContact: map['emergency_contact'] as String?,
      emergencyPhone: map['emergency_phone'] as String?,
      dateOfJoining: map['date_of_joining'] != null
          ? DateTime.parse(map['date_of_joining'] as String)
          : null,
      salary: (map['salary'] as num?)?.toDouble(),
      status: StaffStatusX.fromDb(map['status'] as String? ?? 'active'),
      routeId: map['route_id'] as int?,
      vehicleId: map['vehicle_id'] as int?,
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
      'user_id': userId,
      'full_name': fullName,
      'cnic': cnic,
      'phone_number': phoneNumber,
      'alternate_phone': alternatePhone,
      'address': address,
      'emergency_contact': emergencyContact,
      'emergency_phone': emergencyPhone,
      'date_of_joining': dateOfJoining?.toIso8601String().split('T')[0],
      'salary': salary,
      'status': status.dbValue,
      'route_id': routeId,
      'vehicle_id': vehicleId,
      'notes': notes,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
        id,
        schoolId,
        userId,
        fullName,
        cnic,
        phoneNumber,
        alternatePhone,
        address,
        emergencyContact,
        emergencyPhone,
        dateOfJoining,
        salary,
        status,
        routeId,
        vehicleId,
        notes,
        createdAt,
        updatedAt,
      ];
}

