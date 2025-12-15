import 'package:equatable/equatable.dart';

import 'plan_feature.dart';

class SubscriptionPlan extends Equatable {
  const SubscriptionPlan({
    required this.name,
    required this.displayName,
    this.description,
    this.price,
    this.billingCycle, // 'monthly', 'yearly'
    this.features = const [],
  });

  final String name; // 'free', 'basic', 'premium', 'enterprise'
  final String displayName; // 'Free', 'Basic', 'Premium', 'Enterprise'
  final String? description;
  final double? price;
  final String? billingCycle;
  final List<PlanFeatureMapping> features;

  factory SubscriptionPlan.fromMap(Map<String, dynamic> map) {
    return SubscriptionPlan(
      name: map['name'] as String,
      displayName: map['display_name'] as String? ?? map['name'] as String,
      description: map['description'] as String?,
      price: (map['price'] as num?)?.toDouble(),
      billingCycle: map['billing_cycle'] as String?,
      features:
          (map['features'] as List<dynamic>?)
              ?.map(
                (f) => PlanFeatureMapping.fromMap(f as Map<String, dynamic>),
              )
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'display_name': displayName,
      'description': description,
      'price': price,
      'billing_cycle': billingCycle,
      'features': features.map((f) => f.toMap()).toList(),
    };
  }

  @override
  List<Object?> get props => [
    name,
    displayName,
    description,
    price,
    billingCycle,
    features,
  ];
}
