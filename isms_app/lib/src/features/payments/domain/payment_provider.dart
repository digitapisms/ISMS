import 'package:equatable/equatable.dart';

class PaymentProvider extends Equatable {
  const PaymentProvider({
    required this.id,
    required this.providerKey,
    required this.displayName,
    required this.providerType,
    required this.isActive,
    this.metadataSchema,
  });

  final String id;
  final String providerKey;
  final String displayName;
  final String providerType;
  final bool isActive;
  final Map<String, dynamic>? metadataSchema;

  factory PaymentProvider.fromMap(Map<String, dynamic> map) {
    return PaymentProvider(
      id: map['id'] as String,
      providerKey: map['provider_key'] as String,
      displayName: map['display_name'] as String,
      providerType: map['provider_type'] as String,
      isActive: map['is_active'] as bool? ?? true,
      metadataSchema: map['metadata_schema'] != null
          ? Map<String, dynamic>.from(map['metadata_schema'] as Map)
          : null,
    );
  }

  List<String> get requiredFields {
    if (metadataSchema == null) return const [];
    final fields = metadataSchema!['fields'];
    if (fields is List) {
      return fields.cast<String>();
    }
    return const [];
  }

  @override
  List<Object?> get props => [
    id,
    providerKey,
    displayName,
    providerType,
    isActive,
    metadataSchema,
  ];
}
