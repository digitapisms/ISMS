import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/network/supabase_client.dart';
import '../domain/class_model.dart';
import '../domain/section_model.dart';

class ClassRepository {
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
        'School context is required. Please ensure you are signed in to a school tenant.',
      );
    }
    return id;
  }

  // =========================================================
  // CLASS METHODS
  // =========================================================

  /// Get all classes for the current school
  Future<List<ClassModel>> getClasses({bool? activeOnly}) async {
    final schoolId = _requireSchoolId();
    final baseQuery = _client
        .from('classes')
        .select()
        .eq('school_id', schoolId);

    final filteredQuery = activeOnly == true
        ? baseQuery.eq('is_active', true)
        : baseQuery;

    final response = await filteredQuery
        .order('name', ascending: true);
    final data = response;

    // Get section counts separately
    final classes = data.map((row) {
      return ClassModel.fromMap(row);
    }).toList();

    // Fetch section counts for each class
    for (final classModel in classes) {
      final sections = await _client
          .from('sections')
          .select('id')
          .eq('class_id', classModel.id)
          .eq('is_active', true);

      final sectionCount = (sections as List).length;
      classes[classes.indexOf(classModel)] = classModel.copyWith(
        sectionCount: sectionCount,
      );
    }

    return classes;
  }

  /// Get a single class by ID
  Future<ClassModel?> getClassById(String classId) async {
    final schoolId = _requireSchoolId();
    final response = await _client
        .from('classes')
        .select()
        .eq('id', classId)
        .eq('school_id', schoolId)
        .maybeSingle();

    if (response == null) return null;
    return ClassModel.fromMap(response);
  }

  /// Create a new class
  Future<ClassModel> createClass({
    required String name,
    String? code,
    String? level,
    String? description,
    bool isActive = true,
  }) async {
    final schoolId = _requireSchoolId();
    final response = await _client
        .from('classes')
        .insert({
          'school_id': schoolId,
          'name': name,
          'code': code,
          // 'level': level, // Column doesn't exist in database
          // 'description': description, // Column doesn't exist in database
          'is_active': isActive,
        })
        .select()
        .single();

    return ClassModel.fromMap(response);
  }

  /// Update a class
  Future<ClassModel> updateClass({
    required String id,
    String? name,
    String? code,
    String? level,
    String? description,
    bool? isActive,
  }) async {
    final schoolId = _requireSchoolId();
    final updates = <String, dynamic>{};
    if (name != null) updates['name'] = name;
    if (code != null) updates['code'] = code;
    // if (level != null) updates['level'] = level; // Column doesn't exist in database
    // if (description != null) updates['description'] = description; // Column doesn't exist in database
    if (isActive != null) updates['is_active'] = isActive;

    final response = await _client
        .from('classes')
        .update(updates)
        .eq('id', id)
        .eq('school_id', schoolId)
        .select()
        .single();

    return ClassModel.fromMap(response);
  }

  /// Delete a class (soft delete by setting is_active = false)
  Future<void> deleteClass(int id) async {
    final schoolId = _requireSchoolId();
    await _client
        .from('classes')
        .update({'is_active': false})
        .eq('id', id)
        .eq('school_id', schoolId);
  }

  /// Permanently delete a class (only if no students assigned)
  Future<void> permanentlyDeleteClass(String id) async {
    final schoolId = _requireSchoolId();

    // Check if class has students
    final students = await _client
        .from('students')
        .select('id')
        .eq('class_id', id)
        .eq('school_id', schoolId)
        .limit(1);

    if ((students as List).isNotEmpty) {
      throw Exception(
        'Cannot delete class. There are students assigned to this class.',
      );
    }

    // Delete sections first (cascade will handle this, but explicit is better)
    await _client
        .from('sections')
        .delete()
        .eq('class_id', id)
        .eq('school_id', schoolId);

    // Delete class
    await _client
        .from('classes')
        .delete()
        .eq('id', id)
        .eq('school_id', schoolId);
  }

  // =========================================================
  // SECTION METHODS
  // =========================================================

  /// Get all sections for a class
  Future<List<SectionModel>> getSections(
    String classId, {
    bool? activeOnly,
  }) async {
    final schoolId = _requireSchoolId();
    final baseQuery = _client
        .from('sections')
        .select()
        .eq('class_id', classId)
        .eq('school_id', schoolId);

    final filteredQuery = activeOnly == true
        ? baseQuery.eq('is_active', true)
        : baseQuery;

    final response = await filteredQuery.order('name');
    final data = response;

    // Get student counts separately
    final sections = data.map((row) {
      return SectionModel.fromMap(row);
    }).toList();

    // Fetch student counts for each section
    for (final section in sections) {
      final students = await _client
          .from('students')
          .select('id')
          .eq('section_id', section.id)
          .eq('school_id', schoolId);

      final studentCount = (students as List).length;
      sections[sections.indexOf(section)] = section.copyWith(
        studentCount: studentCount,
      );
    }

    return sections;
  }

  /// Get a single section by ID
  Future<SectionModel?> getSectionById(int sectionId) async {
    final schoolId = _requireSchoolId();
    final response = await _client
        .from('sections')
        .select()
        .eq('id', sectionId)
        .eq('school_id', schoolId)
        .maybeSingle();

    if (response == null) return null;
    return SectionModel.fromMap(response);
  }

  /// Create a new section
  Future<SectionModel> createSection({
    required String classId,
    required String name,
    String? code,
    int? capacity,
    bool isActive = true,
  }) async {
    final schoolId = _requireSchoolId();
    final response = await _client
        .from('sections')
        .insert({
          'class_id': classId,
          'school_id': schoolId,
          'name': name,
          'code': code,
          'capacity': capacity,
          'is_active': isActive,
        })
        .select()
        .single();

    return SectionModel.fromMap(response);
  }

  /// Update a section
  Future<SectionModel> updateSection({
    required String id,
    String? name,
    String? code,
    int? capacity,
    bool? isActive,
  }) async {
    final schoolId = _requireSchoolId();
    final updates = <String, dynamic>{};
    if (name != null) updates['name'] = name;
    if (code != null) updates['code'] = code;
    if (capacity != null) updates['capacity'] = capacity;
    if (isActive != null) updates['is_active'] = isActive;

    final response = await _client
        .from('sections')
        .update(updates)
        .eq('id', id)
        .eq('school_id', schoolId)
        .select()
        .single();

    return SectionModel.fromMap(response);
  }

  /// Delete a section (soft delete)
  Future<void> deleteSection(String id) async {
    final schoolId = _requireSchoolId();
    await _client
        .from('sections')
        .update({'is_active': false})
        .eq('id', id)
        .eq('school_id', schoolId);
  }

  /// Permanently delete a section (only if no students assigned)
  Future<void> permanentlyDeleteSection(String id) async {
    final schoolId = _requireSchoolId();

    // Check if section has students
    final students = await _client
        .from('students')
        .select('id')
        .eq('section_id', id)
        .eq('school_id', schoolId)
        .limit(1);

    if ((students as List).isNotEmpty) {
      throw Exception(
        'Cannot delete section. There are students assigned to this section.',
      );
    }

    // Delete section
    await _client
        .from('sections')
        .delete()
        .eq('id', id)
        .eq('school_id', schoolId);
  }
}
