import 'package:equatable/equatable.dart';

/// Fee invoice item model (line items in an invoice)
class FeeInvoiceItem extends Equatable {
  const FeeInvoiceItem({
    required this.id,
    required this.invoiceId,
    required this.description,
    required this.unitAmount,
    required this.totalAmount,
    this.feeStructureId,
    this.categoryId,
    this.quantity = 1,
    this.discountAmount = 0,
    this.createdAt,
  });

  final String id;
  final String invoiceId;
  final String? feeStructureId;
  final String? categoryId;
  final String description;
  final int quantity;
  final double unitAmount;
  final double totalAmount;
  final double discountAmount;
  final DateTime? createdAt;

  factory FeeInvoiceItem.fromMap(Map<String, dynamic> map) {
    return FeeInvoiceItem(
      id: map['id'] as String,
      invoiceId: map['invoice_id'] as String,
      feeStructureId: map['fee_structure_id'] as String?,
      categoryId: map['category_id'] as String?,
      description: map['description'] as String,
      quantity: map['quantity'] as int? ?? 1,
      unitAmount: (map['unit_amount'] as num).toDouble(),
      totalAmount: (map['total_amount'] as num).toDouble(),
      discountAmount: (map['discount_amount'] as num?)?.toDouble() ?? 0,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'invoice_id': invoiceId,
      'fee_structure_id': feeStructureId,
      'category_id': categoryId,
      'description': description,
      'quantity': quantity,
      'unit_amount': unitAmount,
      'total_amount': totalAmount,
      'discount_amount': discountAmount,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
    id,
    invoiceId,
    feeStructureId,
    categoryId,
    description,
    quantity,
    unitAmount,
    totalAmount,
    discountAmount,
    createdAt,
  ];
}
