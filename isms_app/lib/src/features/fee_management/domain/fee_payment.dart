import 'package:equatable/equatable.dart';

/// Fee payment model - links payments to invoices
class FeePayment extends Equatable {
  const FeePayment({
    required this.id,
    required this.schoolId,
    required this.invoiceId,
    required this.studentId,
    required this.paymentMethod,
    required this.amount,
    required this.paymentDate,
    this.paymentTransactionId,
    this.cashReceiptId,
    this.currency = 'PKR',
    this.paymentReference,
    this.notes,
    this.receivedBy,
    this.createdAt,
  });

  final String id;
  final String schoolId;
  final String invoiceId;
  final String studentId;
  final String? paymentTransactionId;
  final String? cashReceiptId;
  final String paymentMethod; // easypaisa, jazzcash, bank_transfer, card, cash
  final double amount;
  final String currency;
  final DateTime paymentDate;
  final String? paymentReference;
  final String? notes;
  final String? receivedBy;
  final DateTime? createdAt;

  factory FeePayment.fromMap(Map<String, dynamic> map) {
    return FeePayment(
      id: map['id'] as String,
      schoolId: map['school_id'] as String,
      invoiceId: map['invoice_id'] as String,
      studentId: map['student_id'] as String,
      paymentTransactionId: map['payment_transaction_id'] as String?,
      cashReceiptId: map['cash_receipt_id'] as String?,
      paymentMethod: map['payment_method'] as String,
      amount: (map['amount'] as num).toDouble(),
      currency: map['currency'] as String? ?? 'PKR',
      paymentDate: DateTime.parse(map['payment_date'] as String),
      paymentReference: map['payment_reference'] as String?,
      notes: map['notes'] as String?,
      receivedBy: map['received_by'] as String?,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'school_id': schoolId,
      'invoice_id': invoiceId,
      'student_id': studentId,
      'payment_transaction_id': paymentTransactionId,
      'cash_receipt_id': cashReceiptId,
      'payment_method': paymentMethod,
      'amount': amount,
      'currency': currency,
      'payment_date': paymentDate.toIso8601String().split('T')[0],
      'payment_reference': paymentReference,
      'notes': notes,
      'received_by': receivedBy,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
    id,
    schoolId,
    invoiceId,
    studentId,
    paymentTransactionId,
    cashReceiptId,
    paymentMethod,
    amount,
    currency,
    paymentDate,
    paymentReference,
    notes,
    receivedBy,
    createdAt,
  ];
}
