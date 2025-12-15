import 'package:equatable/equatable.dart';

class Subject extends Equatable {
  const Subject({
    required this.id,
    required this.schoolId,
    required this.name,
    this.code,
    this.description,
    this.isActive = true,
    this.displayOrder = 0,
    this.createdAt,
    this.updatedAt,
  });

  final int id;
  final String schoolId;
  final String name;
  final String? code;
  final String? description;
  final bool isActive;
  final int displayOrder;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory Subject.fromMap(Map<String, dynamic> map) {
    return Subject(
      id: map['id'] as int,
      schoolId: map['school_id'] as String,
      name: map['name'] as String,
      code: map['code'] as String?,
      description: map['description'] as String?,
      isActive: (map['is_active'] as bool?) ?? true,
      displayOrder: (map['display_order'] as int?) ?? 0,
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
      'code': code,
      'description': description,
      'is_active': isActive,
      'display_order': displayOrder,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
    id,
    schoolId,
    name,
    code,
    description,
    isActive,
    displayOrder,
    createdAt,
    updatedAt,
  ];
}
