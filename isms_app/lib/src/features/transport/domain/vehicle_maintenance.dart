import 'package:equatable/equatable.dart';

import 'transport_type.dart';

class VehicleMaintenance extends Equatable {
  const VehicleMaintenance({
    required this.id,
    required this.schoolId,
    required this.vehicleId,
    required this.maintenanceType,
    required this.maintenanceDate,
    this.nextServiceDate,
    this.cost,
    this.serviceProvider,
    this.description,
    this.partsReplaced,
    this.mileageAtService,
    this.performedBy,
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String schoolId;
  final int vehicleId;
  final MaintenanceType maintenanceType;
  final DateTime maintenanceDate;
  final DateTime? nextServiceDate;
  final double? cost;
  final String? serviceProvider;
  final String? description;
  final String? partsReplaced;
  final int? mileageAtService;
  final String? performedBy;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory VehicleMaintenance.fromMap(Map<String, dynamic> map) {
    return VehicleMaintenance(
      id: map['id'] as String,
      schoolId: map['school_id'] as String,
      vehicleId: map['vehicle_id'] as int,
      maintenanceType: MaintenanceTypeX.fromDb(
        map['maintenance_type'] as String,
      ),
      maintenanceDate: DateTime.parse(map['maintenance_date'] as String),
      nextServiceDate: map['next_service_date'] != null
          ? DateTime.parse(map['next_service_date'] as String)
          : null,
      cost: (map['cost'] as num?)?.toDouble(),
      serviceProvider: map['service_provider'] as String?,
      description: map['description'] as String?,
      partsReplaced: map['parts_replaced'] as String?,
      mileageAtService: map['mileage_at_service'] as int?,
      performedBy: map['performed_by'] as String?,
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
      'vehicle_id': vehicleId,
      'maintenance_type': maintenanceType.dbValue,
      'maintenance_date': maintenanceDate.toIso8601String().split('T')[0],
      'next_service_date': nextServiceDate?.toIso8601String().split('T')[0],
      'cost': cost,
      'service_provider': serviceProvider,
      'description': description,
      'parts_replaced': partsReplaced,
      'mileage_at_service': mileageAtService,
      'performed_by': performedBy,
      'notes': notes,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  bool get isServiceDue {
    if (nextServiceDate == null) return false;
    return DateTime.now().isAfter(nextServiceDate!);
  }

  @override
  List<Object?> get props => [
        id,
        schoolId,
        vehicleId,
        maintenanceType,
        maintenanceDate,
        nextServiceDate,
        cost,
        serviceProvider,
        description,
        partsReplaced,
        mileageAtService,
        performedBy,
        notes,
        createdAt,
        updatedAt,
      ];
}

