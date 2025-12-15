class EnrichmentCategory {
  final String id;
  final String schoolId;
  final String name;
  final String? description;
  final String? icon;
  final int displayOrder;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  EnrichmentCategory({
    required this.id,
    required this.schoolId,
    required this.name,
    this.description,
    this.icon,
    required this.displayOrder,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory EnrichmentCategory.fromMap(Map<String, dynamic> map) {
    return EnrichmentCategory(
      id: map['id'] as String,
      schoolId: map['school_id'] as String,
      name: map['name'] as String,
      description: map['description'] as String?,
      icon: map['icon'] as String?,
      displayOrder: (map['display_order'] as num?)?.toInt() ?? 0,
      isActive: map['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'school_id': schoolId,
      'name': name,
      'description': description,
      'icon': icon,
      'display_order': displayOrder,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
