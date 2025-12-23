import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/app_error.dart';
import '../../../core/errors/error_handler.dart';
import '../../../core/errors/error_repository_mixin.dart';
import '../../../core/errors/validation.dart';
import '../../../core/network/supabase_client.dart';
import '../domain/class_model.dart';
import '../domain/section_model.dart';

/// Repository for class and section management
///
/// Handles all database operations for classes and sections with
/// proper error handling, validation, and timeouts.
class ClassRepository with ErrorRepositoryMixin {
  SupabaseClient get _client => SupabaseManager.client;
  String? _schoolId;

  void setSchoolId(String? schoolId) {
    _schoolId = schoolId;
  }

  String? get schoolId => _schoolId;

  // =========================================================
  // CLASS METHODS
  // =========================================================

  /// Get all classes for the current school
  Future<List<ClassModel>> getClasses({bool? activeOnly}) async {
    final correlationId = ErrorHandler.generateCorrelationId();

    try {
      final schoolId = _schoolId;
      if (schoolId == null) {
        return <ClassModel>[];
      }

      // Validate school ID format
      final validationError = Validation.validateUuid(schoolId, 'school_id');
      if (validationError != null) {
        throw validationError;
      }

      final baseQuery = _client
          .from('classes')
          .select()
          .eq('school_id', schoolId);

      final filteredQuery = activeOnly == true
          ? baseQuery.eq('is_active', true)
          : baseQuery;

      final response = await filteredQuery
          .order('name', ascending: true)
          .timeout(const Duration(seconds: 10));
      final data = response as List;

      // Parse classes with error handling
      final classes = <ClassModel>[];
      for (final row in data) {
        try {
          final classModel = ClassModel.fromMap(row as Map<String, dynamic>);
          classes.add(classModel);
        } catch (e, stackTrace) {
          final error = ErrorHandler.handleException(
            e,
            stackTrace: stackTrace,
            correlationId: correlationId,
            context: 'Parsing class data',
          );
          ErrorHandler.logError(error, context: 'getClasses');
          // Continue with other classes instead of failing entirely
        }
      }

      // Fetch section counts with timeout per class (skip if takes too long)
      for (final classModel in classes) {
        try {
          final sections = await _client
              .from('sections')
              .select('id')
              .eq('class_id', classModel.id)
              .eq('is_active', true)
              .timeout(const Duration(seconds: 1));
          final sectionCount = (sections as List).length;
          final index = classes.indexOf(classModel);
          if (index >= 0) {
            classes[index] = classModel.copyWith(sectionCount: sectionCount);
          }
        } catch (e) {
          // Skip section count on timeout/error - it's optional
          // Don't log to avoid spam
        }
      }

      return classes;
    } catch (e) {
      final error = ErrorHandler.handleException(
        e,
        correlationId: correlationId,
        context: 'ClassRepository.getClasses',
      );
      ErrorHandler.logError(error, context: 'getClasses');
      return <ClassModel>[];
    }
  }

  /// Get a single class by ID
  Future<ClassModel?> getClassById(int classId) async {
    final correlationId = ErrorHandler.generateCorrelationId();

    return safeDbOperation(
      operation: () async {
        final schoolId = validateSchoolId(
          _schoolId,
          correlationId: correlationId,
        );

        // Validate classId
        if (classId <= 0) {
          throw ValidationError(
            message: 'Invalid class ID: $classId',
            userMessage: 'Invalid class identifier.',
            field: 'classId',
          );
        }

        final response = await _client
            .from('classes')
            .select()
            .eq('id', classId)
            .eq('school_id', schoolId)
            .maybeSingle();

        if (response == null) {
          return null;
        }

        return ClassModel.fromMap(response);
      },
      context: 'ClassRepository.getClassById',
      correlationId: correlationId,
    );
  }

  /// Create a new class
  Future<ClassModel> createClass({
    required String name,
    String? code,
    String? level,
    String? description,
    bool isActive = true,
  }) async {
    final correlationId = ErrorHandler.generateCorrelationId();

    return safeDbOperation(
      operation: () async {
        // Input validation
        final nameError = Validation.validateRequired(name, 'name');
        if (nameError != null) throw nameError;

        final lengthError = Validation.validateLength(
          name,
          'name',
          min: 1,
          max: 100,
        );
        if (lengthError != null) throw lengthError;

        if (code != null) {
          final codeLengthError = Validation.validateLength(
            code,
            'code',
            max: 20,
          );
          if (codeLengthError != null) throw codeLengthError;
        }

        final schoolId = validateSchoolId(
          _schoolId,
          correlationId: correlationId,
        );

        final response = await _client
            .from('classes')
            .insert({
              'school_id': schoolId,
              'name': name.trim(),
              'code': code?.trim(),
              'grade_level': level?.trim(),
              'description': description?.trim(),
              'is_active': isActive,
            })
            .select()
            .single();

        return ClassModel.fromMap(response);
      },
      context: 'ClassRepository.createClass',
      correlationId: correlationId,
    );
  }

  /// Update a class
  Future<ClassModel> updateClass({
    required int id,
    String? name,
    String? code,
    String? level,
    String? description,
    bool? isActive,
  }) async {
    final correlationId = ErrorHandler.generateCorrelationId();

    return safeDbOperation(
      operation: () async {
        // Validate ID
        if (id <= 0) {
          throw ValidationError(
            message: 'Invalid class ID: $id',
            userMessage: 'Invalid class identifier.',
            field: 'id',
          );
        }

        // Validate name if provided
        if (name != null) {
          final nameError = Validation.validateRequired(name, 'name');
          if (nameError != null) throw nameError;
          final lengthError = Validation.validateLength(
            name,
            'name',
            min: 1,
            max: 100,
          );
          if (lengthError != null) throw lengthError;
        }

        final schoolId = validateSchoolId(
          _schoolId,
          correlationId: correlationId,
        );

        final updates = <String, dynamic>{};
        if (name != null) updates['name'] = name.trim();
        if (code != null) updates['code'] = code.trim();
        if (level != null) updates['grade_level'] = level.trim();
        if (description != null) updates['description'] = description.trim();
        if (isActive != null) updates['is_active'] = isActive;

        if (updates.isEmpty) {
          // No updates provided, fetch and return existing
          return await getClassById(id) ??
              (throw DatabaseError.notFound(
                resource: 'Class with ID $id',
                correlationId: correlationId,
              ));
        }

        final response = await _client
            .from('classes')
            .update(updates)
            .eq('id', id)
            .eq('school_id', schoolId)
            .select()
            .single();

        return ClassModel.fromMap(response);
      },
      context: 'ClassRepository.updateClass',
      correlationId: correlationId,
    );
  }

  /// Delete a class (soft delete by setting is_active = false)
  Future<void> deleteClass(int id) async {
    final correlationId = ErrorHandler.generateCorrelationId();

    return safeDbOperation(
      operation: () async {
        if (id <= 0) {
          throw ValidationError(
            message: 'Invalid class ID: $id',
            userMessage: 'Invalid class identifier.',
            field: 'id',
          );
        }

        final schoolId = validateSchoolId(
          _schoolId,
          correlationId: correlationId,
        );

        await _client
            .from('classes')
            .update({'is_active': false})
            .eq('id', id)
            .eq('school_id', schoolId);
      },
      context: 'ClassRepository.deleteClass',
      correlationId: correlationId,
    );
  }

  /// Permanently delete a class (only if no students assigned)
  Future<void> permanentlyDeleteClass(int id) async {
    final correlationId = ErrorHandler.generateCorrelationId();

    return safeDbOperation(
      operation: () async {
        if (id <= 0) {
          throw ValidationError(
            message: 'Invalid class ID: $id',
            userMessage: 'Invalid class identifier.',
            field: 'id',
          );
        }

        final schoolId = validateSchoolId(
          _schoolId,
          correlationId: correlationId,
        );

        // Check if class has students
        final students = await _client
            .from('students')
            .select('id')
            .eq('class_id', id)
            .eq('school_id', schoolId)
            .limit(1);

        if ((students as List).isNotEmpty) {
          throw BusinessLogicError.invalidOperation(
            operation: 'delete_class',
            reason: 'Class has assigned students',
            correlationId: correlationId,
          );
        }

        // Delete sections first
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
      },
      context: 'ClassRepository.permanentlyDeleteClass',
      correlationId: correlationId,
    );
  }

  // =========================================================
  // SECTION METHODS
  // =========================================================

  /// Get all sections for a class
  Future<List<SectionModel>> getSections(
    int classId, {
    bool? activeOnly,
  }) async {
    final correlationId = ErrorHandler.generateCorrelationId();

    try {
      if (classId <= 0) {
        return <SectionModel>[];
      }

      final schoolId = _schoolId;
      if (schoolId == null) {
        return <SectionModel>[];
      }

      final baseQuery = _client
          .from('sections')
          .select()
          .eq('class_id', classId)
          .eq('school_id', schoolId);

      final filteredQuery = activeOnly == true
          ? baseQuery.eq('is_active', true)
          : baseQuery;

      final response = await filteredQuery
          .order('name')
          .timeout(const Duration(seconds: 10));
      final data = response as List;

      // Parse sections with error handling
      final sections = <SectionModel>[];
      for (final row in data) {
        try {
          final section = SectionModel.fromMap(row as Map<String, dynamic>);
          sections.add(section);
        } catch (e, stackTrace) {
          final error = ErrorHandler.handleException(
            e,
            stackTrace: stackTrace,
            correlationId: correlationId,
            context: 'Parsing section data',
          );
          ErrorHandler.logError(error, context: 'getSections');
          // Continue with other sections
        }
      }

      // Fetch student counts with timeout (skip if takes too long)
      for (final section in sections) {
        try {
          final students = await _client
              .from('students')
              .select('id')
              .eq('section_id', section.id)
              .eq('school_id', schoolId)
              .timeout(const Duration(seconds: 1));
          final studentCount = (students as List).length;
          final index = sections.indexOf(section);
          if (index >= 0) {
            sections[index] = section.copyWith(studentCount: studentCount);
          }
        } catch (e) {
          // Skip student count on timeout/error - it's optional
          // Don't log to avoid spam
        }
      }

      return sections;
    } catch (e) {
      final error = ErrorHandler.handleException(
        e,
        correlationId: correlationId,
        context: 'ClassRepository.getSections',
      );
      ErrorHandler.logError(error, context: 'getSections');
      return <SectionModel>[];
    }
  }

  /// Get a single section by ID
  Future<SectionModel?> getSectionById(int sectionId) async {
    final correlationId = ErrorHandler.generateCorrelationId();

    return safeDbOperation(
      operation: () async {
        if (sectionId <= 0) {
          throw ValidationError(
            message: 'Invalid section ID: $sectionId',
            userMessage: 'Invalid section identifier.',
            field: 'sectionId',
          );
        }

        final schoolId = validateSchoolId(
          _schoolId,
          correlationId: correlationId,
        );

        final response = await _client
            .from('sections')
            .select()
            .eq('id', sectionId)
            .eq('school_id', schoolId)
            .maybeSingle();

        if (response == null) {
          return null;
        }

        return SectionModel.fromMap(response);
      },
      context: 'ClassRepository.getSectionById',
      correlationId: correlationId,
    );
  }

  /// Create a new section
  Future<SectionModel> createSection({
    required int classId,
    required String name,
    String? code,
    int? capacity,
    bool isActive = true,
  }) async {
    final correlationId = ErrorHandler.generateCorrelationId();

    return safeDbOperation(
      operation: () async {
        // Input validation
        if (classId <= 0) {
          throw ValidationError(
            message: 'Invalid class ID: $classId',
            userMessage: 'Invalid class identifier.',
            field: 'classId',
          );
        }

        final nameError = Validation.validateRequired(name, 'name');
        if (nameError != null) throw nameError;

        final lengthError = Validation.validateLength(
          name,
          'name',
          min: 1,
          max: 50,
        );
        if (lengthError != null) throw lengthError;

        if (capacity != null && capacity < 0) {
          throw ValidationError.outOfRange('capacity', min: 0, max: 1000);
        }

        final schoolId = validateSchoolId(
          _schoolId,
          correlationId: correlationId,
        );

        // Verify class exists
        final classExists = await getClassById(classId);
        if (classExists == null) {
          throw DatabaseError.notFound(
            resource: 'Class with ID $classId',
            correlationId: correlationId,
          );
        }

        final response = await _client
            .from('sections')
            .insert({
              'class_id': classId,
              'school_id': schoolId,
              'name': name.trim(),
              'code': code?.trim(),
              'capacity': capacity,
              'is_active': isActive,
            })
            .select()
            .single();

        return SectionModel.fromMap(response);
      },
      context: 'ClassRepository.createSection',
      correlationId: correlationId,
    );
  }

  /// Update a section
  Future<SectionModel> updateSection({
    required int id,
    String? name,
    String? code,
    int? capacity,
    bool? isActive,
  }) async {
    final correlationId = ErrorHandler.generateCorrelationId();

    return safeDbOperation(
      operation: () async {
        if (id <= 0) {
          throw ValidationError(
            message: 'Invalid section ID: $id',
            userMessage: 'Invalid section identifier.',
            field: 'id',
          );
        }

        if (name != null) {
          final nameError = Validation.validateRequired(name, 'name');
          if (nameError != null) throw nameError;
          final lengthError = Validation.validateLength(
            name,
            'name',
            min: 1,
            max: 50,
          );
          if (lengthError != null) throw lengthError;
        }

        if (capacity != null && capacity < 0) {
          throw ValidationError.outOfRange('capacity', min: 0, max: 1000);
        }

        final schoolId = validateSchoolId(
          _schoolId,
          correlationId: correlationId,
        );

        final updates = <String, dynamic>{};
        if (name != null) updates['name'] = name.trim();
        if (code != null) updates['code'] = code.trim();
        if (capacity != null) updates['capacity'] = capacity;
        if (isActive != null) updates['is_active'] = isActive;

        if (updates.isEmpty) {
          return await getSectionById(id) ??
              (throw DatabaseError.notFound(
                resource: 'Section with ID $id',
                correlationId: correlationId,
              ));
        }

        final response = await _client
            .from('sections')
            .update(updates)
            .eq('id', id)
            .eq('school_id', schoolId)
            .select()
            .single();

        return SectionModel.fromMap(response);
      },
      context: 'ClassRepository.updateSection',
      correlationId: correlationId,
    );
  }

  /// Delete a section (soft delete)
  Future<void> deleteSection(int id) async {
    final correlationId = ErrorHandler.generateCorrelationId();

    return safeDbOperation(
      operation: () async {
        if (id <= 0) {
          throw ValidationError(
            message: 'Invalid section ID: $id',
            userMessage: 'Invalid section identifier.',
            field: 'id',
          );
        }

        final schoolId = validateSchoolId(
          _schoolId,
          correlationId: correlationId,
        );

        await _client
            .from('sections')
            .update({'is_active': false})
            .eq('id', id)
            .eq('school_id', schoolId);
      },
      context: 'ClassRepository.deleteSection',
      correlationId: correlationId,
    );
  }

  /// Permanently delete a section (only if no students assigned)
  Future<void> permanentlyDeleteSection(int id) async {
    final correlationId = ErrorHandler.generateCorrelationId();

    return safeDbOperation(
      operation: () async {
        if (id <= 0) {
          throw ValidationError(
            message: 'Invalid section ID: $id',
            userMessage: 'Invalid section identifier.',
            field: 'id',
          );
        }

        final schoolId = validateSchoolId(
          _schoolId,
          correlationId: correlationId,
        );

        // Check if section has students
        final students = await _client
            .from('students')
            .select('id')
            .eq('section_id', id)
            .eq('school_id', schoolId)
            .limit(1);

        if ((students as List).isNotEmpty) {
          throw BusinessLogicError.invalidOperation(
            operation: 'delete_section',
            reason: 'Section has assigned students',
            correlationId: correlationId,
          );
        }

        // Delete section
        await _client
            .from('sections')
            .delete()
            .eq('id', id)
            .eq('school_id', schoolId);
      },
      context: 'ClassRepository.permanentlyDeleteSection',
      correlationId: correlationId,
    );
  }
}
