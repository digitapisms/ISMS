import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

import '../domain/fee_invoice.dart';
import '../domain/fee_invoice_item.dart';
import '../../student_management/domain/student.dart';
import '../../school_registration/domain/school.dart';

class FeeInvoicePdfService {
  static Future<void> generateAndPrintChallan({
    required FeeInvoice invoice,
    required Student student,
    School? school,
    required List<FeeInvoiceItem> items,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              _buildHeader(school),
              pw.SizedBox(height: 20),
              pw.Divider(),
              pw.SizedBox(height: 20),
              // Title
              pw.Center(
                child: pw.Text(
                  'FEE CHALLAN / INVOICE',
                  style: pw.TextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 20),
              // Invoice Details
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      _buildInfoRow('Invoice Number:', invoice.invoiceNumber),
                      _buildInfoRow(
                        'Issue Date:',
                        invoice.issueDate != null
                            ? DateFormat(
                                'dd MMM yyyy',
                              ).format(invoice.issueDate!)
                            : DateFormat('dd MMM yyyy').format(DateTime.now()),
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
                      _buildInfoRow('Student ID:', student.admissionNo),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 20),
              // Student Details
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Student Information',
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    _buildInfoRow('Name:', student.fullName),
                    _buildInfoRow('Admission No:', student.admissionNo),
                    if (student.className != null)
                      _buildInfoRow('Class:', student.className!),
                    if (student.sectionName != null)
                      _buildInfoRow('Section:', student.sectionName!),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),
              // Items Table
              pw.Text(
                'Fee Details',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 8),
              _buildItemsTable(items),
              pw.SizedBox(height: 20),
              // Summary
              pw.Align(
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
                      _buildSummaryRow('Subtotal:', invoice.totalAmount),
                      if (invoice.discountAmount > 0)
                        _buildSummaryRow(
                          'Discount:',
                          -invoice.discountAmount,
                          color: PdfColors.green,
                        ),
                      if (invoice.lateFeeAmount > 0)
                        _buildSummaryRow(
                          'Late Fee:',
                          invoice.lateFeeAmount,
                          color: PdfColors.red,
                        ),
                      pw.Divider(),
                      _buildSummaryRow(
                        'Total Amount:',
                        invoice.totalAmount,
                        isBold: true,
                      ),
                      _buildSummaryRow(
                        'Paid Amount:',
                        invoice.paidAmount,
                        color: PdfColors.green,
                      ),
                      pw.Divider(),
                      _buildSummaryRow(
                        'Outstanding:',
                        invoice.outstandingAmount,
                        color: PdfColors.red,
                        isBold: true,
                      ),
                    ],
                  ),
                ),
              ),
              if (invoice.notes != null && invoice.notes!.isNotEmpty) ...[
                pw.SizedBox(height: 20),
                pw.Container(
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey100,
                    borderRadius: pw.BorderRadius.circular(4),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Notes:',
                        style: pw.TextStyle(
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        invoice.notes!,
                        style: const pw.TextStyle(fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
              pw.Spacer(),
              // Footer
              pw.Divider(),
              pw.SizedBox(height: 10),
              pw.Center(
                child: pw.Text(
                  'This is a computer-generated challan. No signature required.',
                  style: pw.TextStyle(
                    fontSize: 10,
                    color: PdfColors.grey600,
                    fontStyle: pw.FontStyle.italic,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );

    // Print or save PDF
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  static pw.Widget _buildHeader(School? school) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: school != null
              ? [
                  pw.Text(
                    school.name,
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  if (school.address != null && school.address!.isNotEmpty)
                    pw.Text(
                      school.address!,
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                  pw.Text(
                    'Phone: ${school.phone}',
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                  pw.Text(
                    'Email: ${school.email}',
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                ]
              : [
                  pw.Text(
                    'School Management System',
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text(
              'FEE CHALLAN',
              style: pw.TextStyle(
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blue700,
              ),
            ),
          ],
        ),
      ],
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
              fontSize: 11,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(width: 8),
          pw.Text(value, style: const pw.TextStyle(fontSize: 11)),
        ],
      ),
    );
  }

  static pw.Widget _buildItemsTable(List<FeeInvoiceItem> items) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      children: [
        // Header
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: [
            _buildTableCell('Description', isHeader: true),
            _buildTableCell('Qty', isHeader: true),
            _buildTableCell('Unit Price', isHeader: true),
            _buildTableCell('Total', isHeader: true),
          ],
        ),
        // Items
        ...items.map((item) {
          return pw.TableRow(
            children: [
              _buildTableCell(item.description),
              _buildTableCell(item.quantity.toString()),
              _buildTableCell('PKR ${item.unitAmount.toStringAsFixed(2)}'),
              _buildTableCell('PKR ${item.totalAmount.toStringAsFixed(2)}'),
            ],
          );
        }),
      ],
    );
  }

  static pw.Widget _buildTableCell(String text, {bool isHeader = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: isHeader ? 11 : 10,
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
              fontSize: 11,
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
          pw.Text(
            'PKR ${amount.toStringAsFixed(2)}',
            style: pw.TextStyle(
              fontSize: 11,
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
