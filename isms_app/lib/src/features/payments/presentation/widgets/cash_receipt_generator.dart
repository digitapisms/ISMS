import 'dart:io';

import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';

import '../../domain/cash_fee_receipt.dart';

class CashReceiptGenerator {
  /// Generate and share cash receipt PDF
  static Future<void> generateReceipt({
    required BuildContext context,
    required CashFeeReceipt receipt,
    String? schoolName,
  }) async {
    try {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Generating receipt...')));

      final pdf = pw.Document();
      final dateFormat = DateFormat('MMM dd, yyyy');

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
                            'CASH PAYMENT RECEIPT',
                            style: pw.TextStyle(
                              fontSize: 24,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          if (schoolName != null) ...[
                            pw.SizedBox(height: 4),
                            pw.Text(
                              schoolName,
                              style: pw.TextStyle(
                                fontSize: 12,
                                color: PdfColors.grey700,
                              ),
                            ),
                          ],
                        ],
                      ),
                      pw.Container(
                        padding: const pw.EdgeInsets.all(12),
                        decoration: pw.BoxDecoration(
                          color: PdfColors.green,
                          borderRadius: pw.BorderRadius.circular(4),
                        ),
                        child: pw.Text(
                          'PAID',
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
                          'Amount Received',
                          style: pw.TextStyle(
                            fontSize: 12,
                            color: PdfColors.grey700,
                          ),
                        ),
                        pw.SizedBox(height: 8),
                        pw.Text(
                          '${receipt.currency} ${NumberFormat('#,##0.00').format(receipt.amount)}',
                          style: pw.TextStyle(
                            fontSize: 32,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.green,
                          ),
                        ),
                      ],
                    ),
                  ),
                  pw.SizedBox(height: 30),

                  // Payer Information
                  pw.Text(
                    'Payment Details',
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 12),
                  _buildDetailRow('Payer Name', receipt.payerName),
                  _buildDetailRow(
                    'Payment Date',
                    dateFormat.format(receipt.paymentDate),
                  ),
                  if (receipt.receiptNumber != null)
                    _buildDetailRow('Receipt Number', receipt.receiptNumber!),
                  pw.SizedBox(height: 20),

                  // Notes
                  if (receipt.notes != null && receipt.notes!.isNotEmpty) ...[
                    pw.Text(
                      'Notes',
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Container(
                      width: double.infinity,
                      padding: const pw.EdgeInsets.all(12),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.grey100,
                        borderRadius: pw.BorderRadius.circular(4),
                      ),
                      child: pw.Text(
                        receipt.notes!,
                        style: pw.TextStyle(fontSize: 10),
                      ),
                    ),
                    pw.SizedBox(height: 20),
                  ],

                  // Footer
                  pw.Divider(),
                  pw.SizedBox(height: 20),
                  pw.Text(
                    'This is a computer-generated receipt for cash payment.',
                    style: pw.TextStyle(
                      fontSize: 10,
                      color: PdfColors.grey600,
                      fontStyle: pw.FontStyle.italic,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'Generated on: ${DateFormat('MMM dd, yyyy HH:mm').format(DateTime.now())}',
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
      final receiptId = receipt.receiptNumber ?? receipt.id.substring(0, 8);
      final file = File('${output.path}/cash_receipt_$receiptId.pdf');
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
