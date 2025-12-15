import 'package:equatable/equatable.dart';

import 'transport_type.dart';

class Vehicle extends Equatable {
  const Vehicle({
    required this.id,
    required this.schoolId,
    required this.vehicleNumber,
    required this.capacity,
    this.vehicleType = VehicleType.bus,
    this.make,
    this.model,
    this.year,
    this.color,
    this.registrationNumber,
    this.chassisNumber,
    this.engineNumber,
    this.fitnessCertificateNumber,
    this.fitnessCertificateExpiry,
    this.insuranceNumber,
    this.insuranceExpiry,
    this.routeId,
    this.status = VehicleStatus.active,
    this.purchaseDate,
    this.purchasePrice,
    this.currentValue,
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  final int id;
  final String schoolId;
  final String vehicleNumber;
  final VehicleType vehicleType;
  final String? make;
  final String? model;
  final int? year;
  final String? color;
  final int capacity;
  final String? registrationNumber;
  final String? chassisNumber;
  final String? engineNumber;
  final String? fitnessCertificateNumber;
  final DateTime? fitnessCertificateExpiry;
  final String? insuranceNumber;
  final DateTime? insuranceExpiry;
  final int? routeId;
  final VehicleStatus status;
  final DateTime? purchaseDate;
  final double? purchasePrice;
  final double? currentValue;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory Vehicle.fromMap(Map<String, dynamic> map) {
    return Vehicle(
      id: map['id'] as int,
      schoolId: map['school_id'] as String,
      vehicleNumber: map['vehicle_number'] as String,
      vehicleType: VehicleTypeX.fromDb(map['vehicle_type'] as String? ?? 'bus'),
      make: map['make'] as String?,
      model: map['model'] as String?,
      year: map['year'] as int?,
      color: map['color'] as String?,
      capacity: map['capacity'] as int,
      registrationNumber: map['registration_number'] as String?,
      chassisNumber: map['chassis_number'] as String?,
      engineNumber: map['engine_number'] as String?,
      fitnessCertificateNumber: map['fitness_certificate_number'] as String?,
      fitnessCertificateExpiry: map['fitness_certificate_expiry'] != null
          ? DateTime.parse(map['fitness_certificate_expiry'] as String)
          : null,
      insuranceNumber: map['insurance_number'] as String?,
      insuranceExpiry: map['insurance_expiry'] != null
          ? DateTime.parse(map['insurance_expiry'] as String)
          : null,
      routeId: map['route_id'] as int?,
      status: VehicleStatusX.fromDb(map['status'] as String? ?? 'active'),
      purchaseDate: map['purchase_date'] != null
          ? DateTime.parse(map['purchase_date'] as String)
          : null,
      purchasePrice: (map['purchase_price'] as num?)?.toDouble(),
      currentValue: (map['current_value'] as num?)?.toDouble(),
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
      'vehicle_number': vehicleNumber,
      'vehicle_type': vehicleType.dbValue,
      'make': make,
      'model': model,
      'year': year,
      'color': color,
      'capacity': capacity,
      'registration_number': registrationNumber,
      'chassis_number': chassisNumber,
      'engine_number': engineNumber,
      'fitness_certificate_number': fitnessCertificateNumber,
      'fitness_certificate_expiry':
          fitnessCertificateExpiry?.toIso8601String().split('T')[0],
      'insurance_number': insuranceNumber,
      'insurance_expiry': insuranceExpiry?.toIso8601String().split('T')[0],
      'route_id': routeId,
      'status': status.dbValue,
      'purchase_date': purchaseDate?.toIso8601String().split('T')[0],
      'purchase_price': purchasePrice,
      'current_value': currentValue,
      'notes': notes,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  bool get isFitnessExpiringSoon {
    if (fitnessCertificateExpiry == null) return false;
    final daysUntilExpiry =
        fitnessCertificateExpiry!.difference(DateTime.now()).inDays;
    return daysUntilExpiry <= 30 && daysUntilExpiry > 0;
  }

  bool get isFitnessExpired {
    if (fitnessCertificateExpiry == null) return false;
    return DateTime.now().isAfter(fitnessCertificateExpiry!);
  }

  bool get isInsuranceExpiringSoon {
    if (insuranceExpiry == null) return false;
    final daysUntilExpiry = insuranceExpiry!.difference(DateTime.now()).inDays;
    return daysUntilExpiry <= 30 && daysUntilExpiry > 0;
  }

  bool get isInsuranceExpired {
    if (insuranceExpiry == null) return false;
    return DateTime.now().isAfter(insuranceExpiry!);
  }

  @override
  List<Object?> get props => [
        id,
        schoolId,
        vehicleNumber,
        vehicleType,
        make,
        model,
        year,
        color,
        capacity,
        registrationNumber,
        chassisNumber,
        engineNumber,
        fitnessCertificateNumber,
        fitnessCertificateExpiry,
        insuranceNumber,
        insuranceExpiry,
        routeId,
        status,
        purchaseDate,
        purchasePrice,
        currentValue,
        notes,
        createdAt,
        updatedAt,
      ];
}

