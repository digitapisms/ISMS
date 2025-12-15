enum UserRole {
  superAdmin,
  admin,
  principal,
  teacher,
  staff,
  student,
  parent,
  applicant,
}

extension UserRoleX on UserRole {
  String get label {
    switch (this) {
      case UserRole.superAdmin:
        return 'Super Admin';
      case UserRole.admin:
        return 'Admin';
      case UserRole.principal:
        return 'Principal';
      case UserRole.teacher:
        return 'Teacher';
      case UserRole.staff:
        return 'Staff';
      case UserRole.student:
        return 'Student';
      case UserRole.parent:
        return 'Parent';
      case UserRole.applicant:
        return 'Applicant';
    }
  }

  String get dbValue {
    switch (this) {
      case UserRole.superAdmin:
        return 'super_admin';
      case UserRole.admin:
        return 'admin';
      case UserRole.principal:
        return 'principal';
      case UserRole.teacher:
        return 'teacher';
      case UserRole.staff:
        return 'staff';
      case UserRole.student:
        return 'student';
      case UserRole.parent:
        return 'parent';
      case UserRole.applicant:
        return 'applicant';
    }
  }

  bool get isStaff =>
      this == UserRole.superAdmin ||
      this == UserRole.admin ||
      this == UserRole.principal ||
      this == UserRole.teacher ||
      this == UserRole.staff;

  bool get canManageTenants => this == UserRole.superAdmin;

  static UserRole fromDb(String value) {
    switch (value) {
      case 'super_admin':
        return UserRole.superAdmin;
      case 'admin':
        return UserRole.admin;
      case 'principal':
        return UserRole.principal;
      case 'teacher':
        return UserRole.teacher;
      case 'staff':
        return UserRole.staff;
      case 'student':
        return UserRole.student;
      case 'parent':
        return UserRole.parent;
      case 'applicant':
      default:
        return UserRole.applicant;
    }
  }
}
