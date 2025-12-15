class PaymentFilters {
  final String? status;
  final DateTime? startDate;
  final DateTime? endDate;
  final double? minAmount;
  final double? maxAmount;
  final String? paymentMethod;

  const PaymentFilters({
    this.status,
    this.startDate,
    this.endDate,
    this.minAmount,
    this.maxAmount,
    this.paymentMethod,
  });

  PaymentFilters copyWith({
    String? status,
    DateTime? startDate,
    DateTime? endDate,
    double? minAmount,
    double? maxAmount,
    String? paymentMethod,
  }) {
    return PaymentFilters(
      status: status ?? this.status,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      minAmount: minAmount ?? this.minAmount,
      maxAmount: maxAmount ?? this.maxAmount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
    );
  }
}