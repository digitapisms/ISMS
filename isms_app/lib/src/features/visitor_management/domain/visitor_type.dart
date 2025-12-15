enum VisitorType {
  guest,
  parent,
  vendor,
  official,
  contractor,
  other,
}

extension VisitorTypeX on VisitorType {
  String get dbValue {
    switch (this) {
      case VisitorType.guest:
        return 'guest';
      case VisitorType.parent:
        return 'parent';
      case VisitorType.vendor:
        return 'vendor';
      case VisitorType.official:
        return 'official';
      case VisitorType.contractor:
        return 'contractor';
      case VisitorType.other:
        return 'other';
    }
  }

  String get displayName {
    switch (this) {
      case VisitorType.guest:
        return 'Guest';
      case VisitorType.parent:
        return 'Parent';
      case VisitorType.vendor:
        return 'Vendor';
      case VisitorType.official:
        return 'Official';
      case VisitorType.contractor:
        return 'Contractor';
      case VisitorType.other:
        return 'Other';
    }
  }

  static VisitorType fromDb(String value) {
    switch (value) {
      case 'guest':
        return VisitorType.guest;
      case 'parent':
        return VisitorType.parent;
      case 'vendor':
        return VisitorType.vendor;
      case 'official':
        return VisitorType.official;
      case 'contractor':
        return VisitorType.contractor;
      case 'other':
        return VisitorType.other;
      default:
        return VisitorType.guest;
    }
  }
}

enum VisitPurpose {
  meeting,
  pickup,
  delivery,
  interview,
  event,
  maintenance,
  inspection,
  other,
}

extension VisitPurposeX on VisitPurpose {
  String get dbValue {
    switch (this) {
      case VisitPurpose.meeting:
        return 'meeting';
      case VisitPurpose.pickup:
        return 'pickup';
      case VisitPurpose.delivery:
        return 'delivery';
      case VisitPurpose.interview:
        return 'interview';
      case VisitPurpose.event:
        return 'event';
      case VisitPurpose.maintenance:
        return 'maintenance';
      case VisitPurpose.inspection:
        return 'inspection';
      case VisitPurpose.other:
        return 'other';
    }
  }

  String get displayName {
    switch (this) {
      case VisitPurpose.meeting:
        return 'Meeting';
      case VisitPurpose.pickup:
        return 'Pickup';
      case VisitPurpose.delivery:
        return 'Delivery';
      case VisitPurpose.interview:
        return 'Interview';
      case VisitPurpose.event:
        return 'Event';
      case VisitPurpose.maintenance:
        return 'Maintenance';
      case VisitPurpose.inspection:
        return 'Inspection';
      case VisitPurpose.other:
        return 'Other';
    }
  }

  static VisitPurpose fromDb(String value) {
    switch (value) {
      case 'meeting':
        return VisitPurpose.meeting;
      case 'pickup':
        return VisitPurpose.pickup;
      case 'delivery':
        return VisitPurpose.delivery;
      case 'interview':
        return VisitPurpose.interview;
      case 'event':
        return VisitPurpose.event;
      case 'maintenance':
        return VisitPurpose.maintenance;
      case 'inspection':
        return VisitPurpose.inspection;
      case 'other':
        return VisitPurpose.other;
      default:
        return VisitPurpose.meeting;
    }
  }
}

enum VisitStatus {
  scheduled,
  checkedIn,
  checkedOut,
  cancelled,
  noShow,
}

extension VisitStatusX on VisitStatus {
  String get dbValue {
    switch (this) {
      case VisitStatus.scheduled:
        return 'scheduled';
      case VisitStatus.checkedIn:
        return 'checked_in';
      case VisitStatus.checkedOut:
        return 'checked_out';
      case VisitStatus.cancelled:
        return 'cancelled';
      case VisitStatus.noShow:
        return 'no_show';
    }
  }

  String get displayName {
    switch (this) {
      case VisitStatus.scheduled:
        return 'Scheduled';
      case VisitStatus.checkedIn:
        return 'Checked In';
      case VisitStatus.checkedOut:
        return 'Checked Out';
      case VisitStatus.cancelled:
        return 'Cancelled';
      case VisitStatus.noShow:
        return 'No Show';
    }
  }

  static VisitStatus fromDb(String value) {
    switch (value) {
      case 'scheduled':
        return VisitStatus.scheduled;
      case 'checked_in':
        return VisitStatus.checkedIn;
      case 'checked_out':
        return VisitStatus.checkedOut;
      case 'cancelled':
        return VisitStatus.cancelled;
      case 'no_show':
        return VisitStatus.noShow;
      default:
        return VisitStatus.scheduled;
    }
  }
}

enum HostType {
  student,
  staff,
  admin,
  department,
}

extension HostTypeX on HostType {
  String get dbValue {
    switch (this) {
      case HostType.student:
        return 'student';
      case HostType.staff:
        return 'staff';
      case HostType.admin:
        return 'admin';
      case HostType.department:
        return 'department';
    }
  }

  String get displayName {
    switch (this) {
      case HostType.student:
        return 'Student';
      case HostType.staff:
        return 'Staff';
      case HostType.admin:
        return 'Admin';
      case HostType.department:
        return 'Department';
    }
  }

  static HostType fromDb(String value) {
    switch (value) {
      case 'student':
        return HostType.student;
      case 'staff':
        return HostType.staff;
      case 'admin':
        return HostType.admin;
      case 'department':
        return HostType.department;
      default:
        return HostType.staff;
    }
  }
}

enum ActionType {
  checkIn,
  checkOut,
  badgeIssued,
  badgeReturned,
  securityAlert,
}

extension ActionTypeX on ActionType {
  String get dbValue {
    switch (this) {
      case ActionType.checkIn:
        return 'check_in';
      case ActionType.checkOut:
        return 'check_out';
      case ActionType.badgeIssued:
        return 'badge_issued';
      case ActionType.badgeReturned:
        return 'badge_returned';
      case ActionType.securityAlert:
        return 'security_alert';
    }
  }

  static ActionType fromDb(String value) {
    switch (value) {
      case 'check_in':
        return ActionType.checkIn;
      case 'check_out':
        return ActionType.checkOut;
      case 'badge_issued':
        return ActionType.badgeIssued;
      case 'badge_returned':
        return ActionType.badgeReturned;
      case 'security_alert':
        return ActionType.securityAlert;
      default:
        return ActionType.checkIn;
    }
  }
}

enum EntryType {
  visitor,
  staff,
  student,
  vehicle,
  emergency,
}

extension EntryTypeX on EntryType {
  String get dbValue {
    switch (this) {
      case EntryType.visitor:
        return 'visitor';
      case EntryType.staff:
        return 'staff';
      case EntryType.student:
        return 'student';
      case EntryType.vehicle:
        return 'vehicle';
      case EntryType.emergency:
        return 'emergency';
    }
  }

  static EntryType fromDb(String value) {
    switch (value) {
      case 'visitor':
        return EntryType.visitor;
      case 'staff':
        return EntryType.staff;
      case 'student':
        return EntryType.student;
      case 'vehicle':
        return EntryType.vehicle;
      case 'emergency':
        return EntryType.emergency;
      default:
        return EntryType.visitor;
    }
  }
}

enum AlertLevel {
  normal,
  low,
  medium,
  high,
  critical,
}

extension AlertLevelX on AlertLevel {
  String get dbValue {
    switch (this) {
      case AlertLevel.normal:
        return 'normal';
      case AlertLevel.low:
        return 'low';
      case AlertLevel.medium:
        return 'medium';
      case AlertLevel.high:
        return 'high';
      case AlertLevel.critical:
        return 'critical';
    }
  }

  String get displayName {
    switch (this) {
      case AlertLevel.normal:
        return 'Normal';
      case AlertLevel.low:
        return 'Low';
      case AlertLevel.medium:
        return 'Medium';
      case AlertLevel.high:
        return 'High';
      case AlertLevel.critical:
        return 'Critical';
    }
  }

  static AlertLevel fromDb(String value) {
    switch (value) {
      case 'normal':
        return AlertLevel.normal;
      case 'low':
        return AlertLevel.low;
      case 'medium':
        return AlertLevel.medium;
      case 'high':
        return AlertLevel.high;
      case 'critical':
        return AlertLevel.critical;
      default:
        return AlertLevel.normal;
    }
  }
}

