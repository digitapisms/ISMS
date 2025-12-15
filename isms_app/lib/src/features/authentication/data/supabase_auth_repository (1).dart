import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/network/supabase_client.dart';
import '../domain/app_user.dart';
import '../domain/auth_repository.dart';
import '../domain/user_role.dart';

class SupabaseAuthRepository implements AuthRepository {
  SupabaseClient get _client => SupabaseManager.client;

  @override
  Future<AppUser?> currentUser() async {
    final session = _client.auth.currentSession;
    final user = session?.user;
    if (user == null) return null;

    // Load user from database
    final rows = await _client
        .from('users')
        .select()
        .eq('auth_id', user.id)
        .limit(1);

    if (rows.isEmpty) return null;

    final row = (rows as List).first as Map<String, dynamic>;
    final roleString = row['role'] as String? ?? 'applicant';
    final schoolId = row['school_id'] as String?;

    final appUser = AppUser(
      id: user.id,
      email: user.email ?? '',
      role: UserRoleX.fromDb(roleString),
      schoolId: schoolId,
    );

    final rowId = row['id'] as String?;
    if (rowId != null) {
      unawaited(
        _client
            .from('users')
            .update({'last_login_at': DateTime.now().toIso8601String()})
            .eq('id', rowId),
      );
    }

    return appUser;
  }

  @override
  Future<AppUser> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final response = await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );

    final user = response.user;
    if (user == null) {
      throw Exception('Invalid login credentials');
    }

    // Load corresponding app user row; if missing, treat as unregistered in ISMS.
    final rows = await _client
        .from('users')
        .select()
        .eq('auth_id', user.id)
        .limit(1);

    if (rows.isEmpty) {
      throw Exception('NO_PROFILE');
    }

    final row = (rows as List).first as Map<String, dynamic>;
    final roleString = row['role'] as String? ?? 'applicant';
    final schoolId = row['school_id'] as String?;

    return AppUser(
      id: user.id,
      email: user.email ?? '',
      role: UserRoleX.fromDb(roleString),
      schoolId: schoolId,
    );
  }

  @override
  Future<AppUser> signUpWithEmail({
    required String email,
    required String password,
    required UserRole role,
    String? schoolId,
  }) async {
    final response = await _client.auth.signUp(
      email: email,
      password: password,
    );

    final user = response.user;
    if (user == null) {
      throw Exception('Sign-up failed');
    }

    // Create corresponding row in public.users table
    await _client.from('users').insert({
      'auth_id': user.id,
      'email': user.email,
      'role': role.dbValue,
      'school_id': schoolId, // Can be null for some roles
    });

    return AppUser(
      id: user.id,
      email: user.email ?? '',
      role: role,
      schoolId: schoolId,
    );
  }

  @override
  Future<void> signOut() async {
    await _client.auth.signOut();
  }
}
