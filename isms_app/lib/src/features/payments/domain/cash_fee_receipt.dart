import 'package:equatable/equatable.dart';

class CashFeeReceipt extends Equatable {
  const CashFeeReceipt({
    required this.id,
    required this.schoolId,
    required this.payerName,
    required this.amount,
    required this.paymentDate,
    this.studentId,
    this.receiptNumber,
    this.currency = 'PKR',
    this.notes,
    this.receivedBy,
  });

  final String id;
  final String schoolId;
  final String payerName;
  final double amount;
  final DateTime paymentDate;
  final String? studentId;
  final String? receiptNumber;
  final String currency;
  final String? notes;
  final String? receivedBy;

  factory CashFeeReceipt.fromMap(Map<String, dynamic> map) {
    return CashFeeReceipt(
      id: map['id'] as String,
      schoolId: map['school_id'] as String,
      payerName: map['payer_name'] as String,
      amount: (map['amount'] as num).toDouble(),
      paymentDate: DateTime.parse(map['payment_date'] as String),
      studentId: map['student_id'] as String?,
      receiptNumber: map['receipt_number'] as String?,
      currency: map['currency'] as String? ?? 'PKR',
      notes: map['notes'] as String?,
      receivedBy: map['received_by'] as String?,
    );
  }

  @override
  List<Object?> get props => [
    id,
    schoolId,
    payerName,
    amount,
    paymentDate,
    studentId,
    receiptNumber,
    currency,
    notes,
    receivedBy,
  ];
}
