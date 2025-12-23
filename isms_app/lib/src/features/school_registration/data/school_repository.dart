import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/app_error.dart';
import '../../../core/errors/error_handler.dart';
import '../../../core/network/supabase_client.dart';
import '../domain/global_analytics.dart';
import '../domain/school.dart';
import '../domain/school_analytics.dart';
import '../domain/tenant_onboarding_status.dart';

class SchoolRepository {
  SupabaseClient get _client => SupabaseManager.client;

  /// Register a new school
  Future<School> registerSchool({
    required String name,
    required String email,
    required String phone,
    required String principalName,
    required String principalEmail,
    required String principalPassword,
    String? address,
    String? city,
    String? state,
    String? zipCode,
    String? country,
    String? website,
    String? slogan,
    String? schoolType,
    String? groupName,
    String? boardsOrganizations,
    String? charityFoundationType,
    Uint8List? logoBytes,
    String? logoFileName,
    // New fields
    double? latitude,
    double? longitude,
    String? locationAddress,
    String? googlePlaceId,
    String? registrationType,
    String? registrationNumber,
    String? registrationBoard,
    String? province,
    String? district,
    String? tehsil,
    String? phoneSecondary,
    String? phoneLandline,
    String? whatsappNumber,
    String? faxNumber,
    String? mediumOfInstruction,
    List<String>? educationLevels,
    String? genderType,
    int? establishedYear,
    int? totalStudentsCapacity,
    String? cnicNumber,
    String? ntnNumber,
  }) async {
    // Create principal user in auth FIRST
    final authResponse = await _client.auth.signUp(
      email: principalEmail,
      password: principalPassword,
    );

    if (authResponse.user == null) {
      throw AuthError(
        message:
            'Failed to create principal account during school registration',
        userMessage:
            'Unable to create principal account. Please try again or contact support.',
      );
    }

    final principalAuthId = authResponse.user!.id;

    // Auto-confirm the user via database function (if email confirmation is enabled)
    // This allows immediate registration without email confirmation
    try {
      await _client.rpc(
        'confirm_user_email',
        params: {'user_id': principalAuthId},
      );
    } catch (e) {
      // If function doesn't exist or fails, continue anyway
      // User will need to confirm email manually
      print(
        'Note: Could not auto-confirm user. Email confirmation may be required.',
      );
    }

    // Try to get a session - if email confirmation is disabled, this will work
    // If email confirmation is enabled and auto-confirm failed, this will fail
    // In that case, we'll create the school without authentication (needs public policy)
    if (_client.auth.currentSession == null) {
      try {
        await _client.auth.signInWithPassword(
          email: principalEmail,
          password: principalPassword,
        );
      } catch (e) {
        // If sign in fails due to email not confirmed, continue anyway
        // The school insert will need a public policy to work
        if (kDebugMode) {
          debugPrint(
            'Note: User not yet confirmed. School creation will proceed if public policy exists.',
          );
        }
      }
    }

    // Upload logo if provided (now we're authenticated)
    String? logoUrl;
    if (logoBytes != null && logoFileName != null) {
      try {
        final fileName =
            '${DateTime.now().millisecondsSinceEpoch}_$logoFileName';
        await _client.storage
            .from('school-logos')
            .uploadBinary(
              fileName,
              logoBytes,
              fileOptions: const FileOptions(
                upsert: false,
                contentType: 'image/jpeg',
              ),
            );

        logoUrl = _client.storage.from('school-logos').getPublicUrl(fileName);
      } catch (e) {
        // Log error but continue with registration
        print('Error uploading logo: $e');
      }
    }

    // Try to use the comprehensive RPC function first (bypasses all RLS)
    try {
      if (kDebugMode) {
        debugPrint(
          'Attempting to use complete_school_registration RPC function...',
        );
      }
      final result = await _client.rpc(
        'complete_school_registration',
        params: {
          'p_name': name,
          'p_email': email,
          'p_phone': phone,
          'p_principal_name': principalName,
          'p_principal_email': principalEmail,
          'p_principal_auth_id': principalAuthId,
          'p_logo_url': logoUrl,
          'p_address': address,
          'p_city': city,
          'p_state': state,
          'p_zip_code': zipCode,
          'p_country': country ?? 'Pakistan',
          'p_website': website,
          'p_slogan': slogan,
          'p_school_type': schoolType,
          'p_group_name': groupName,
          'p_boards_organizations': boardsOrganizations,
          'p_charity_foundation_type': charityFoundationType,
        },
      );

      if (kDebugMode) {
        debugPrint('RPC function returned: $result');
      }

      // The function returns the complete school data as JSON
      if (result != null) {
        final schoolMap = Map<String, dynamic>.from(result as Map);
        if (kDebugMode) {
          debugPrint('Successfully created school via RPC: ${schoolMap['id']}');
        }
        return School.fromMap(schoolMap);
      } else {
        throw DatabaseError(
          message: 'complete_school_registration RPC returned null',
          userMessage:
              'School registration failed. Please try again or contact support.',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Complete registration RPC failed: $e');
        debugPrint('Falling back to step-by-step approach...');
      }
      // Convert to AppError if not already
      final error = ErrorHandler.handleException(e);
      if (error is! DatabaseError ||
          !error.message.contains('relation') &&
              !error.message.contains('function')) {
        // Re-throw if it's not a schema issue (which we handle with fallback)
        rethrow;
      }
      // Fall through to step-by-step approach
    }

    // Fallback: Step-by-step approach using RPC functions
    String schoolId = '';
    try {
      final schoolIdResult = await _client.rpc(
        'create_school',
        params: {
          'p_name': name,
          'p_email': email,
          'p_phone': phone,
          'p_logo_url': logoUrl,
          'p_address': address,
          'p_city': city,
          'p_state': state,
          'p_zip_code': zipCode,
          'p_country': country ?? 'Pakistan',
          'p_website': website,
          'p_slogan': slogan,
          'p_school_type': schoolType,
          'p_group_name': groupName,
          'p_boards_organizations': boardsOrganizations,
          'p_charity_foundation_type': charityFoundationType,
          'p_status': 'pending',
          'p_subscription_plan': 'free',
        },
      );
      schoolId = schoolIdResult as String;
    } catch (e) {
      // Last resort: direct insert (will fail if RLS blocks)
      if (kDebugMode) {
        debugPrint('RPC function not available, using direct insert: $e');
      }
      final error = ErrorHandler.handleException(e);
      final schoolResponse = await _client
          .from('schools')
          .insert({
            'name': name,
            'email': email,
            'phone': phone,
            'address': address,
            'city': city,
            'state': state,
            'zip_code': zipCode,
            'country': country ?? 'Pakistan',
            'website': website,
            'slogan': slogan,
            'school_type': schoolType,
            'group_name': groupName,
            'boards_organizations': boardsOrganizations,
            'charity_foundation_type': charityFoundationType,
            'logo_url': logoUrl,
            'status': 'pending',
            'subscription_plan': 'free',
            // New fields
            'latitude': latitude,
            'longitude': longitude,
            'location_address': locationAddress,
            'google_place_id': googlePlaceId,
            'registration_type': registrationType,
            'registration_number': registrationNumber,
            'registration_board': registrationBoard,
            'province': province,
            'district': district,
            'tehsil': tehsil,
            'phone_secondary': phoneSecondary,
            'phone_landline': phoneLandline,
            'whatsapp_number': whatsappNumber,
            'fax_number': faxNumber,
            'medium_of_instruction': mediumOfInstruction,
            'education_levels': educationLevels,
            'gender_type': genderType,
            'established_year': establishedYear,
            'total_students_capacity': totalStudentsCapacity,
            'cnic_number': cnicNumber,
            'ntn_number': ntnNumber,
          })
          .select()
          .maybeSingle();
      if (schoolResponse == null) {
        throw DatabaseError(
          message: 'School record was created but could not be fetched',
          userMessage:
              'School registration completed, but there was an issue retrieving the school details. Please try logging in.',
          details: {'table': 'schools', 'hint': 'Check RLS policies'},
        );
      }
      schoolId = schoolResponse['id'] as String;
    }

    // Create principal user using RPC function (bypasses RLS)
    try {
      await _client.rpc(
        'create_principal_user',
        params: {
          'p_auth_id': principalAuthId,
          'p_email': principalEmail,
          'p_school_id': schoolId,
          'p_principal_name': principalName,
        },
      );
    } catch (e) {
      // Fallback to direct insert
      if (kDebugMode) {
        debugPrint(
          'create_principal_user RPC not available, using direct insert: $e',
        );
      }
      final error = ErrorHandler.handleException(e);
      final userResponse = await _client
          .from('users')
          .insert({
            'auth_id': principalAuthId,
            'email': principalEmail,
            'role': 'principal',
            'school_id': schoolId,
          })
          .select('id')
          .maybeSingle();

      if (userResponse == null) {
        throw DatabaseError(
          message: 'Principal user record was created but could not be fetched',
          userMessage:
              'Principal account created, but there was an issue. Please try logging in with the principal email.',
          details: {'table': 'users', 'hint': 'Check RLS policies'},
        );
      }

      final userId = userResponse['id'] as String;

      // Create principal profile
      await _client.from('user_profiles').insert({
        'user_id': userId,
        'full_name': principalName,
      });
    }

    // Fetch the created school to return (only if we didn't use complete_school_registration)
    final schoolData = await _client
        .from('schools')
        .select()
        .eq('id', schoolId)
        .maybeSingle();

    if (schoolData == null) {
      throw DatabaseError(
        message: 'School created but could not be read back',
        userMessage:
            'School registration completed, but there was an issue. Please try logging in with the principal account.',
        details: {
          'table': 'schools',
          'hint': 'Verify principal has SELECT access',
        },
      );
    }

    return School.fromMap(Map<String, dynamic>.from(schoolData));
  }

  /// Get school by ID
  Future<School?> getSchoolById(String schoolId) async {
    final response = await _client
        .from('schools')
        .select()
        .eq('id', schoolId)
        .maybeSingle();

    if (response == null) return null;
    return School.fromMap(Map<String, dynamic>.from(response));
  }

  /// Get school by code (for user registration)
  Future<School?> getSchoolByCode(String code) async {
    final normalized = code.trim().toUpperCase();
    if (normalized.isEmpty) return null;

    // IMPORTANT: During signup the user is typically not authenticated, so RLS
    // may block direct SELECT on `schools`. Use a SECURITY DEFINER RPC that
    // safely returns the matching active school by code.
    try {
      final result = await _client.rpc(
        'get_school_by_code_public',
        params: {'p_school_code': normalized},
      );
      if (result is Map) {
        return School.fromMap(Map<String, dynamic>.from(result));
      }
    } catch (_) {
      // Fallback to direct query (works for authenticated/admin contexts)
    }

    final response = await _client
        .from('schools')
        .select()
        .eq('school_code', normalized)
        .eq('status', 'active') // Only allow active schools
        .maybeSingle();

    if (response == null) return null;
    return School.fromMap(Map<String, dynamic>.from(response));
  }

  /// Get school by user's auth ID
  Future<School?> getSchoolByUserId(String userId) async {
    final user = await _client
        .from('users')
        .select('school_id')
        .eq('auth_id', userId)
        .maybeSingle();

    if (user == null || user['school_id'] == null) return null;

    final schoolId = user['school_id'] as String;
    return getSchoolById(schoolId);
  }

  /// Update school information
  Future<void> updateSchool({
    required String schoolId,
    String? name,
    String? email,
    String? phone,
    String? address,
    String? city,
    String? state,
    String? zipCode,
    String? country,
    String? website,
    String? slogan,
    String? schoolType,
    String? groupName,
    String? boardsOrganizations,
    String? charityFoundationType,
  }) async {
    final updates = <String, dynamic>{};
    if (name != null) updates['name'] = name;
    if (email != null) updates['email'] = email;
    if (phone != null) updates['phone'] = phone;
    if (address != null) updates['address'] = address;
    if (city != null) updates['city'] = city;
    if (state != null) updates['state'] = state;
    if (zipCode != null) updates['zip_code'] = zipCode;
    if (country != null) updates['country'] = country;
    if (website != null) updates['website'] = website;
    if (slogan != null) updates['slogan'] = slogan;
    if (schoolType != null) updates['school_type'] = schoolType;
    if (groupName != null) updates['group_name'] = groupName;
    if (boardsOrganizations != null) {
      updates['boards_organizations'] = boardsOrganizations;
    }
    if (charityFoundationType != null) {
      updates['charity_foundation_type'] = charityFoundationType;
    }
    await _client.from('schools').update(updates).eq('id', schoolId);
  }

  /// Update school branding
  Future<void> updateSchoolBranding({
    required String schoolId,
    String? name,
    String? logoUrl,
    String? primaryColorHex,
    String? secondaryColorHex,
  }) async {
    final updates = <String, dynamic>{};
    if (name != null) updates['name'] = name;
    if (logoUrl != null) updates['logo_url'] = logoUrl;
    if (primaryColorHex != null) {
      updates['primary_color'] = primaryColorHex;
    }
    if (secondaryColorHex != null) {
      updates['secondary_color'] = secondaryColorHex;
    }

    await _client.from('schools').update(updates).eq('id', schoolId);
  }

  /// Get all schools (for super admin)
  Future<List<School>> getAllSchools({
    String? status,
    String? subscriptionPlan,
    String? queryText,
  }) async {
    var query = _client.from('schools').select();

    if (status != null && status.isNotEmpty) {
      query = query.eq('status', status);
    }

    if (subscriptionPlan != null && subscriptionPlan.isNotEmpty) {
      query = query.eq('subscription_plan', subscriptionPlan);
    }

    if (queryText != null && queryText.trim().isNotEmpty) {
      final value = queryText.trim();
      query = query.or(
        'name.ilike.%$value%,email.ilike.%$value%,city.ilike.%$value%',
      );
    }

    final response = await query.order('created_at', ascending: false);
    final data = response as List<dynamic>;
    return data
        .map((row) => School.fromMap(row as Map<String, dynamic>))
        .toList();
  }

  /// Update school status (for super admin)
  Future<void> updateSchoolStatus({
    required String schoolId,
    required String status,
  }) async {
    try {
      final response = await _client
          .from('schools')
          .update({'status': status})
          .eq('id', schoolId)
          .select();

      if (response.isEmpty) {
        throw DatabaseError.notFound(
          resource: 'School',
          correlationId: ErrorHandler.generateCorrelationId(),
        );
      }
    } catch (e) {
      debugPrint('Error updating school status: $e');
      rethrow;
    }
  }

  /// Update school subscription
  Future<void> updateSchoolSubscription({
    required String schoolId,
    required String plan,
    DateTime? expiresAt,
  }) async {
    await _client
        .from('schools')
        .update({
          'subscription_plan': plan,
          'subscription_expires_at': expiresAt?.toIso8601String(),
        })
        .eq('id', schoolId);
  }

  Future<SchoolAnalytics> getSchoolAnalytics(String schoolId) async {
    // Try RPC first for better performance
    try {
      final result = await _client
          .rpc('get_school_metrics', params: {'p_school_id': schoolId})
          .timeout(const Duration(seconds: 5));
      if (result is Map) {
        final map = Map<String, dynamic>.from(result);
        return SchoolAnalytics(
          totalStudents: (map['total_students'] as int?) ?? 0,
          pendingApplications: (map['pending_applications'] as int?) ?? 0,
          staffCount: (map['staff_count'] as int?) ?? 0,
          teacherCount: (map['teacher_count'] as int?) ?? 0,
          lastApplicationAt: _parseDateTime(map['last_application_at']),
          lastStudentCreatedAt: _parseDateTime(map['last_student_created_at']),
        );
      }
    } catch (e) {
      // Fall back to manual counts - log error in debug mode
      debugPrint('RPC get_school_metrics failed, using fallback: $e');
    }

    final totalStudents = await _countTable('students', schoolId);
    final pendingApplications = await _countTable(
      'applications',
      schoolId,
      equals: {'status': 'pending'},
    );
    final staffCount = await _countUsersWithRoles(schoolId, const [
      'admin',
      'principal',
      'staff',
    ]);
    final teacherCount = await _countUsersWithRoles(schoolId, const [
      'teacher',
    ]);

    final lastApplicationAt = await _latestTimestamp(
      table: 'applications',
      column: 'submitted_at',
      schoolId: schoolId,
    );
    final lastStudentCreatedAt = await _latestTimestamp(
      table: 'students',
      column: 'created_at',
      schoolId: schoolId,
    );

    return SchoolAnalytics(
      totalStudents: totalStudents,
      pendingApplications: pendingApplications,
      staffCount: staffCount,
      teacherCount: teacherCount,
      lastApplicationAt: lastApplicationAt,
      lastStudentCreatedAt: lastStudentCreatedAt,
    );
  }

  Future<TenantOnboardingStatus> getTenantOnboardingStatus(
    String schoolId,
  ) async {
    final school = await getSchoolById(schoolId);
    final profileComplete = [
      school?.address,
      school?.city,
      school?.phone,
      school?.slogan,
    ].every((value) => value != null && value.toString().trim().isNotEmpty);

    final brandingComplete =
        (school?.logoUrl?.isNotEmpty ?? false) &&
        (school?.primaryColor?.isNotEmpty ?? false) &&
        (school?.secondaryColor?.isNotEmpty ?? false);

    final classesConfigured = await _countTable('classes', schoolId) > 0;
    final staffInvited =
        await _countUsersWithRoles(schoolId, const [
          'principal',
          'admin',
          'teacher',
          'staff',
        ]) >
        1; // more than principal
    final applicationsEnabled = await _countTable('applications', schoolId) > 0;

    return TenantOnboardingStatus(
      profileComplete: profileComplete,
      brandingComplete: brandingComplete,
      classesConfigured: classesConfigured,
      staffInvited: staffInvited,
      applicationsEnabled: applicationsEnabled,
    );
  }

  Future<int> _countTable(
    String table,
    String schoolId, {
    Map<String, dynamic>? equals,
  }) async {
    try {
      var query = _client.from(table).select('id').eq('school_id', schoolId);
      equals?.forEach((key, value) {
        query = query.eq(key, value);
      });
      final response = await query;
      return (response as List).length;
    } catch (_) {
      // Ignore count errors
    }
    return 0;
  }

  Future<int> _countUsersWithRoles(String schoolId, List<String> roles) async {
    if (roles.isEmpty) return 0;
    try {
      var query = _client.from('users').select('id').eq('school_id', schoolId);
      final roleFilter = roles.map((role) => 'role.eq.$role').join(',');
      query = query.or(roleFilter);
      final response = await query;
      return (response as List).length;
    } catch (_) {}
    return 0;
  }

  Future<DateTime?> _latestTimestamp({
    required String table,
    required String column,
    required String schoolId,
  }) async {
    try {
      final response = await _client
          .from(table)
          .select(column)
          .eq('school_id', schoolId)
          .order(column, ascending: false)
          .limit(1)
          .maybeSingle();
      if (response != null && response[column] != null) {
        return _parseDateTime(response[column]);
      }
    } catch (_) {}
    return null;
  }

  DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) {
      return DateTime.tryParse(value);
    }
    return null;
  }

  /// Get global analytics across all schools (for super admin)
  Future<GlobalAnalytics> getGlobalAnalytics() async {
    try {
      // Try RPC first for better performance
      final result = await _client.rpc('get_global_analytics');
      if (result is Map) {
        final map = Map<String, dynamic>.from(result);
        return GlobalAnalytics(
          totalSchools: (map['total_schools'] as int?) ?? 0,
          totalStudents: (map['total_students'] as int?) ?? 0,
          totalApplications: (map['total_applications'] as int?) ?? 0,
          activeSchools: (map['active_schools'] as int?) ?? 0,
          pendingSchools: (map['pending_schools'] as int?) ?? 0,
          totalUsers: (map['total_users'] as int?) ?? 0,
          planDistribution: Map<String, int>.from(
            (map['plan_distribution'] as Map?) ?? {},
          ),
        );
      }
    } catch (_) {
      // Fall back to manual aggregation
    }

    // Manual aggregation
    final allSchools = await getAllSchools();
    final totalSchools = allSchools.length;
    final activeSchools = allSchools.where((s) => s.status == 'active').length;
    final pendingSchools = allSchools
        .where((s) => s.status == 'pending')
        .length;

    final planDistribution = <String, int>{};
    for (final school in allSchools) {
      final plan = school.subscriptionPlan ?? 'free';
      planDistribution[plan] = (planDistribution[plan] ?? 0) + 1;
    }

    // Count students across all schools
    int totalStudents = 0;
    int totalApplications = 0;
    int totalUsers = 0;

    for (final school in allSchools) {
      try {
        final students = await _countTable('students', school.id);
        final applications = await _countTable('applications', school.id);
        final users = await _countUsersWithRoles(school.id, const [
          'super_admin',
          'admin',
          'principal',
          'teacher',
          'staff',
          'student',
          'parent',
          'applicant',
        ]);
        totalStudents += students;
        totalApplications += applications;
        totalUsers += users;
      } catch (_) {
        // Continue if one school fails
      }
    }

    return GlobalAnalytics(
      totalSchools: totalSchools,
      totalStudents: totalStudents,
      totalApplications: totalApplications,
      activeSchools: activeSchools,
      pendingSchools: pendingSchools,
      totalUsers: totalUsers,
      planDistribution: planDistribution,
    );
  }

  /// Delete a school (for super admin)
  /// This will cascade delete all related data due to foreign key constraints
  Future<void> deleteSchool({required String schoolId}) async {
    // First, delete all users associated with this school
    // This will cascade to user_profiles, students, etc.
    await _client.from('users').delete().eq('school_id', schoolId);

    // Delete the school record
    await _client.from('schools').delete().eq('id', schoolId);
  }
}
