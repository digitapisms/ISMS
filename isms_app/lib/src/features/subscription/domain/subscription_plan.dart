import 'package:equatable/equatable.dart';

class SubscriptionPlan extends Equatable {
  const SubscriptionPlan({
    required this.id,
    required this.name,
    this.description,
    required this.pricePerMonth,
    this.pricePerQuarter,
    this.pricePerHalfYear,
    this.pricePerYear,
    this.currency = 'PKR',
    this.maxStudents,
    this.maxTeachers,
    this.maxStorageMb,
    this.features = const {},
    this.isActive = true,
    this.isPublic = true,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String name; // Basic, Standard, Enterprise
  final String? description;
  final double pricePerMonth;
  final double? pricePerQuarter;
  final double? pricePerHalfYear;
  final double? pricePerYear;
  final String currency;
  final int? maxStudents;
  final int? maxTeachers;
  final int? maxStorageMb;
  final Map<String, dynamic> features;
  final bool isActive;
  final bool isPublic;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory SubscriptionPlan.fromMap(Map<String, dynamic> map) {
    return SubscriptionPlan(
      id: map['id'] as String,
      name: map['name'] as String,
      description: map['description'] as String?,
      pricePerMonth: (map['price_per_month'] as num).toDouble(),
      pricePerQuarter: (map['price_per_quarter'] as num?)?.toDouble(),
      pricePerHalfYear: (map['price_per_half_year'] as num?)?.toDouble(),
      pricePerYear: (map['price_per_year'] as num?)?.toDouble(),
      currency: map['currency'] as String? ?? 'PKR',
      maxStudents: map['max_students'] as int?,
      maxTeachers: map['max_teachers'] as int?,
      maxStorageMb: map['max_storage_mb'] as int?,
      features: (map['features'] as Map<String, dynamic>?) ?? {},
      isActive: map['is_active'] as bool? ?? true,
      isPublic: map['is_public'] as bool? ?? true,
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
      'name': name,
      'description': description,
      'price_per_month': pricePerMonth,
      'price_per_quarter': pricePerQuarter,
      'price_per_half_year': pricePerHalfYear,
      'price_per_year': pricePerYear,
      'currency': currency,
      'max_students': maxStudents,
      'max_teachers': maxTeachers,
      'max_storage_mb': maxStorageMb,
      'features': features,
      'is_active': isActive,
      'is_public': isPublic,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  /// Get price for a specific billing cycle
  double getPriceForBillingCycle(String billingCycle) {
    switch (billingCycle) {
      case 'monthly':
        return pricePerMonth;
      case 'quarterly':
        return pricePerQuarter ?? pricePerMonth * 3;
      case 'half_yearly':
        return pricePerHalfYear ?? pricePerMonth * 6;
      case 'yearly':
        return pricePerYear ?? pricePerMonth * 12;
      default:
        return pricePerMonth;
    }
  }

  /// Check if a specific feature is enabled
  bool hasFeature(String featureKey) {
    return features[featureKey] as bool? ?? false;
  }

  /// Get feature limit
  int? getFeatureLimit(String featureKey) {
    return features['${featureKey}_limit'] as int?;
  }

  /// Get display name (capitalized name)
  String get displayName {
    if (name.isEmpty) return name;
    return name[0].toUpperCase() + name.substring(1);
  }

  /// Get price (alias for pricePerMonth for backward compatibility)
  double? get price => pricePerMonth;

  /// Get features as a list of entries for iteration
  List<MapEntry<String, dynamic>> get featuresList => features.entries.toList();

  /// Create a copy with updated values
  SubscriptionPlan copyWith({
    String? id,
    String? name,
    String? description,
    double? pricePerMonth,
    double? pricePerQuarter,
    double? pricePerHalfYear,
    double? pricePerYear,
    String? currency,
    int? maxStudents,
    int? maxTeachers,
    int? maxStorageMb,
    Map<String, dynamic>? features,
    bool? isActive,
    bool? isPublic,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SubscriptionPlan(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      pricePerMonth: pricePerMonth ?? this.pricePerMonth,
      pricePerQuarter: pricePerQuarter ?? this.pricePerQuarter,
      pricePerHalfYear: pricePerHalfYear ?? this.pricePerHalfYear,
      pricePerYear: pricePerYear ?? this.pricePerYear,
      currency: currency ?? this.currency,
      maxStudents: maxStudents ?? this.maxStudents,
      maxTeachers: maxTeachers ?? this.maxTeachers,
      maxStorageMb: maxStorageMb ?? this.maxStorageMb,
      features: features ?? this.features,
      isActive: isActive ?? this.isActive,
      isPublic: isPublic ?? this.isPublic,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        pricePerMonth,
        pricePerQuarter,
        pricePerHalfYear,
        pricePerYear,
        currency,
        maxStudents,
        maxTeachers,
        maxStorageMb,
        features,
        isActive,
        isPublic,
        createdAt,
        updatedAt,
      ];
}