import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/app_error.dart';
import '../../../core/errors/error_handler.dart';
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
        throw AuthError.invalidCredentials(
          correlationId: ErrorHandler.generateCorrelationId(),
        );
      }

      // Load corresponding app user row; if missing, treat as unregistered in ISMS.
      final rows = await _client
          .from('users')
          .select()
          .eq('auth_id', user.id)
          .limit(1);

      if (rows.isEmpty) {
        throw AuthError(
          message: 'User profile not found in database',
          userMessage:
              'Your account is not yet registered in the system. Please sign up first.',
          correlationId: ErrorHandler.generateCorrelationId(),
        );
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
      final error = ErrorHandler.handleException(e, context: 'signInWithEmail');

      // If ErrorHandler converted it properly, throw it
      if (error is AuthError) {
        throw error;
      }

      // Otherwise convert the auth exception manually
      final errorMessage = e.message.toLowerCase();
      if (errorMessage.contains('email not confirmed') ||
          errorMessage.contains('not confirmed') ||
          errorMessage.contains('email_confirmed_at')) {
        throw AuthError(
          message: 'Email not confirmed',
          userMessage:
              'Your email address has not been confirmed yet. '
              'Please check your inbox and click the confirmation link in the email we sent you. '
              'If you just confirmed your email, please wait a few seconds and try signing in again.',
          correlationId: ErrorHandler.generateCorrelationId(),
        );
      }

      // Convert to AuthError
      throw AuthError(
        message: 'Sign in failed: ${e.message}',
        userMessage:
            'Sign in failed. Please check your credentials and try again.',
        correlationId: ErrorHandler.generateCorrelationId(),
      );
    } catch (e) {
      // Re-throw AppError as-is
      if (e is AppError) {
        rethrow;
      }

      // Convert other errors
      throw ErrorHandler.handleException(e, context: 'signInWithEmail');
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
      throw AuthError(
        message: 'Sign-up failed - user object is null',
        userMessage: 'Registration failed. Please try again.',
        correlationId: ErrorHandler.generateCorrelationId(),
      );
    }

    // Check if we have a session (user might need email confirmation)
    final session = response.session;
    debugPrint(
      'SignUp response - User ID: ${user.id}, Session: ${session != null ? "exists" : "null"}',
    );

    // If no session (email confirmation required), we still need to create the user record
    // The RPC function uses SECURITY DEFINER so it should work even without session
    // But we'll check the session state

    // Create corresponding row in public.users table using RPC function
    // This bypasses RLS policies and ensures the user can create their own record
    try {
      debugPrint(
        'Calling create_user_record RPC with: auth_id=${user.id}, email=$email, role=${role.dbValue}, school_id=$schoolId',
      );

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

      // Convert exception using ErrorHandler
      final error = ErrorHandler.handleException(e, context: 'signUpWithEmail');

      // Customize user messages for common cases
      if (error is DatabaseError) {
        final errorMessage = error.message.toLowerCase();
        final details = error.details ?? {};
        final code = details['code'] as String?;

        // Check if user already exists
        if (errorMessage.contains('already exists') ||
            errorMessage.contains('duplicate') ||
            errorMessage.contains('unique') ||
            code == '23505' || // Unique violation
            code == 'P0001') {
          throw DatabaseError(
            message: error.message,
            userMessage:
                'An account with this email already exists. Please sign in instead or use a different email address.',
            correlationId: error.correlationId,
            details: error.details,
          );
        }

        // Handle invalid role
        if (errorMessage.contains('invalid role')) {
          throw ValidationError(
            message: error.message,
            userMessage: 'Invalid user role. Please contact support.',
            correlationId: error.correlationId,
            details: error.details,
          );
        }
      }

      // Re-throw the handled error
      throw error;
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
