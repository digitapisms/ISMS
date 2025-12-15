import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

import '../domain/fee_invoice.dart';
import '../application/fee_structure_engine.dart';

class ThreeCopyInvoicePdfService {
  /// Generate and print all three copies in a single PDF
  static Future<void> generateAndPrintThreeCopies({
    required Map<FeeCopyType, Map<String, dynamic>> copies,
    required FeeInvoice invoice,
    required String institutionType,
    required FeeStructureFormat format,
  }) async {
    final pdf = pw.Document();

    // Add each copy as a separate page
    for (final copyType in FeeCopyType.values) {
      final copyData = copies[copyType];
      if (copyData != null) {
        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            margin: const pw.EdgeInsets.all(40),
            build: (pw.Context context) {
              return _buildCopyPage(
                copyData,
                invoice,
                copyType,
                institutionType,
                format,
              );
            },
          ),
        );
      }
    }

    // Print the PDF
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  /// Generate and print a single copy
  static Future<void> generateAndPrintSingleCopy({
    required Map<String, dynamic> invoiceData,
    required FeeInvoice invoice,
    required FeeCopyType copyType,
    required String institutionType,
    required FeeStructureFormat format,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) {
          return _buildCopyPage(
            invoiceData,
            invoice,
            copyType,
            institutionType,
            format,
          );
        },
      ),
    );

    // Print the PDF
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  /// Build a single copy page
  static pw.Widget _buildCopyPage(
    Map<String, dynamic> invoiceData,
    FeeInvoice invoice,
    FeeCopyType copyType,
    String institutionType,
    FeeStructureFormat format,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Header with copy type identification
        _buildHeader(institutionType, copyType, format),
        pw.SizedBox(height: 20),
        pw.Divider(),
        pw.SizedBox(height: 20),

        // Title
        pw.Center(
          child: pw.Text(
            'FEE INVOICE - ${_getCopyTypeName(copyType).toUpperCase()}',
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ),
        pw.SizedBox(height: 20),

        // Invoice Details
        _buildInvoiceDetails(invoiceData, invoice),
        pw.SizedBox(height: 20),

        // Student Details
        if (invoiceData.containsKey('studentDetails'))
          _buildStudentDetails(invoiceData['studentDetails']),
        pw.SizedBox(height: 20),

        // Fee Breakdown
        if (invoiceData.containsKey('feeBreakdown'))
          _buildFeeBreakdown(invoiceData['feeBreakdown']),
        pw.SizedBox(height: 20),

        // Amount Summary
        _buildAmountSummary(invoiceData),
        pw.SizedBox(height: 20),

        // Payment Instructions (for student/school copies)
        if ((copyType == FeeCopyType.studentCopy || 
             copyType == FeeCopyType.schoolCopy) &&
            invoiceData.containsKey('paymentInstructions'))
          _buildPaymentInstructions(invoiceData['paymentInstructions']),

        // Bank Details (for bank copy)
        if (copyType == FeeCopyType.bankCopy && 
            invoiceData.containsKey('bankDetails'))
          _buildBankDetails(invoiceData['bankDetails']),

        pw.SizedBox(height: 20),

        // Footer with copy-specific information
        _buildFooter(copyType),

        // Watermark
        _buildWatermark(copyType),
      ],
    );
  }

  static pw.Widget _buildHeader(
    String institutionType,
    FeeCopyType copyType,
    FeeStructureFormat format,
  ) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              institutionType.toUpperCase(),
              style: pw.TextStyle(
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.Text(
              'Fee Management System',
              style: const pw.TextStyle(fontSize: 10),
            ),
          ],
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text(
              _getCopyTypeName(copyType).toUpperCase(),
              style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
                color: _getCopyColorPdf(copyType),
              ),
            ),
            pw.Text(
              'Format: ${_getFormatName(format).toUpperCase()}',
              style: const pw.TextStyle(fontSize: 9),
            ),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildInvoiceDetails(
    Map<String, dynamic> invoiceData,
    FeeInvoice invoice,
  ) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _buildInfoRow('Invoice #:', invoice.invoiceNumber),
            if (invoiceData.containsKey('issueDate') && invoiceData['issueDate'] != null)
              _buildInfoRow(
                'Issue Date:',
                DateFormat('dd MMM yyyy').format(DateTime.parse(invoiceData['issueDate'])),
              ),
            _buildInfoRow(
              'Due Date:',
              DateFormat('dd MMM yyyy').format(invoice.dueDate),
            ),
          ],
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _buildInfoRow('Status:', invoice.status.displayName),
            if (invoiceData.containsKey('academicYear'))
              _buildInfoRow('Academic Year:', invoiceData['academicYear']),
            if (invoiceData.containsKey('term'))
              _buildInfoRow('Term:', invoiceData['term']),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildStudentDetails(Map<String, dynamic> studentDetails) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'STUDENT INFORMATION',
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 8),
          _buildInfoRow('Name:', studentDetails['name']),
          if (studentDetails.containsKey('class'))
            _buildInfoRow('Class:', studentDetails['class']),
          if (studentDetails.containsKey('section'))
            _buildInfoRow('Section:', studentDetails['section']),
          if (studentDetails.containsKey('rollNumber'))
            _buildInfoRow('Roll #:', studentDetails['rollNumber']),
          if (studentDetails.containsKey('admissionNo'))
            _buildInfoRow('Admission #:', studentDetails['admissionNo']),
        ],
      ),
    );
  }

  static pw.Widget _buildFeeBreakdown(List<dynamic> feeBreakdown) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'FEE BREAKDOWN',
          style: pw.TextStyle(
            fontSize: 12,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 8),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300),
          children: [
            // Header
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey200),
              children: [
                _buildTableCell('Description', isHeader: true),
                _buildTableCell('Amount', isHeader: true),
                _buildTableCell('Remarks', isHeader: true),
              ],
            ),
            // Items
            ...feeBreakdown.map((item) {
              return pw.TableRow(
                children: [
                  _buildTableCell(item['description'] ?? ''),
                  _buildTableCell('PKR ${(item['amount'] ?? 0).toStringAsFixed(2)}'),
                  _buildTableCell(item['remarks'] ?? ''),
                ],
              );
            }),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildAmountSummary(Map<String, dynamic> invoiceData) {
    final totalAmount = (invoiceData['totalAmount'] ?? 0).toDouble();
    final paidAmount = (invoiceData['paidAmount'] ?? 0).toDouble();
    final outstandingAmount = totalAmount - paidAmount;

    return pw.Align(
      alignment: pw.Alignment.centerRight,
      child: pw.Container(
        width: 250,
        padding: const pw.EdgeInsets.all(12),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.grey300),
          borderRadius: pw.BorderRadius.circular(4),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            _buildSummaryRow('Total Amount:', totalAmount),
            if (paidAmount > 0)
              _buildSummaryRow('Paid Amount:', paidAmount, color: PdfColors.green),
            pw.Divider(),
            _buildSummaryRow(
              'Outstanding Amount:',
              outstandingAmount,
              color: outstandingAmount > 0 ? PdfColors.red : PdfColors.green,
              isBold: true,
            ),
          ],
        ),
      ),
    );
  }

  static pw.Widget _buildPaymentInstructions(Map<String, dynamic> instructions) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'PAYMENT INSTRUCTIONS',
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 8),
          if (instructions.containsKey('methods'))
            pw.Text('Payment Methods: ${instructions['methods']}'),
          if (instructions.containsKey('dueDateNote'))
            pw.Text('Due Date: ${instructions['dueDateNote']}'),
          if (instructions.containsKey('lateFeeNote'))
            pw.Text('Late Fee: ${instructions['lateFeeNote']}'),
          if (instructions.containsKey('contactInfo'))
            pw.Text('Contact: ${instructions['contactInfo']}'),
        ],
      ),
    );
  }

  static pw.Widget _buildBankDetails(Map<String, dynamic> bankDetails) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.blue300),
        borderRadius: pw.BorderRadius.circular(4),
        color: PdfColors.blue50,
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'BANK PAYMENT DETAILS',
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue700,
            ),
          ),
          pw.SizedBox(height: 8),
          if (bankDetails.containsKey('accountName'))
            _buildInfoRow('Account Name:', bankDetails['accountName']),
          if (bankDetails.containsKey('accountNumber'))
            _buildInfoRow('Account #:', bankDetails['accountNumber']),
          if (bankDetails.containsKey('bankName'))
            _buildInfoRow('Bank Name:', bankDetails['bankName']),
          if (bankDetails.containsKey('branch'))
            _buildInfoRow('Branch:', bankDetails['branch']),
          if (bankDetails.containsKey('iban'))
            _buildInfoRow('IBAN:', bankDetails['iban']),
          if (bankDetails.containsKey('swiftCode'))
            _buildInfoRow('SWIFT Code:', bankDetails['swiftCode']),
          if (bankDetails.containsKey('reference'))
            _buildInfoRow('Reference:', bankDetails['reference']),
        ],
      ),
    );
  }

  static pw.Widget _buildFooter(FeeCopyType copyType) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Divider(),
        pw.SizedBox(height: 10),
        pw.Text(
          _getFooterText(copyType),
          style: pw.TextStyle(
            fontSize: 9,
            fontStyle: pw.FontStyle.italic,
            color: PdfColors.grey600,
          ),
          textAlign: pw.TextAlign.center,
        ),
      ],
    );
  }

  static pw.Widget _buildWatermark(FeeCopyType copyType) {
    return pw.Align(
      alignment: pw.Alignment.center,
      child: pw.Opacity(
        opacity: 0.1,
        child: pw.Text(
          _getCopyTypeName(copyType).toUpperCase(),
          style: pw.TextStyle(
            fontSize: 48,
            fontWeight: pw.FontWeight.bold,
            color: _getCopyColorPdf(copyType),
          ),
        ),
      ),
    );
  }

  static pw.Widget _buildInfoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Row(
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(width: 8),
          pw.Text(value, style: const pw.TextStyle(fontSize: 10)),
        ],
      ),
    );
  }

  static pw.Widget _buildTableCell(String text, {bool isHeader = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: isHeader ? 10 : 9,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  static pw.Widget _buildSummaryRow(
    String label,
    double amount, {
    PdfColor? color,
    bool isBold = false,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
          pw.Text(
            'PKR ${amount.toStringAsFixed(2)}',
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  static String _getCopyTypeName(FeeCopyType copyType) {
    switch (copyType) {
      case FeeCopyType.studentCopy:
        return 'Student Copy';
      case FeeCopyType.schoolCopy:
        return 'School Copy';
      case FeeCopyType.bankCopy:
        return 'Bank Copy';
    }
  }

  static PdfColor _getCopyColorPdf(FeeCopyType copyType) {
    switch (copyType) {
      case FeeCopyType.studentCopy:
        return PdfColors.blue700;
      case FeeCopyType.schoolCopy:
        return PdfColors.green700;
      case FeeCopyType.bankCopy:
        return PdfColors.orange700;
    }
  }

  static String _getFormatName(FeeStructureFormat format) {
    switch (format) {
      case FeeStructureFormat.standard:
        return 'Standard';
      case FeeStructureFormat.simplified:
        return 'Simplified';
      case FeeStructureFormat.consolidated:
        return 'Consolidated';
    }
  }

  static String _getFooterText(FeeCopyType copyType) {
    switch (copyType) {
      case FeeCopyType.studentCopy:
        return 'This is your copy of the fee invoice. Please keep it for your records.';
      case FeeCopyType.schoolCopy:
        return 'School copy - For accounting and record keeping purposes.';
      case FeeCopyType.bankCopy:
        return 'Bank copy - Present this copy at the bank for payment processing.';
    }
  }
}