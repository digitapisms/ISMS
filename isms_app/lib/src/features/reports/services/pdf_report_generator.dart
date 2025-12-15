import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';

import '../../school_registration/domain/school.dart';
import '../domain/school_report_overview.dart';

/// Service for generating PDF reports
class PDFReportGenerator {
  /// Generate comprehensive school report PDF
  Future<Uint8List> generateSchoolReport({
    required School school,
    required SchoolReportOverview overview,
    required Map<String, dynamic> additionalData,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) => [
          _buildHeader(school),
          pw.SizedBox(height: 20),
          _buildOverviewSection(overview),
          pw.SizedBox(height: 20),
          _buildStatisticsSection(overview),
          pw.SizedBox(height: 20),
          _buildTrendsSection(additionalData),
          pw.SizedBox(height: 20),
          _buildFooter(),
        ],
      ),
    );

    return pdf.save();
  }

  /// Generate attendance report PDF
  Future<Uint8List> generateAttendanceReport({
    required School school,
    required Map<String, dynamic> attendanceData,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final pdf = pw.Document();
    final dateFormat = DateFormat('dd MMM yyyy');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) => [
          _buildHeader(school),
          pw.SizedBox(height: 10),
          pw.Text(
            'Attendance Report',
            style: pw.TextStyle(
              fontSize: 24,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.Text(
            'Period: ${dateFormat.format(startDate)} - ${dateFormat.format(endDate)}',
            style: const pw.TextStyle(fontSize: 12),
          ),
          pw.SizedBox(height: 20),
          _buildAttendanceTable(attendanceData),
          pw.SizedBox(height: 20),
          _buildFooter(),
        ],
      ),
    );

    return pdf.save();
  }

  /// Generate financial report PDF
  Future<Uint8List> generateFinancialReport({
    required School school,
    required Map<String, dynamic> financialData,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final pdf = pw.Document();
    final dateFormat = DateFormat('dd MMM yyyy');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) => [
          _buildHeader(school),
          pw.SizedBox(height: 10),
          pw.Text(
            'Financial Report',
            style: pw.TextStyle(
              fontSize: 24,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.Text(
            'Period: ${dateFormat.format(startDate)} - ${dateFormat.format(endDate)}',
            style: const pw.TextStyle(fontSize: 12),
          ),
          pw.SizedBox(height: 20),
          _buildFinancialSummary(financialData),
          pw.SizedBox(height: 20),
          _buildFinancialTable(financialData),
          pw.SizedBox(height: 20),
          _buildFooter(),
        ],
      ),
    );

    return pdf.save();
  }

  pw.Widget _buildHeader(School school) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  school.name,
                  style: pw.TextStyle(
                    fontSize: 28,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                if (school.slogan != null)
                  pw.Text(
                    school.slogan!,
                    style: const pw.TextStyle(fontSize: 12),
                  ),
              ],
            ),
            pw.Text(
              DateFormat('dd MMM yyyy').format(DateTime.now()),
              style: const pw.TextStyle(fontSize: 10),
            ),
          ],
        ),
        pw.Divider(),
      ],
    );
  }

  pw.Widget _buildOverviewSection(SchoolReportOverview overview) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Overview',
          style: pw.TextStyle(
            fontSize: 18,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 10),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
          children: [
            _buildStatCard('Total Students', overview.totalStudents.toString()),
            _buildStatCard('Total Staff', (overview.staffCount + overview.teacherCount).toString()),
            _buildStatCard('Classes', overview.classCount.toString()),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildStatCard(String label, String value) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(5),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 20,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.Text(
            label,
            style: const pw.TextStyle(fontSize: 10),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildStatisticsSection(SchoolReportOverview overview) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Statistics',
          style: pw.TextStyle(
            fontSize: 18,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 10),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300),
          children: [
            _buildTableRow(['Metric', 'Value']),
            _buildTableRow(['Total Students', overview.totalStudents.toString()]),
            _buildTableRow(['New Students (30d)', overview.newStudents30d.toString()]),
            _buildTableRow(['Total Applications', overview.totalApplications.toString()]),
            _buildTableRow(['Approved Applications', overview.approvedApplications.toString()]),
            _buildTableRow(['Application Conversion Rate', '${overview.applicationConversionRate.toStringAsFixed(1)}%']),
          ],
        ),
      ],
    );
  }

  pw.TableRow _buildTableRow(List<String> cells) {
    return pw.TableRow(
      children: cells.map((cell) => pw.Padding(
        padding: const pw.EdgeInsets.all(8),
        child: pw.Text(cell),
      )).toList(),
    );
  }

  pw.Widget _buildTrendsSection(Map<String, dynamic> data) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Trends & Analysis',
          style: pw.TextStyle(
            fontSize: 18,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 10),
        pw.Text(
          'Key trends and insights based on recent data analysis.',
          style: const pw.TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  pw.Widget _buildAttendanceTable(Map<String, dynamic> data) {
    final students = data['students'] as List<dynamic>? ?? [];
    
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      columnWidths: {
        0: const pw.FlexColumnWidth(2),
        1: const pw.FlexColumnWidth(1),
        2: const pw.FlexColumnWidth(1),
        3: const pw.FlexColumnWidth(1),
      },
      children: [
        _buildTableRow(['Student', 'Present', 'Absent', 'Rate']),
        ...students.take(20).map((student) {
          final present = student['present'] ?? 0;
          final absent = student['absent'] ?? 0;
          final total = present + absent;
          final rate = total > 0 ? (present / total * 100).toStringAsFixed(1) : '0.0';
          return _buildTableRow([
            student['name']?.toString() ?? 'N/A',
            present.toString(),
            absent.toString(),
            '$rate%',
          ]);
        }).toList(),
      ],
    );
  }

  pw.Widget _buildFinancialSummary(Map<String, dynamic> data) {
    final totalRevenue = data['total_revenue'] ?? 0;
    final totalExpenses = data['total_expenses'] ?? 0;
    final netIncome = totalRevenue - totalExpenses;

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      children: [
        _buildTableRow(['Total Revenue', _formatCurrency(totalRevenue)]),
        _buildTableRow(['Total Expenses', _formatCurrency(totalExpenses)]),
        _buildTableRow(['Net Income', _formatCurrency(netIncome)]),
      ],
    );
  }

  pw.Widget _buildFinancialTable(Map<String, dynamic> data) {
    final transactions = data['transactions'] as List<dynamic>? ?? [];
    
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      columnWidths: {
        0: const pw.FlexColumnWidth(1),
        1: const pw.FlexColumnWidth(2),
        2: const pw.FlexColumnWidth(1),
        3: const pw.FlexColumnWidth(1),
      },
      children: [
        _buildTableRow(['Date', 'Description', 'Type', 'Amount']),
        ...transactions.take(30).map((transaction) {
          return _buildTableRow([
            DateFormat('dd/MM/yyyy').format(
              DateTime.parse(transaction['date'] ?? DateTime.now().toIso8601String()),
            ),
            transaction['description']?.toString() ?? 'N/A',
            transaction['type']?.toString() ?? 'N/A',
            _formatCurrency(transaction['amount'] ?? 0),
          ]);
        }).toList(),
      ],
    );
  }

  pw.Widget _buildFooter() {
    return pw.Container(
      alignment: pw.Alignment.center,
      child: pw.Text(
        'Generated by ISMS - ${DateFormat('dd MMM yyyy HH:mm').format(DateTime.now())}',
        style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
      ),
    );
  }

  String _formatCurrency(num amount) {
    return 'PKR ${amount.toStringAsFixed(2)}';
  }
}

