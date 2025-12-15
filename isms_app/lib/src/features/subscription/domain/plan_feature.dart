import 'package:equatable/equatable.dart';

class PlanFeature extends Equatable {
  const PlanFeature({
    required this.id,
    required this.featureKey,
    required this.featureName,
    this.description,
    this.category,
    this.createdAt,
  });

  final String id;
  final String featureKey;
  final String featureName;
  final String? description;
  final String? category;
  final DateTime? createdAt;

  factory PlanFeature.fromMap(Map<String, dynamic> map) {
    return PlanFeature(
      id: map['id'] as String,
      featureKey: map['feature_key'] as String,
      featureName: map['feature_name'] as String,
      description: map['description'] as String?,
      category: map['category'] as String?,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'feature_key': featureKey,
      'feature_name': featureName,
      'description': description,
      'category': category,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
    id,
    featureKey,
    featureName,
    description,
    category,
    createdAt,
  ];
}

class PlanFeatureMapping extends Equatable {
  const PlanFeatureMapping({
    required this.id,
    required this.planName,
    required this.featureId,
    required this.isEnabled,
    this.limitValue,
    this.feature,
  });

  final String id;
  final String planName;
  final String featureId;
  final bool isEnabled;
  final int? limitValue;
  final PlanFeature? feature; // Populated when fetched with join

  factory PlanFeatureMapping.fromMap(Map<String, dynamic> map) {
    return PlanFeatureMapping(
      id: map['id'] as String,
      planName: map['plan_name'] as String,
      featureId: map['feature_id'] as String,
      isEnabled: (map['is_enabled'] as bool?) ?? true,
      limitValue: map['limit_value'] as int?,
      feature: map['feature'] != null
          ? PlanFeature.fromMap(map['feature'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'plan_name': planName,
      'feature_id': featureId,
      'is_enabled': isEnabled,
      'limit_value': limitValue,
    };
  }

  @override
  List<Object?> get props => [
    id,
    planName,
    featureId,
    isEnabled,
    limitValue,
    feature,
  ];
}
