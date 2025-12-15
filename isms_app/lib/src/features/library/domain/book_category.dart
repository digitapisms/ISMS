import 'package:equatable/equatable.dart';

class BookCategory extends Equatable {
  const BookCategory({
    required this.id,
    required this.schoolId,
    required this.name,
    this.description,
    this.parentCategoryId,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  final int id;
  final String schoolId;
  final String name;
  final String? description;
  final int? parentCategoryId;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory BookCategory.fromMap(Map<String, dynamic> map) {
    return BookCategory(
      id: map['id'] as int,
      schoolId: map['school_id'] as String,
      name: map['name'] as String,
      description: map['description'] as String?,
      parentCategoryId: map['parent_category_id'] as int?,
      isActive: (map['is_active'] as bool?) ?? true,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'school_id': schoolId,
      'name': name,
      'description': description,
      'parent_category_id': parentCategoryId,
      'is_active': isActive,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
        id,
        schoolId,
        name,
        description,
        parentCategoryId,
        isActive,
        createdAt,
        updatedAt,
      ];
}

