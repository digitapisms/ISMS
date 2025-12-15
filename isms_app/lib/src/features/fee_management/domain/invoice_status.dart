/// Invoice status enum
enum InvoiceStatus {
  pending('pending', 'Pending'),
  partial('partial', 'Partially Paid'),
  paid('paid', 'Paid'),
  overdue('overdue', 'Overdue'),
  cancelled('cancelled', 'Cancelled');

  const InvoiceStatus(this.dbValue, this.displayName);

  final String dbValue;
  final String displayName;

  static InvoiceStatus fromDb(String value) {
    return InvoiceStatus.values.firstWhere(
      (s) => s.dbValue == value,
      orElse: () => InvoiceStatus.pending,
    );
  }
}

/// Invoice type enum for Pakistani schools
enum InvoiceType {
  fee('fee', 'Regular Fee'),
  admission('admission', 'Admission Fee'),
  securityDeposit('security_deposit', 'Security Deposit'),
  transport('transport', 'Transport Fee'),
  other('other', 'Other');

  const InvoiceType(this.dbValue, this.displayName);

  final String dbValue;
  final String displayName;

  static InvoiceType fromDb(String value) {
    return InvoiceType.values.firstWhere(
      (t) => t.dbValue == value,
      orElse: () => InvoiceType.fee,
    );
  }
}
