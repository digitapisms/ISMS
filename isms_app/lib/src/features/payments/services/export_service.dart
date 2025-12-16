import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../domain/payment_transaction.dart';

class ExportService {
  static Future<String> exportTransactionsToCSV(List<PaymentTransaction> transactions) async {
    final csvBuffer = StringBuffer();
    
    // CSV header
    csvBuffer.writeln('Date,Reference,External Reference,Payer Name,Amount,Currency,Status,Payment Method,Initiated At,Completed At,Error Message');
    
    // CSV rows
    for (final transaction in transactions) {
      final row = [
        _escapeCsvField(DateFormat('yyyy-MM-dd').format(transaction.initiatedAt ?? DateTime.now())),
        _escapeCsvField(transaction.referenceCode ?? ''),
        _escapeCsvField(transaction.externalReference ?? ''),
        _escapeCsvField(transaction.payerName ?? ''),
        transaction.amount.toString(),
        _escapeCsvField(transaction.currency),
        _escapeCsvField(transaction.status),
        _escapeCsvField(transaction.providerId ?? ''), // TODO: paymentMethod property doesn't exist
        _escapeCsvField(transaction.initiatedAt != null ? DateFormat('yyyy-MM-dd HH:mm:ss').format(transaction.initiatedAt!) : ''),
        _escapeCsvField(transaction.completedAt != null ? DateFormat('yyyy-MM-dd HH:mm:ss').format(transaction.completedAt!) : ''),
        _escapeCsvField(transaction.errorMessage ?? ''),
      ];
      
      csvBuffer.writeln(row.join(','));
    }
    
    return csvBuffer.toString();
  }
  
  static Future<void> saveCSVToFile(String csvContent, String fileName) async {
    final data = utf8.encode(csvContent);
    final blob = ByteData.view(data.buffer);
    
    await MethodChannel('isms_app/export').invokeMethod('saveFile', {
      'data': blob,
      'fileName': fileName,
      'mimeType': 'text/csv',
    });
  }
  
  static String _escapeCsvField(String field) {
    if (field.contains(',') || field.contains('"') || field.contains('\n')) {
      return '"${field.replaceAll('"', '""')}"';
    }
    return field;
  }
  
  static Future<String> exportTransactionsToExcel(List<PaymentTransaction> transactions) async {
    // For Excel export, we'll use CSV format which Excel can open
    // In a real implementation, you might use a package like excel or syncfusion_flutter_xlsio
    return exportTransactionsToCSV(transactions);
  }
  
  static String generateExportFileName({String prefix = 'transactions', String format = 'csv'}) {
    final now = DateTime.now();
    final dateStr = DateFormat('yyyyMMdd_HHmmss').format(now);
    return '${prefix}_$dateStr.$format';
  }
}