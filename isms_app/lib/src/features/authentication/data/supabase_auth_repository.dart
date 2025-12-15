import 'dart:async';

import 'package:flutter/foundation.dart';
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
    try {
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
    } on AuthException catch (e) {
      // Handle Supabase auth-specific errors
      final errorMessage = e.message.toLowerCase();
      if (errorMessage.contains('email not confirmed') ||
          errorMessage.contains('not confirmed') ||
          errorMessage.contains('email_confirmed_at')) {
        throw Exception(
          'Your email address has not been confirmed yet. '
          'Please check your inbox and click the confirmation link in the email we sent you. '
          'If you just confirmed your email, please wait a few seconds and try signing in again.',
        );
      }
      // Re-throw other auth exceptions
      throw Exception('Sign in failed: ${e.message}');
    } catch (e) {
      // Re-throw with better message if it's already an Exception
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Sign in failed: ${e.toString()}');
    }
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

    // Check if we have a session (user might need email confirmation)
    final session = response.session;
    debugPrint('SignUp response - User ID: ${user.id}, Session: ${session != null ? "exists" : "null"}');
    
    // If no session (email confirmation required), we still need to create the user record
    // The RPC function uses SECURITY DEFINER so it should work even without session
    // But we'll check the session state

    // Create corresponding row in public.users table using RPC function
    // This bypasses RLS policies and ensures the user can create their own record
    try {
      debugPrint('Calling create_user_record RPC with: auth_id=${user.id}, email=$email, role=${role.dbValue}, school_id=$schoolId');
      
      final result = await _client.rpc(
        'create_user_record',
        params: {
          'p_auth_id': user.id,
          'p_email': user.email ?? email,
          'p_role': role.dbValue,
          'p_school_id': schoolId,
        },
      );
      
      debugPrint('RPC create_user_record succeeded: $result');
    } catch (e) {
      // Log the error for debugging
      debugPrint('RPC create_user_record failed: $e');
      debugPrint('Error type: ${e.runtimeType}');
      
      // Handle PostgrestException specifically
      if (e is PostgrestException) {
        final errorMessage = e.message.toLowerCase();
        
        // Check if user already exists (multiple ways this can be expressed)
        if (errorMessage.contains('already exists') || 
            errorMessage.contains('duplicate') ||
            errorMessage.contains('unique') ||
            e.code == 'P0001') {
          throw Exception('An account with this email already exists. Please sign in instead or use a different email address.');
        }
        
        // Handle invalid role
        if (errorMessage.contains('invalid role')) {
          throw Exception('Invalid user role. Please contact support.');
        }
        
        // Other PostgrestException errors
        throw Exception(
          'Registration failed: ${e.message}. Please try again or contact support.',
        );
      }
      
      // Handle non-PostgrestException errors
      final errorMessage = e.toString().toLowerCase();
      if (errorMessage.contains('already exists') || 
          errorMessage.contains('duplicate') ||
          errorMessage.contains('unique')) {
        throw Exception('An account with this email already exists. Please sign in instead or use a different email address.');
      }
      
      // Generic error
      throw Exception(
        'Registration failed. Please try again or contact support if the problem persists.',
      );
    }

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
