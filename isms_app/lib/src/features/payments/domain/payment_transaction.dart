import 'package:equatable/equatable.dart';

class PaymentTransaction extends Equatable {
  const PaymentTransaction({
    required this.id,
    required this.schoolId,
    required this.status,
    required this.amount,
    required this.currency,
    this.providerId,
    this.accountId,
    this.externalReference,
    this.referenceCode,
    this.payerName,
    this.payerEmail,
    this.payerPhone,
    this.errorCode,
    this.errorMessage,
    this.initiatedAt,
    this.completedAt,
    this.rawResponse,
  });

  final String id;
  final String schoolId;
  final String status;
  final double amount;
  final String currency;
  final String? providerId;
  final String? accountId;
  final String? externalReference;
  final String? referenceCode;
  final String? payerName;
  final String? payerEmail;
  final String? payerPhone;
  final String? errorCode;
  final String? errorMessage;
  final DateTime? initiatedAt;
  final DateTime? completedAt;
  final Map<String, dynamic>? rawResponse;

  factory PaymentTransaction.fromMap(Map<String, dynamic> map) {
    return PaymentTransaction(
      id: map['id'] as String,
      schoolId: map['school_id'] as String,
      status: map['status'] as String? ?? 'pending',
      amount: (map['amount'] as num).toDouble(),
      currency: map['currency'] as String? ?? 'PKR',
      providerId: map['provider_id'] as String?,
      accountId: map['account_id'] as String?,
      externalReference: map['external_reference'] as String?,
      referenceCode: map['reference_code'] as String?,
      payerName: map['payer_name'] as String?,
      payerEmail: map['payer_email'] as String?,
      payerPhone: map['payer_phone'] as String?,
      errorCode: map['error_code'] as String?,
      errorMessage: map['error_message'] as String?,
      initiatedAt: map['initiated_at'] != null
          ? DateTime.tryParse(map['initiated_at'] as String)
          : null,
      completedAt: map['completed_at'] != null
          ? DateTime.tryParse(map['completed_at'] as String)
          : null,
      rawResponse: map['raw_response'] != null
          ? Map<String, dynamic>.from(map['raw_response'] as Map)
          : null,
    );
  }

  bool get isSuccessful => status == 'succeeded';
  bool get isFailed => status == 'failed';
  bool get isPending => status == 'pending';

  @override
  List<Object?> get props => [
    id,
    schoolId,
    status,
    amount,
    currency,
    providerId,
    accountId,
    externalReference,
    referenceCode,
    payerName,
    payerEmail,
    payerPhone,
    errorCode,
    errorMessage,
    initiatedAt,
    completedAt,
    rawResponse,
  ];
}
