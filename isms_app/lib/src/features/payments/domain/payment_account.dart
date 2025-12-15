import 'package:equatable/equatable.dart';

import 'payment_provider.dart';

class PaymentAccount extends Equatable {
  const PaymentAccount({
    required this.id,
    required this.schoolId,
    required this.providerId,
    required this.accountLabel,
    required this.status,
    this.country,
    this.currency,
    this.metadata,
    this.credentials,
    this.verifiedAt,
    this.provider,
  });

  final String id;
  final String schoolId;
  final String providerId;
  final String accountLabel;
  final String status;
  final String? country;
  final String? currency;
  final Map<String, dynamic>? metadata;
  final Map<String, dynamic>? credentials;
  final DateTime? verifiedAt;
  final PaymentProvider? provider;

  factory PaymentAccount.fromMap(Map<String, dynamic> map) {
    return PaymentAccount(
      id: map['id'] as String,
      schoolId: map['school_id'] as String,
      providerId: map['provider_id'] as String,
      accountLabel: map['account_label'] as String,
      status: map['status'] as String? ?? 'pending',
      country: map['country'] as String?,
      currency: map['currency'] as String?,
      metadata: map['metadata'] != null
          ? Map<String, dynamic>.from(map['metadata'] as Map)
          : null,
      credentials: map['credentials'] != null
          ? Map<String, dynamic>.from(map['credentials'] as Map)
          : null,
      verifiedAt: map['verified_at'] != null
          ? DateTime.tryParse(map['verified_at'] as String)
          : null,
      provider: map['payment_providers'] != null
          ? PaymentProvider.fromMap(
              Map<String, dynamic>.from(map['payment_providers'] as Map),
            )
          : null,
    );
  }

  bool get isActive => status == 'active';
  bool get isPending => status == 'pending';
  bool get isRejected => status == 'rejected';

  @override
  List<Object?> get props => [
    id,
    schoolId,
    providerId,
    accountLabel,
    status,
    country,
    currency,
    metadata,
    credentials,
    verifiedAt,
    provider,
  ];
}
