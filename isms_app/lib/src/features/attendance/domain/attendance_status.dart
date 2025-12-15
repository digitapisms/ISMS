enum AttendanceStatus {
  present,
  absent,
  late,
  excused,
  halfDay;

  String get displayName {
    switch (this) {
      case AttendanceStatus.present:
        return 'Present';
      case AttendanceStatus.absent:
        return 'Absent';
      case AttendanceStatus.late:
        return 'Late';
      case AttendanceStatus.excused:
        return 'Excused';
      case AttendanceStatus.halfDay:
        return 'Half Day';
    }
  }

  String get dbValue {
    switch (this) {
      case AttendanceStatus.present:
        return 'present';
      case AttendanceStatus.absent:
        return 'absent';
      case AttendanceStatus.late:
        return 'late';
      case AttendanceStatus.excused:
        return 'excused';
      case AttendanceStatus.halfDay:
        return 'half_day';
    }
  }

  static AttendanceStatus fromDb(String value) {
    switch (value.toLowerCase()) {
      case 'present':
        return AttendanceStatus.present;
      case 'absent':
        return AttendanceStatus.absent;
      case 'late':
        return AttendanceStatus.late;
      case 'excused':
        return AttendanceStatus.excused;
      case 'half_day':
      case 'halfday':
        return AttendanceStatus.halfDay;
      default:
        return AttendanceStatus.present;
    }
  }
}
