import 'package:equatable/equatable.dart';

class SectionModel extends Equatable {
  const SectionModel({
    required this.id,
    required this.classId,
    required this.schoolId,
    required this.name,
    this.code,
    this.capacity,
    this.isActive = true,
    this.studentCount,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String classId;
  final String schoolId;
  final String name;
  final String? code;
  final int? capacity;
  final bool isActive;
  final int? studentCount; // Populated when fetched with count
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory SectionModel.fromMap(Map<String, dynamic> map) {
    return SectionModel(
      id: map['id'] as String,
      classId: map['class_id'] as String,
      schoolId: map['school_id'] as String,
      name: map['name'] as String,
      code: map['code'] as String?,
      capacity: map['capacity'] as int?,
      isActive: (map['is_active'] as bool?) ?? true,
      studentCount: map['student_count'] as int?,
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
      'class_id': classId,
      'school_id': schoolId,
      'name': name,
      'code': code,
      'capacity': capacity,
      'is_active': isActive,
      'student_count': studentCount,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  SectionModel copyWith({
    String? id,
    String? classId,
    String? schoolId,
    String? name,
    String? code,
    int? capacity,
    bool? isActive,
    int? studentCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SectionModel(
      id: id ?? this.id,
      classId: classId ?? this.classId,
      schoolId: schoolId ?? this.schoolId,
      name: name ?? this.name,
      code: code ?? this.code,
      capacity: capacity ?? this.capacity,
      isActive: isActive ?? this.isActive,
      studentCount: studentCount ?? this.studentCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    classId,
    schoolId,
    name,
    code,
    capacity,
    isActive,
    studentCount,
    createdAt,
    updatedAt,
  ];
}
