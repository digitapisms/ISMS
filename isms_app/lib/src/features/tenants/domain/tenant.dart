import 'package:equatable/equatable.dart';

class Tenant extends Equatable {
  const Tenant({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.status,
    required this.subscriptionPlan,
    this.subscriptionExpiresAt,
    this.timezone,
    this.locale,
    this.currency,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String name;
  final String email;
  final String phone;
  final String status;
  final String subscriptionPlan;
  final DateTime? subscriptionExpiresAt;
  final String? timezone;
  final String? locale;
  final String? currency;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory Tenant.fromMap(Map<String, dynamic> map) {
    return Tenant(
      id: map['id'] as String,
      name: map['name'] as String,
      email: map['email'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      status: map['status'] as String? ?? 'pending',
      subscriptionPlan: map['subscription_plan'] as String? ?? 'free',
      subscriptionExpiresAt: map['subscription_expires_at'] != null
          ? DateTime.tryParse(map['subscription_expires_at'] as String)
          : null,
      timezone: map['timezone'] as String?,
      locale: map['locale'] as String?,
      currency: map['currency'] as String?,
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'] as String)
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.tryParse(map['updated_at'] as String)
          : null,
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    email,
    phone,
    status,
    subscriptionPlan,
    subscriptionExpiresAt,
    timezone,
    locale,
    currency,
    createdAt,
    updatedAt,
  ];
}
