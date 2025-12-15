import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/network/supabase_client.dart';
import '../domain/student.dart';

class StudentRepository {
  SupabaseClient get _client => SupabaseManager.client;
  String? _schoolId;

  void setSchoolId(String? schoolId) {
    _schoolId = schoolId;
  }

  String? get schoolId => _schoolId;

  String _requireSchoolId() {
    final id = _schoolId;
    if (id == null) {
      throw Exception(
        'School context is required for this action. Please ensure you are signed in to a school tenant.',
      );
    }
    return id;
  }

  Map<String, dynamic> _withSchoolId(
    Map<String, dynamic> data, {
    String? override,
  }) {
    final id = override ?? _schoolId;
    if (id == null) return data;
    return {...data, 'school_id': id};
  }

  dynamic _filterBySchool(dynamic query, {String? override}) {
    final id = override ?? _schoolId;
    if (id == null) return query;
    return query.eq('school_id', id);
  }

  Future<List<Student>> fetchStudents() async {
    var query = _client.from('students_view').select();
    query = _filterBySchool(query);

    final response = await query.order('created_at', ascending: false);

    final data = response as List<dynamic>;
    return data
        .map((row) => Student.fromMap(row as Map<String, dynamic>))
        .toList();
  }

  Future<Student?> fetchStudentById(String studentId) async {
    var query = _client.from('students_view').select().eq('id', studentId);
    query = _filterBySchool(query);
    final response = await query.maybeSingle();

    if (response == null) return null;
    return Student.fromMap(Map<String, dynamic>.from(response));
  }

  /// Fetch student by user_id (from users table)
  Future<Student?> fetchStudentByUserId(String userId) async {
    // First get the user's auth_id to find the student
    final userRow = await _client
        .from('users')
        .select('id, auth_id')
        .eq('id', userId)
        .maybeSingle();

    if (userRow == null) return null;

    final authId = userRow['auth_id'] as String?;
    if (authId == null) return null;

    // Find student linked to this user
    var query = _client.from('students').select('id').eq('user_id', userId);
    query = _filterBySchool(query);
    final studentRow = await query.maybeSingle();

    if (studentRow == null) return null;

    final studentId = studentRow['id'] as String;
    return fetchStudentById(studentId);
  }

  /// Fetch current student from authenticated user's auth_id
  Future<Student?> fetchCurrentStudent() async {
    final authUser = _client.auth.currentUser;
    if (authUser == null) return null;

    // Get user record from users table
    final userRow = await _client
        .from('users')
        .select('id')
        .eq('auth_id', authUser.id)
        .maybeSingle();

    if (userRow == null) return null;

    final userId = userRow['id'] as String;
    return fetchStudentByUserId(userId);
  }

  Future<List<Map<String, dynamic>>> fetchStudentDocuments(
    String studentId,
  ) async {
    var query = _client
        .from('student_documents')
        .select()
        .eq('student_id', studentId)
        .order('uploaded_at', ascending: false);
    query = _filterBySchool(query);
    final response = await query;

    return List<Map<String, dynamic>>.from(response as List);
  }

  Future<List<Map<String, dynamic>>> fetchStudentFamily(
    String studentId,
  ) async {
    var query = _client
        .from('family_members')
        .select()
        .eq('student_id', studentId);
    query = _filterBySchool(query);
    final response = await query;

    return List<Map<String, dynamic>>.from(response as List);
  }

  Future<List<Map<String, dynamic>>> fetchStudentEmergencyContacts(
    String studentId,
  ) async {
    var query = _client
        .from('emergency_contacts')
        .select()
        .eq('student_id', studentId);
    query = _filterBySchool(query);
    final response = await query;

    return List<Map<String, dynamic>>.from(response as List);
  }

  Future<void> createStudent({
    required String admissionNo,
    required String fullName,
  }) async {
    final schoolId = _requireSchoolId();
    await _client.from('students').insert({
      'admission_no': admissionNo,
      'status': 'active',
      'school_id': schoolId,
    });
  }

  Future<void> updateStudent({
    required String studentId,
    int? classId,
    int? sectionId,
    String? status,
    DateTime? dob,
    String? gender,
    String? bloodGroup,
    String? medicalInfo,
  }) async {
    final schoolId = _requireSchoolId();
    // Update students table
    final studentUpdate = <String, dynamic>{};
    if (classId != null) studentUpdate['class_id'] = classId;
    if (sectionId != null) studentUpdate['section_id'] = sectionId;
    if (status != null) studentUpdate['status'] = status;

    if (studentUpdate.isNotEmpty) {
      await _client
          .from('students')
          .update(studentUpdate)
          .eq('id', studentId)
          .eq('school_id', schoolId);
    }

    // Update or insert student_details
    final detailsUpdate = <String, dynamic>{};
    if (dob != null) detailsUpdate['dob'] = dob.toIso8601String().split('T')[0];
    if (gender != null) detailsUpdate['gender'] = gender;
    if (bloodGroup != null) detailsUpdate['blood_group'] = bloodGroup;
    if (medicalInfo != null) detailsUpdate['medical_info'] = medicalInfo;

    if (detailsUpdate.isNotEmpty) {
      // Check if student_details exists
      final existing = await _client
          .from('student_details')
          .select()
          .eq('student_id', studentId)
          .eq('school_id', schoolId)
          .maybeSingle();

      if (existing != null) {
        await _client
            .from('student_details')
            .update(detailsUpdate)
            .eq('student_id', studentId)
            .eq('school_id', schoolId);
      } else {
        detailsUpdate['student_id'] = studentId;
        await _client
            .from('student_details')
            .insert(_withSchoolId(detailsUpdate));
      }
    }
  }

  Future<void> addFamilyMember({
    required String studentId,
    required String relation,
    required String name,
    String? contact,
    String? occupation,
  }) async {
    await _client
        .from('family_members')
        .insert(
          _withSchoolId({
            'student_id': studentId,
            'relation': relation,
            'name': name,
            'contact': contact,
            'occupation': occupation,
          }),
        );
  }

  Future<void> addEmergencyContact({
    required String studentId,
    required String name,
    required String phone,
    String? relation,
  }) async {
    await _client
        .from('emergency_contacts')
        .insert(
          _withSchoolId({
            'student_id': studentId,
            'name': name,
            'phone': phone,
            'relation': relation,
          }),
        );
  }

  Future<List<Map<String, dynamic>>> fetchClasses() async {
    var query = _client.from('classes').select().order('name');
    query = _filterBySchool(query);
    final response = await query;
    return List<Map<String, dynamic>>.from(response as List);
  }

  Future<List<Map<String, dynamic>>> fetchSections(int classId) async {
    var query = _client
        .from('sections')
        .select()
        .eq('class_id', classId)
        .order('name');
    query = _filterBySchool(query);
    final response = await query;
    return List<Map<String, dynamic>>.from(response as List);
  }

  Future<String> submitStudentApplication({
    required String applicantUserId,
    required String schoolId,
    required String firstName,
    required String lastName,
    DateTime? dob,
    String? gender,
    String? bloodGroup,
    String? nationality,
    String? religion,
    String? medicalInfo,
    int? desiredClassId,
    String? previousSchool,
    String? address,
    String? city,
    String? state,
    String? zipCode,
    String? fatherName,
    String? fatherContact,
    String? fatherOccupation,
    String? motherName,
    String? motherContact,
    String? motherOccupation,
    String? guardianName,
    String? guardianContact,
    String? guardianRelation,
    required String emergencyName,
    required String emergencyPhone,
    String? emergencyRelation,
    String? transportRequired,
    String? transportRoute,
  }) async {
    // Get the user's users table id
    final userRows = await _client
        .from('users')
        .select('id, school_id')
        .eq('auth_id', applicantUserId)
        .limit(1);

    if (userRows.isEmpty) {
      throw Exception('User not found');
    }

    final row = (userRows as List).first as Map<String, dynamic>;
    final userId = row['id'] as String;
    final existingSchoolId = row['school_id'] as String?;

    if (existingSchoolId == null) {
      await _client
          .from('users')
          .update({'school_id': schoolId})
          .eq('id', userId);
    }

    // Create application
    await _client.from('applications').insert({
      'applicant_user_id': userId,
      'desired_class_id': desiredClassId,
      'status': 'pending',
      'school_id': schoolId,
    });

    // Update user profile with name
    await _client.from('user_profiles').upsert({
      'user_id': userId,
      'full_name': '$firstName $lastName',
    });

    // Create student record (will be linked after approval)
    final studentResponse = await _client.from('students').insert({
      'admission_no': 'TEMP-${DateTime.now().millisecondsSinceEpoch}',
      'user_id': userId,
      'class_id': desiredClassId,
      'section_id': null,
      'status': 'pending',
      'school_id': schoolId,
    }).select();

    final studentId = (studentResponse as List).first['id'] as String;

    // Create student_details
    await _client
        .from('student_details')
        .insert(
          _withSchoolId({
            'student_id': studentId,
            'dob': dob?.toIso8601String().split('T')[0],
            'gender': gender,
            'blood_group': bloodGroup,
            'nationality': nationality,
            'religion': religion,
            'medical_info': medicalInfo,
            'transport_required': transportRequired == 'yes',
            'transport_route': transportRoute,
          }, override: schoolId),
        );

    // Add family members
    if (fatherName != null && fatherName.isNotEmpty) {
      await _client
          .from('family_members')
          .insert(
            _withSchoolId({
              'student_id': studentId,
              'relation': 'Father',
              'name': fatherName,
              'contact': fatherContact,
              'occupation': fatherOccupation,
            }, override: schoolId),
          );
    }

    if (motherName != null && motherName.isNotEmpty) {
      await _client
          .from('family_members')
          .insert(
            _withSchoolId({
              'student_id': studentId,
              'relation': 'Mother',
              'name': motherName,
              'contact': motherContact,
              'occupation': motherOccupation,
            }, override: schoolId),
          );
    }

    if (guardianName != null && guardianName.isNotEmpty) {
      await _client
          .from('family_members')
          .insert(
            _withSchoolId({
              'student_id': studentId,
              'relation': guardianRelation ?? 'Guardian',
              'name': guardianName,
              'contact': guardianContact,
              'occupation': null,
            }, override: schoolId),
          );
    }

    // Add emergency contact
    await _client
        .from('emergency_contacts')
        .insert(
          _withSchoolId({
            'student_id': studentId,
            'name': emergencyName,
            'phone': emergencyPhone,
            'relation': emergencyRelation,
          }, override: schoolId),
        );

    // Update user profile with address if provided
    if (address != null || city != null || state != null) {
      await _client
          .from('user_profiles')
          .update({
            'address': address,
            'city': city,
            'state': state,
            'zip_code': zipCode,
          })
          .eq('user_id', userId);
    }

    return studentId;
  }

  Future<Map<String, dynamic>?> fetchApplicationStatus(String userId) async {
    final userRows = await _client
        .from('users')
        .select('id')
        .eq('auth_id', userId)
        .limit(1);

    if (userRows.isEmpty) return null;

    final appUserId = (userRows as List).first['id'] as String;

    final response = await _client
        .from('applications')
        .select('''
          *,
          classes(name, code)
        ''')
        .eq('applicant_user_id', appUserId)
        .order('submitted_at', ascending: false)
        .limit(1)
        .maybeSingle();

    if (response == null) return null;
    return Map<String, dynamic>.from(response);
  }

  Future<String> uploadDocument({
    required String studentId,
    required String documentType,
    required List<int> fileBytes,
    required String fileName,
    String? schoolId,
  }) async {
    // Upload file to Supabase Storage
    await _client.storage
        .from('student-documents')
        .uploadBinary(
          '$studentId/$documentType/$fileName',
          Uint8List.fromList(fileBytes),
        );

    // Get public URL
    final url = _client.storage
        .from('student-documents')
        .getPublicUrl('$studentId/$documentType/$fileName');

    // Save document record
    await _client
        .from('student_documents')
        .insert(
          _withSchoolId({
            'student_id': studentId,
            'document_type': documentType,
            'file_url': url,
          }, override: schoolId),
        );

    return url;
  }

  Future<List<Map<String, dynamic>>> fetchPendingApplications() async {
    var query = _client
        .from('applications')
        .select('''
          *,
          classes(name, code),
          users!applicant_user_id(email, user_profiles(full_name))
        ''')
        .or('status.eq.pending,status.eq.under_review')
        .order('submitted_at', ascending: false);
    query = _filterBySchool(query);
    final response = await query;

    return List<Map<String, dynamic>>.from(response as List);
  }

  Future<void> updateApplicationStatus({
    required String applicationId,
    required String status,
    String? remarks,
  }) async {
    final schoolId = _requireSchoolId();
    // Get application details before update for email notification
    final appBefore = await _client
        .from('applications')
        .select('''
          *,
          users!applicant_user_id(email, user_profiles(full_name))
        ''')
        .eq('id', applicationId)
        .eq('school_id', schoolId)
        .maybeSingle();

    await _client
        .from('applications')
        .update({
          'status': status,
          'reviewed_at': DateTime.now().toIso8601String(),
          'remarks': remarks,
        })
        .eq('id', applicationId)
        .eq('school_id', schoolId);

    // If approved, update student status to active
    if (status == 'approved') {
      final app = await _client
          .from('applications')
          .select('applicant_user_id')
          .eq('id', applicationId)
          .eq('school_id', schoolId)
          .single();

      final userId = app['applicant_user_id'] as String;

      // Find student record
      final student = await _client
          .from('students')
          .select('id')
          .eq('user_id', userId)
          .eq('school_id', schoolId)
          .maybeSingle();

      if (student != null) {
        await _client
            .from('students')
            .update({'status': 'active'})
            .eq('id', student['id']);
      }

      // Update user role to student
      await _client.from('users').update({'role': 'student'}).eq('id', userId);
    }

    // Send email notification (if notification service is available)
    if (appBefore != null) {
      try {
        final users = appBefore['users'] as Map<String, dynamic>?;
        final email = users?['email'] as String?;

        if (email != null) {
          // Import and use email notification service
          // Note: This will be handled by the calling code to avoid circular dependencies
        }
      } catch (e) {
        // Ignore notification errors
        print('Notification error: $e');
      }
    }
  }

  Future<Map<String, dynamic>?> fetchApplicationDetails(
    String applicationId,
  ) async {
    var query = _client
        .from('applications')
        .select('''
          *,
          classes(name, code),
          users!applicant_user_id(
            id,
            email,
            user_profiles(*)
          )
        ''')
        .eq('id', applicationId);
    query = _filterBySchool(query);
    final response = await query.maybeSingle();

    if (response == null) return null;
    final applicationSchoolId = response['school_id'] as String?;

    // Get student details
    final userId = (response['users'] as Map)['id'] as String;
    var studentQuery = _client
        .from('students')
        .select('id')
        .eq('user_id', userId);
    studentQuery = _filterBySchool(studentQuery, override: applicationSchoolId);
    final student = await studentQuery.maybeSingle();

    if (student != null) {
      final studentId = student['id'] as String;

      var detailsQuery = _client
          .from('student_details')
          .select()
          .eq('student_id', studentId);
      detailsQuery = _filterBySchool(
        detailsQuery,
        override: applicationSchoolId,
      );
      final studentDetails = await detailsQuery.maybeSingle();

      var familyQuery = _client
          .from('family_members')
          .select()
          .eq('student_id', studentId);
      familyQuery = _filterBySchool(familyQuery, override: applicationSchoolId);

      var emergencyQuery = _client
          .from('emergency_contacts')
          .select()
          .eq('student_id', studentId);
      emergencyQuery = _filterBySchool(
        emergencyQuery,
        override: applicationSchoolId,
      );

      final family = await familyQuery;
      final emergency = await emergencyQuery;

      return {
        ...response,
        'student_details': studentDetails,
        'family_members': family,
        'emergency_contacts': emergency,
      };
    }

    return response;
  }

  // Application Fee Payment
  Future<Map<String, dynamic>?> fetchApplicationFee(
    String applicationId,
  ) async {
    var query = _client
        .from('application_fees')
        .select()
        .eq('application_id', applicationId);
    query = _filterBySchool(query);
    final response = await query.maybeSingle();
    if (response == null) return null;
    return Map<String, dynamic>.from(response);
  }

  Future<void> createApplicationFee({
    required String applicationId,
    required double amount,
  }) async {
    await _client
        .from('application_fees')
        .insert(
          _withSchoolId({
            'application_id': applicationId,
            'amount': amount,
            'payment_status': 'pending',
          }),
        );
  }

  Future<void> updatePaymentStatus({
    required String applicationId,
    required String status,
    String? transactionId,
  }) async {
    var query = _client
        .from('application_fees')
        .update({
          'payment_status': status,
          'payment_date': status == 'paid'
              ? DateTime.now().toIso8601String()
              : null,
          'transaction_id': transactionId,
        })
        .eq('application_id', applicationId);
    query = _filterBySchool(query);
    await query;
  }

  // Update Application
  Future<void> updateStudentApplication({
    required String applicationId,
    required String userId,
    String? firstName,
    String? lastName,
    DateTime? dob,
    String? gender,
    String? bloodGroup,
    String? nationality,
    String? religion,
    String? medicalInfo,
    int? desiredClassId,
    String? previousSchool,
    String? address,
    String? city,
    String? state,
    String? zipCode,
    String? transportRequired,
    String? transportRoute,
  }) async {
    final schoolId = _requireSchoolId();
    // Update application
    await _client
        .from('applications')
        .update({
          'desired_class_id': desiredClassId,
          'previous_school': previousSchool,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', applicationId)
        .eq('school_id', schoolId);

    // Find student
    final student = await _client
        .from('students')
        .select('id')
        .eq('user_id', userId)
        .eq('school_id', schoolId)
        .maybeSingle();

    if (student != null) {
      final studentId = student['id'] as String;

      // Update student details
      await _client
          .from('student_details')
          .update({
            if (dob != null) 'dob': dob.toIso8601String(),
            if (gender != null) 'gender': gender,
            if (bloodGroup != null) 'blood_group': bloodGroup,
            if (nationality != null) 'nationality': nationality,
            if (religion != null) 'religion': religion,
            if (medicalInfo != null) 'medical_info': medicalInfo,
            if (transportRequired != null)
              'transport_required': transportRequired == 'yes',
            if (transportRoute != null) 'transport_route': transportRoute,
          })
          .eq('student_id', studentId)
          .eq('school_id', schoolId);

      // Update user profile
      if (firstName != null || lastName != null) {
        final profile = await _client
            .from('user_profiles')
            .select('full_name')
            .eq('user_id', userId)
            .maybeSingle();

        String fullName;
        if (firstName != null && lastName != null) {
          fullName = '$firstName $lastName';
        } else if (firstName != null) {
          final current = profile?['full_name'] as String? ?? '';
          fullName = '$firstName ${current.split(' ').skip(1).join(' ')}';
        } else {
          final current = profile?['full_name'] as String? ?? '';
          fullName = '${current.split(' ').first} $lastName';
        }

        await _client
            .from('user_profiles')
            .update({'full_name': fullName})
            .eq('user_id', userId);
      }
    }
  }

  // Student Search and Filter
  Future<List<Student>> searchStudents({
    String? query,
    int? classId,
    int? sectionId,
    String? status,
  }) async {
    var queryBuilder = _client.from('students_view').select();
    queryBuilder = _filterBySchool(queryBuilder);

    if (query != null && query.isNotEmpty) {
      queryBuilder = queryBuilder.or(
        'full_name.ilike.%$query%,admission_no.ilike.%$query%',
      );
    }

    if (classId != null) {
      queryBuilder = queryBuilder.eq('class_id', classId);
    }

    if (sectionId != null) {
      queryBuilder = queryBuilder.eq('section_id', sectionId);
    }

    if (status != null) {
      queryBuilder = queryBuilder.eq('status', status);
    }

    final response = await queryBuilder.order('created_at', ascending: false);
    final data = response as List<dynamic>;
    return data
        .map((row) => Student.fromMap(row as Map<String, dynamic>))
        .toList();
  }

  // Bulk Import
  Future<Map<String, dynamic>> bulkImportStudents(
    List<Map<String, dynamic>> students,
  ) async {
    final schoolId = _requireSchoolId();
    int success = 0;
    int failed = 0;
    List<String> errors = [];

    for (final studentData in students) {
      try {
        // Note: In production, you'd need to create auth user first
        // For now, we'll assume user exists or create via admin
        await _client.from('students').insert({
          'admission_no': studentData['admission_no'] as String,
          'user_id': studentData['user_id'] as String?,
          'class_id': studentData['class_id'] as int?,
          'section_id': studentData['section_id'] as int?,
          'status': studentData['status'] as String? ?? 'active',
          'school_id': schoolId,
        });
        success++;
      } catch (e) {
        failed++;
        errors.add('${studentData['admission_no']}: $e');
      }
    }

    return {'success': success, 'failed': failed, 'errors': errors};
  }

  // Fetch transport routes
  Future<List<Map<String, dynamic>>> fetchTransportRoutes() async {
    // This would typically come from a transport_routes table
    // For now, return sample data
    return [
      {'id': 'route1', 'name': 'Route 1 - North Zone'},
      {'id': 'route2', 'name': 'Route 2 - South Zone'},
      {'id': 'route3', 'name': 'Route 3 - East Zone'},
      {'id': 'route4', 'name': 'Route 4 - West Zone'},
    ];
  }
}
