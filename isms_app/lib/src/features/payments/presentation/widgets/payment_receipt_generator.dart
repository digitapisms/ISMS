import 'dart:io';

import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';

import '../../domain/payment_transaction.dart';

class PaymentReceiptGenerator {
  /// Generate and share payment receipt PDF
  static Future<void> generateReceipt({
    required BuildContext context,
    required PaymentTransaction transaction,
  }) async {
    try {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Generating receipt...')));

      final pdf = pw.Document();
      final dateFormat = DateFormat('MMM dd, yyyy HH:mm');

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Padding(
              padding: const pw.EdgeInsets.all(40),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Header
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'PAYMENT RECEIPT',
                            style: pw.TextStyle(
                              fontSize: 24,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          pw.SizedBox(height: 4),
                          pw.Text(
                            'Transaction ID: ${transaction.id.substring(0, 8)}...',
                            style: pw.TextStyle(
                              fontSize: 10,
                              color: PdfColors.grey700,
                            ),
                          ),
                        ],
                      ),
                      pw.Container(
                        padding: const pw.EdgeInsets.all(12),
                        decoration: pw.BoxDecoration(
                          color: transaction.isSuccessful
                              ? PdfColors.green
                              : PdfColors.red,
                          borderRadius: pw.BorderRadius.circular(4),
                        ),
                        child: pw.Text(
                          transaction.status.toUpperCase(),
                          style: pw.TextStyle(
                            color: PdfColors.white,
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 30),

                  // Amount
                  pw.Container(
                    width: double.infinity,
                    padding: const pw.EdgeInsets.all(20),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.grey100,
                      borderRadius: pw.BorderRadius.circular(8),
                    ),
                    child: pw.Column(
                      children: [
                        pw.Text(
                          'Amount Paid',
                          style: pw.TextStyle(
                            fontSize: 12,
                            color: PdfColors.grey700,
                          ),
                        ),
                        pw.SizedBox(height: 8),
                        pw.Text(
                          '${transaction.currency} ${NumberFormat('#,##0.00').format(transaction.amount)}',
                          style: pw.TextStyle(
                            fontSize: 32,
                            fontWeight: pw.FontWeight.bold,
                            color: transaction.isSuccessful
                                ? PdfColors.green
                                : PdfColors.grey700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  pw.SizedBox(height: 30),

                  // Payer Information
                  if (transaction.payerName != null ||
                      transaction.payerEmail != null ||
                      transaction.payerPhone != null) ...[
                    pw.Text(
                      'Payer Information',
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 12),
                    if (transaction.payerName != null)
                      _buildDetailRow('Name', transaction.payerName!),
                    if (transaction.payerEmail != null)
                      _buildDetailRow('Email', transaction.payerEmail!),
                    if (transaction.payerPhone != null)
                      _buildDetailRow('Phone', transaction.payerPhone!),
                    pw.SizedBox(height: 20),
                  ],

                  // Transaction Details
                  pw.Text(
                    'Transaction Details',
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 12),
                  _buildDetailRow('Transaction ID', transaction.id),
                  if (transaction.referenceCode != null)
                    _buildDetailRow(
                      'Reference Code',
                      transaction.referenceCode!,
                    ),
                  if (transaction.externalReference != null)
                    _buildDetailRow(
                      'External Reference',
                      transaction.externalReference!,
                    ),
                  if (transaction.initiatedAt != null)
                    _buildDetailRow(
                      'Initiated At',
                      dateFormat.format(transaction.initiatedAt!),
                    ),
                  if (transaction.completedAt != null)
                    _buildDetailRow(
                      'Completed At',
                      dateFormat.format(transaction.completedAt!),
                    ),
                  pw.SizedBox(height: 20),

                  // Footer
                  pw.Divider(),
                  pw.SizedBox(height: 20),
                  pw.Text(
                    'This is a computer-generated receipt.',
                    style: pw.TextStyle(
                      fontSize: 10,
                      color: PdfColors.grey600,
                      fontStyle: pw.FontStyle.italic,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'Generated on: ${dateFormat.format(DateTime.now())}',
                    style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
                  ),
                ],
              ),
            );
          },
        ),
      );

      // Save and share
      final output = await getTemporaryDirectory();
      final file = File(
        '${output.path}/payment_receipt_${transaction.id.substring(0, 8)}.pdf',
      );
      await file.writeAsBytes(await pdf.save());

      await Printing.sharePdf(
        bytes: await file.readAsBytes(),
        filename: file.path.split('/').last,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Receipt generated successfully')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error generating receipt: $e')));
      }
    }
  }

  static pw.Widget _buildDetailRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 120,
            child: pw.Text(
              label,
              style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value,
              style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
