import 'package:equatable/equatable.dart';

import '../../authentication/domain/user_role.dart';

class StaffInvite extends Equatable {
  const StaffInvite({
    required this.id,
    required this.schoolId,
    required this.email,
    required this.role,
    required this.status,
    required this.code,
    this.fullName,
    this.invitedBy,
    this.notes,
    this.expiresAt,
    this.acceptedAt,
    this.createdAt,
  });

  final String id;
  final String schoolId;
  final String email;
  final UserRole role;
  final String status;
  final String code;
  final String? fullName;
  final String? invitedBy;
  final String? notes;
  final DateTime? expiresAt;
  final DateTime? acceptedAt;
  final DateTime? createdAt;

  factory StaffInvite.fromMap(Map<String, dynamic> map) {
    return StaffInvite(
      id: map['id'] as String,
      schoolId: map['school_id'] as String,
      email: map['email'] as String,
      role: _mapRole(map['role'] as String?),
      status: map['status'] as String? ?? 'pending',
      code: map['invite_code'] as String,
      fullName: map['full_name'] as String?,
      invitedBy: map['invited_by'] as String?,
      notes: map['notes'] as String?,
      expiresAt: map['expires_at'] != null
          ? DateTime.tryParse(map['expires_at'] as String)
          : null,
      acceptedAt: map['accepted_at'] != null
          ? DateTime.tryParse(map['accepted_at'] as String)
          : null,
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'] as String)
          : null,
    );
  }

  static UserRole _mapRole(String? value) {
    switch (value) {
      case 'admin':
        return UserRole.admin;
      case 'principal':
        return UserRole.principal;
      case 'teacher':
        return UserRole.teacher;
      case 'staff':
      default:
        return UserRole.staff;
    }
  }

  @override
  List<Object?> get props => [
    id,
    schoolId,
    email,
    role,
    status,
    code,
    fullName,
    invitedBy,
    notes,
    expiresAt,
    acceptedAt,
    createdAt,
  ];
}
