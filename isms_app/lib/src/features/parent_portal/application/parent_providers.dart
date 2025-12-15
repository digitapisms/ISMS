import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/supabase_client.dart';
import '../../authentication/application/auth_providers.dart';
import '../../authentication/domain/user_role.dart';
import '../../student_management/domain/student.dart';

final parentChildrenProvider = FutureProvider<List<Student>>((ref) async {
  final currentUser = ref.watch(currentUserProvider).value;
  if (currentUser?.id == null || currentUser?.role != UserRole.parent) {
    return [];
  }

  final client = SupabaseManager.client;

  try {
    // Get parent's user record ID from users table
    final userResponse = await client
        .from('users')
        .select('id')
        .eq('auth_id', currentUser!.id)
        .single();

    final userId = userResponse['id'] as String;

    // Get student IDs linked to this parent
    final mappingResponse = await client
        .from('parent_student_mapping')
        .select('student_id')
        .eq('parent_id', userId);

    if (mappingResponse.isEmpty) {
      return [];
    }

    final studentIds = (mappingResponse as List)
        .map((row) => row['student_id'] as String)
        .toList();

    // Fetch student details
    final students = <Student>[];
    for (final studentId in studentIds) {
      try {
        final studentResponse = await client
            .from('students')
            .select('''
              id,
              admission_no,
              user_id,
              class_id,
              section_id,
              status,
              created_at
            ''')
            .eq('id', studentId)
            .single();

        // Get user details for student name
        final studentUserId = studentResponse['user_id'] as String?;
        if (studentUserId != null) {
          final userResponse = await client
              .from('users')
              .select('email')
              .eq('id', studentUserId)
              .single();

          // Get class and section names if available
          String? className;
          String? sectionName;

          if (studentResponse['class_id'] != null) {
            try {
              final classResponse = await client
                  .from('classes')
                  .select('name')
                  .eq('id', studentResponse['class_id'])
                  .maybeSingle();
              className = classResponse?['name'] as String?;
            } catch (_) {
              // Ignore if class not found
            }
          }

          if (studentResponse['section_id'] != null) {
            try {
              final sectionResponse = await client
                  .from('sections')
                  .select('name')
                  .eq('id', studentResponse['section_id'])
                  .maybeSingle();
              sectionName = sectionResponse?['name'] as String?;
            } catch (_) {
              // Ignore if section not found
            }
          }

          final student = Student(
            id: studentId,
            admissionNo: studentResponse['admission_no'] as String? ?? '',
            fullName: userResponse['email'] as String? ?? 'Unknown',
            className: className,
            sectionName: sectionName,
            classId: studentResponse['class_id'] as int?,
            sectionId: studentResponse['section_id'] as int?,
            status: studentResponse['status'] as String?,
          );

          students.add(student);
        }
      } catch (e) {
        // Skip students that can't be loaded
        continue;
      }
    }

    return students;
  } catch (e) {
    // If parent_student_mapping doesn't exist or query fails, return empty list
    return [];
  }
});

