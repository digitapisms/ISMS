import 'package:equatable/equatable.dart';

class ClassModel extends Equatable {
  const ClassModel({
    required this.id,
    required this.schoolId,
    required this.name,
    this.code,
    this.level,
    this.description,
    this.isActive = true,
    this.sectionCount,
    this.createdAt,
    this.updatedAt,
  });

  final int id;
  final String schoolId;
  final String name;
  final String? code;
  final int? level;
  final String? description;
  final bool isActive;
  final int? sectionCount; // Populated when fetched with count
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory ClassModel.fromMap(Map<String, dynamic> map) {
    return ClassModel(
      id: map['id'] as int,
      schoolId: map['school_id'] as String,
      name: map['name'] as String,
      code: map['code'] as String?,
      level: map['level'] as int?,
      description: map['description'] as String?,
      isActive: (map['is_active'] as bool?) ?? true,
      sectionCount: map['section_count'] as int?,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'])
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'school_id': schoolId,
      'name': name,
      'code': code,
      'level': level,
      'description': description,
      'is_active': isActive,
      'section_count': sectionCount,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  ClassModel copyWith({
    int? id,
    String? schoolId,
    String? name,
    String? code,
    int? level,
    String? description,
    bool? isActive,
    int? sectionCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ClassModel(
      id: id ?? this.id,
      schoolId: schoolId ?? this.schoolId,
      name: name ?? this.name,
      code: code ?? this.code,
      level: level ?? this.level,
      description: description ?? this.description,
      isActive: isActive ?? this.isActive,
      sectionCount: sectionCount ?? this.sectionCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    schoolId,
    name,
    code,
    level,
    description,
    isActive,
    sectionCount,
    createdAt,
    updatedAt,
  ];
}
