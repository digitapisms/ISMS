import 'package:equatable/equatable.dart';

import 'user_role.dart';

class AppUser extends Equatable {
  const AppUser({
    required this.id,
    required this.email,
    required this.role,
    this.schoolId,
  });

  final String id;
  final String email;
  final UserRole role;
  final String? schoolId;

  @override
  List<Object?> get props => [id, email, role, schoolId];
}
