enum VehicleType {
  bus,
  van,
  car,
  coaster,
}

extension VehicleTypeX on VehicleType {
  String get dbValue {
    switch (this) {
      case VehicleType.bus:
        return 'bus';
      case VehicleType.van:
        return 'van';
      case VehicleType.car:
        return 'car';
      case VehicleType.coaster:
        return 'coaster';
    }
  }

  String get displayName {
    switch (this) {
      case VehicleType.bus:
        return 'Bus';
      case VehicleType.van:
        return 'Van';
      case VehicleType.car:
        return 'Car';
      case VehicleType.coaster:
        return 'Coaster';
    }
  }

  static VehicleType fromDb(String value) {
    switch (value) {
      case 'bus':
        return VehicleType.bus;
      case 'van':
        return VehicleType.van;
      case 'car':
        return VehicleType.car;
      case 'coaster':
        return VehicleType.coaster;
      default:
        return VehicleType.bus;
    }
  }
}

enum VehicleStatus {
  active,
  maintenance,
  retired,
}

extension VehicleStatusX on VehicleStatus {
  String get dbValue {
    switch (this) {
      case VehicleStatus.active:
        return 'active';
      case VehicleStatus.maintenance:
        return 'maintenance';
      case VehicleStatus.retired:
        return 'retired';
    }
  }

  String get displayName {
    switch (this) {
      case VehicleStatus.active:
        return 'Active';
      case VehicleStatus.maintenance:
        return 'Maintenance';
      case VehicleStatus.retired:
        return 'Retired';
    }
  }

  static VehicleStatus fromDb(String value) {
    switch (value) {
      case 'active':
        return VehicleStatus.active;
      case 'maintenance':
        return VehicleStatus.maintenance;
      case 'retired':
        return VehicleStatus.retired;
      default:
        return VehicleStatus.active;
    }
  }
}

enum LicenseType {
  psv,
  ltv,
  htv,
}

extension LicenseTypeX on LicenseType {
  String get dbValue {
    switch (this) {
      case LicenseType.psv:
        return 'PSV';
      case LicenseType.ltv:
        return 'LTV';
      case LicenseType.htv:
        return 'HTV';
    }
  }

  String get displayName {
    switch (this) {
      case LicenseType.psv:
        return 'PSV (Public Service Vehicle)';
      case LicenseType.ltv:
        return 'LTV (Light Transport Vehicle)';
      case LicenseType.htv:
        return 'HTV (Heavy Transport Vehicle)';
    }
  }

  static LicenseType fromDb(String value) {
    switch (value) {
      case 'PSV':
        return LicenseType.psv;
      case 'LTV':
        return LicenseType.ltv;
      case 'HTV':
        return LicenseType.htv;
      default:
        return LicenseType.psv;
    }
  }
}

enum StaffStatus {
  active,
  onLeave,
  terminated,
}

extension StaffStatusX on StaffStatus {
  String get dbValue {
    switch (this) {
      case StaffStatus.active:
        return 'active';
      case StaffStatus.onLeave:
        return 'on_leave';
      case StaffStatus.terminated:
        return 'terminated';
    }
  }

  String get displayName {
    switch (this) {
      case StaffStatus.active:
        return 'Active';
      case StaffStatus.onLeave:
        return 'On Leave';
      case StaffStatus.terminated:
        return 'Terminated';
    }
  }

  static StaffStatus fromDb(String value) {
    switch (value) {
      case 'active':
        return StaffStatus.active;
      case 'on_leave':
        return StaffStatus.onLeave;
      case 'terminated':
        return StaffStatus.terminated;
      default:
        return StaffStatus.active;
    }
  }
}

enum TripType {
  morning,
  afternoon,
  both,
}

extension TripTypeX on TripType {
  String get dbValue {
    switch (this) {
      case TripType.morning:
        return 'morning';
      case TripType.afternoon:
        return 'afternoon';
      case TripType.both:
        return 'both';
    }
  }

  String get displayName {
    switch (this) {
      case TripType.morning:
        return 'Morning';
      case TripType.afternoon:
        return 'Afternoon';
      case TripType.both:
        return 'Both';
    }
  }

  static TripType fromDb(String value) {
    switch (value) {
      case 'morning':
        return TripType.morning;
      case 'afternoon':
        return TripType.afternoon;
      case 'both':
        return TripType.both;
      default:
        return TripType.morning;
    }
  }
}

enum AttendanceStatus {
  present,
  absent,
  late,
}

extension AttendanceStatusExtension on AttendanceStatus {
  String get dbValue {
    switch (this) {
      case AttendanceStatus.present:
        return 'present';
      case AttendanceStatus.absent:
        return 'absent';
      case AttendanceStatus.late:
        return 'late';
    }
  }

  String get displayName {
    switch (this) {
      case AttendanceStatus.present:
        return 'Present';
      case AttendanceStatus.absent:
        return 'Absent';
      case AttendanceStatus.late:
        return 'Late';
    }
  }

  static AttendanceStatus fromDb(String value) {
    switch (value) {
      case 'present':
        return AttendanceStatus.present;
      case 'absent':
        return AttendanceStatus.absent;
      case 'late':
        return AttendanceStatus.late;
      default:
        return AttendanceStatus.present;
    }
  }
}

enum FeeStatus {
  pending,
  paid,
  overdue,
  waived,
}

extension FeeStatusX on FeeStatus {
  String get dbValue {
    switch (this) {
      case FeeStatus.pending:
        return 'pending';
      case FeeStatus.paid:
        return 'paid';
      case FeeStatus.overdue:
        return 'overdue';
      case FeeStatus.waived:
        return 'waived';
    }
  }

  static FeeStatus fromDb(String value) {
    switch (value) {
      case 'pending':
        return FeeStatus.pending;
      case 'paid':
        return FeeStatus.paid;
      case 'overdue':
        return FeeStatus.overdue;
      case 'waived':
        return FeeStatus.waived;
      default:
        return FeeStatus.pending;
    }
  }
}

enum MaintenanceType {
  service,
  repair,
  inspection,
  fitnessRenewal,
  insuranceRenewal,
}

extension MaintenanceTypeX on MaintenanceType {
  String get dbValue {
    switch (this) {
      case MaintenanceType.service:
        return 'service';
      case MaintenanceType.repair:
        return 'repair';
      case MaintenanceType.inspection:
        return 'inspection';
      case MaintenanceType.fitnessRenewal:
        return 'fitness_renewal';
      case MaintenanceType.insuranceRenewal:
        return 'insurance_renewal';
    }
  }

  String get displayName {
    switch (this) {
      case MaintenanceType.service:
        return 'Service';
      case MaintenanceType.repair:
        return 'Repair';
      case MaintenanceType.inspection:
        return 'Inspection';
      case MaintenanceType.fitnessRenewal:
        return 'Fitness Renewal';
      case MaintenanceType.insuranceRenewal:
        return 'Insurance Renewal';
    }
  }

  static MaintenanceType fromDb(String value) {
    switch (value) {
      case 'service':
        return MaintenanceType.service;
      case 'repair':
        return MaintenanceType.repair;
      case 'inspection':
        return MaintenanceType.inspection;
      case 'fitness_renewal':
        return MaintenanceType.fitnessRenewal;
      case 'insurance_renewal':
        return MaintenanceType.insuranceRenewal;
      default:
        return MaintenanceType.service;
    }
  }
}

