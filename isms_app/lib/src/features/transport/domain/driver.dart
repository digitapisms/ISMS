import 'package:equatable/equatable.dart';

import 'transport_type.dart';

class Driver extends Equatable {
  const Driver({
    required this.id,
    required this.schoolId,
    required this.fullName,
    required this.licenseNumber,
    required this.licenseExpiry,
    this.userId,
    this.cnic,
    this.licenseType = LicenseType.psv,
    this.phoneNumber,
    this.alternatePhone,
    this.address,
    this.emergencyContact,
    this.emergencyPhone,
    this.experienceYears,
    this.dateOfJoining,
    this.salary,
    this.status = StaffStatus.active,
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
  final String licenseNumber;
  final LicenseType licenseType;
  final DateTime licenseExpiry;
  final String? phoneNumber;
  final String? alternatePhone;
  final String? address;
  final String? emergencyContact;
  final String? emergencyPhone;
  final int? experienceYears;
  final DateTime? dateOfJoining;
  final double? salary;
  final StaffStatus status;
  final int? vehicleId;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory Driver.fromMap(Map<String, dynamic> map) {
    return Driver(
      id: map['id'] as String,
      schoolId: map['school_id'] as String,
      userId: map['user_id'] as String?,
      fullName: map['full_name'] as String,
      cnic: map['cnic'] as String?,
      licenseNumber: map['license_number'] as String,
      licenseType: LicenseTypeX.fromDb(map['license_type'] as String? ?? 'PSV'),
      licenseExpiry: DateTime.parse(map['license_expiry'] as String),
      phoneNumber: map['phone_number'] as String?,
      alternatePhone: map['alternate_phone'] as String?,
      address: map['address'] as String?,
      emergencyContact: map['emergency_contact'] as String?,
      emergencyPhone: map['emergency_phone'] as String?,
      experienceYears: map['experience_years'] as int?,
      dateOfJoining: map['date_of_joining'] != null
          ? DateTime.parse(map['date_of_joining'] as String)
          : null,
      salary: (map['salary'] as num?)?.toDouble(),
      status: StaffStatusX.fromDb(map['status'] as String? ?? 'active'),
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
      'license_number': licenseNumber,
      'license_type': licenseType.dbValue,
      'license_expiry': licenseExpiry.toIso8601String().split('T')[0],
      'phone_number': phoneNumber,
      'alternate_phone': alternatePhone,
      'address': address,
      'emergency_contact': emergencyContact,
      'emergency_phone': emergencyPhone,
      'experience_years': experienceYears,
      'date_of_joining': dateOfJoining?.toIso8601String().split('T')[0],
      'salary': salary,
      'status': status.dbValue,
      'vehicle_id': vehicleId,
      'notes': notes,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  bool get isLicenseExpiringSoon {
    final daysUntilExpiry = licenseExpiry.difference(DateTime.now()).inDays;
    return daysUntilExpiry <= 30 && daysUntilExpiry > 0;
  }

  bool get isLicenseExpired {
    return DateTime.now().isAfter(licenseExpiry);
  }

  @override
  List<Object?> get props => [
        id,
        schoolId,
        userId,
        fullName,
        cnic,
        licenseNumber,
        licenseType,
        licenseExpiry,
        phoneNumber,
        alternatePhone,
        address,
        emergencyContact,
        emergencyPhone,
        experienceYears,
        dateOfJoining,
        salary,
        status,
        vehicleId,
        notes,
        createdAt,
        updatedAt,
      ];
}

