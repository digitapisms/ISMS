import 'package:equatable/equatable.dart';

import '../../authentication/domain/user_role.dart';

class StaffMember extends Equatable {
  const StaffMember({
    required this.id,
    required this.authId,
    required this.schoolId,
    required this.email,
    required this.role,
    required this.status,
    this.fullName,
    this.phoneNumber,
    this.avatarUrl,
    this.lastLoginAt,
    this.createdAt,
  });

  final String id;
  final String authId;
  final String schoolId;
  final String email;
  final UserRole role;
  final String status;
  final String? fullName;
  final String? phoneNumber;
  final String? avatarUrl;
  final DateTime? lastLoginAt;
  final DateTime? createdAt;

  factory StaffMember.fromMap(Map<String, dynamic> map) {
    final profile = map['user_profiles'] as Map<String, dynamic>?;
    return StaffMember(
      id: map['id'] as String,
      authId: map['auth_id'] as String,
      schoolId: map['school_id'] as String,
      email: map['email'] as String,
      role: _mapRole(map['role'] as String?),
      status: map['status'] as String? ?? 'active',
      fullName: profile?['full_name'] as String?,
      phoneNumber: profile?['phone_number'] as String?,
      avatarUrl: profile?['avatar_url'] as String?,
      lastLoginAt: map['last_login_at'] != null
          ? DateTime.tryParse(map['last_login_at'] as String)
          : null,
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'] as String)
          : null,
    );
  }

  StaffMember copyWith({
    UserRole? role,
    String? status,
    String? fullName,
    String? phoneNumber,
    String? avatarUrl,
  }) {
    return StaffMember(
      id: id,
      authId: authId,
      schoolId: schoolId,
      email: email,
      role: role ?? this.role,
      status: status ?? this.status,
      fullName: fullName ?? this.fullName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      lastLoginAt: lastLoginAt,
      createdAt: createdAt,
    );
  }

  static UserRole _mapRole(String? value) {
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
      default:
        return UserRole.staff;
    }
  }

  @override
  List<Object?> get props => [
    id,
    authId,
    schoolId,
    email,
    role,
    status,
    fullName,
    phoneNumber,
    avatarUrl,
    lastLoginAt,
    createdAt,
  ];
}
