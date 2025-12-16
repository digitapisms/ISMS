import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../institution/application/institution_config_loader.dart';
import '../../application/fee_structure_engine.dart';
import '../../domain/fee_invoice.dart';
import '../../domain/fee_structure.dart';
import '../../services/three_copy_invoice_pdf_service.dart';

class ThreeCopyInvoiceViewer extends ConsumerStatefulWidget {
  final FeeInvoice invoice;
  final List<FeeStructure> feeStructures;
  final String institutionTypeId;

  const ThreeCopyInvoiceViewer({
    super.key,
    required this.invoice,
    required this.feeStructures,
    required this.institutionTypeId,
  });

  @override
  ConsumerState<ThreeCopyInvoiceViewer> createState() =>
      _ThreeCopyInvoiceViewerState();
}

class _ThreeCopyInvoiceViewerState
    extends ConsumerState<ThreeCopyInvoiceViewer> {
  FeeStructureFormat _selectedFormat = FeeStructureFormat.standard;
  FeeCopyType _selectedCopy = FeeCopyType.studentCopy;
  bool _showAllCopies = false;

  String _getInstitutionTypeDisplayName(String institutionTypeId) {
    switch (institutionTypeId.toLowerCase()) {
      case 'school':
        return 'School';
      case 'madarsa':
      case 'madrasa':
        return 'Madrasa';
      case 'coaching_center':
        return 'Coaching Center';
      case 'tuition_center':
        return 'Tuition Center';
      case 'online_institute':
        return 'Online Institute';
      default:
        return 'Institution';
    }
  }

  @override
  Widget build(BuildContext context) {
    final feeEngine = ref.watch(feeStructureEngineProvider);
    final configLoader = ref.watch(institutionConfigLoaderProvider);

    return FutureBuilder(
      future: configLoader.loadAcademicConfig(widget.institutionTypeId),
      builder: (context, configSnapshot) {
        if (configSnapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }

        return FutureBuilder(
          future: feeEngine.getSupportedFormats(widget.institutionTypeId),
          builder: (context, formatSnapshot) {
            if (formatSnapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }

            final supportedFormats =
                formatSnapshot.data ?? [FeeStructureFormat.standard];

            return FutureBuilder(
              future: _showAllCopies
                  ? feeEngine.generateThreeCopies(
                      institutionTypeId: widget.institutionTypeId,
                      invoice: widget.invoice,
                      feeStructures: widget.feeStructures,
                      format: _selectedFormat,
                    )
                  : feeEngine
                      .generateFeeInvoice(
                        institutionTypeId: widget.institutionTypeId,
                        invoice: widget.invoice,
                        feeStructures: widget.feeStructures,
                        format: _selectedFormat,
                      )
                      .then(
                        (invoice) => {_selectedCopy: invoice},
                      ),
              builder: (context, invoiceSnapshot) {
                if (invoiceSnapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }

                final invoiceData = invoiceSnapshot.data!;

                return Scaffold(
                  appBar: AppBar(
                    title: const Text('Fee Invoice'),
                    actions: [
                      // Format selector
                      if (supportedFormats.length > 1)
                        PopupMenuButton<FeeStructureFormat>(
                          icon: const Icon(Icons.format_shapes),
                          onSelected: (format) {
                            setState(() {
                              _selectedFormat = format;
                            });
                          },
                          itemBuilder: (context) => supportedFormats
                              .map(
                                (format) => PopupMenuItem(
                                  value: format,
                                  child: Text(_getFormatName(format)),
                                ),
                              )
                              .toList(),
                        ),

                      // Copy type selector
                      PopupMenuButton<FeeCopyType>(
                        icon: const Icon(Icons.content_copy),
                        onSelected: (copyType) {
                          setState(() {
                            _selectedCopy = copyType;
                            _showAllCopies = false;
                          });
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: FeeCopyType.studentCopy,
                            child: Text('Student Copy'),
                          ),
                          const PopupMenuItem(
                            value: FeeCopyType.schoolCopy,
                            child: Text('School Copy'),
                          ),
                          const PopupMenuItem(
                            value: FeeCopyType.bankCopy,
                            child: Text('Bank Copy'),
                          ),
                        ],
                      ),

                      // Show all copies toggle
                      IconButton(
                        icon: Icon(
                          _showAllCopies
                              ? Icons.view_agenda
                              : Icons.view_carousel,
                        ),
                        onPressed: () {
                          setState(() {
                            _showAllCopies = !_showAllCopies;
                          });
                        },
                        tooltip: _showAllCopies
                            ? 'View Single Copy'
                            : 'View All Copies',
                      ),

                      // Print button
                      IconButton(
                        icon: const Icon(Icons.print),
                        onPressed: _printInvoice,
                        tooltip: 'Print Invoice',
                      ),
                    ],
                  ),
                  body: _showAllCopies
                      ? _buildAllCopiesView(invoiceData)
                      : _buildSingleCopyView(invoiceData[_selectedCopy]!),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildSingleCopyView(Map<String, dynamic> invoiceData) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: _buildInvoiceCard(invoiceData, _selectedCopy),
    );
  }

  Widget _buildAllCopiesView(Map<FeeCopyType, Map<String, dynamic>> invoices) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildInvoiceCard(
            invoices[FeeCopyType.studentCopy]!,
            FeeCopyType.studentCopy,
          ),
          const SizedBox(height: 20),
          _buildInvoiceCard(
            invoices[FeeCopyType.schoolCopy]!,
            FeeCopyType.schoolCopy,
          ),
          const SizedBox(height: 20),
          _buildInvoiceCard(
            invoices[FeeCopyType.bankCopy]!,
            FeeCopyType.bankCopy,
          ),
        ],
      ),
    );
  }

  Widget _buildInvoiceCard(
    Map<String, dynamic> invoiceData,
    FeeCopyType copyType,
  ) {
    final format = invoiceData['format'] as String;
    final institutionType = invoiceData['institutionType'] as String;

    return Card(
      elevation: 4,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          border: Border.all(color: _getCopyColor(copyType), width: 2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            _buildHeader(invoiceData, copyType, format, institutionType),

            const SizedBox(height: 20),

            // Student Details
            if (invoiceData.containsKey('studentDetails'))
              _buildStudentDetails(invoiceData['studentDetails']),

            const SizedBox(height: 20),

            // Fee Breakdown
            if (invoiceData.containsKey('feeBreakdown'))
              _buildFeeBreakdown(invoiceData['feeBreakdown']),

            const SizedBox(height: 20),

            // Amount Summary
            _buildAmountSummary(invoiceData),

            const SizedBox(height: 20),

            // Payment Instructions
            if (invoiceData.containsKey('paymentInstructions'))
              _buildPaymentInstructions(invoiceData['paymentInstructions']),

            const SizedBox(height: 20),

            // Bank Details (for bank copy)
            if (copyType == FeeCopyType.bankCopy &&
                invoiceData.containsKey('bankDetails'))
              _buildBankDetails(invoiceData['bankDetails']),

            const SizedBox(height: 20),

            // Footer
            _buildFooter(invoiceData, copyType),

            // Watermark
            _buildWatermark(copyType),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(
    Map<String, dynamic> data,
    FeeCopyType copyType,
    String format,
    String institutionType,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${institutionType.toUpperCase()} FEE INVOICE',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              'Format: ${format.toUpperCase()}',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),

        const SizedBox(height: 8),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Invoice #: ${data['invoiceNumber']}'),
            Text(
              'Due: ${DateFormat('MMM dd, yyyy').format(DateTime.parse(data['dueDate']))}',
            ),
          ],
        ),

        if (data.containsKey('issueDate') && data['issueDate'] != null)
          Text(
            'Issued: ${DateFormat('MMM dd, yyyy').format(DateTime.parse(data['issueDate']))}',
          ),
      ],
    );
  }

  Widget _buildStudentDetails(Map<String, dynamic> studentDetails) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'STUDENT DETAILS',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text('Name: ${studentDetails['name']}'),
        Text('Class: ${studentDetails['class']}'),
        Text('Section: ${studentDetails['section']}'),
        Text('Roll #: ${studentDetails['rollNumber']}'),
      ],
    );
  }

  Widget _buildFeeBreakdown(List<dynamic> feeBreakdown) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'FEE BREAKDOWN',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ...feeBreakdown
            .map(
              (item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        '${item['category']}${item['description'] != null ? ' - ${item['description']}' : ''}',
                      ),
                    ),
                    Text('PKR ${item['amount'].toStringAsFixed(2)}'),
                  ],
                ),
              ),
            )
            ,
      ],
    );
  }

  Widget _buildAmountSummary(Map<String, dynamic> data) {
    final numberFormat = NumberFormat.currency(symbol: 'PKR ');

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          _buildAmountRow('Total Amount', data['totalAmount'], numberFormat),
          _buildAmountRow('Paid Amount', data['paidAmount'], numberFormat),
          _buildAmountRow(
            'Outstanding Amount',
            data['outstandingAmount'],
            numberFormat,
            isBold: true,
          ),

          if (data.containsKey('tuitionAmount'))
            _buildAmountRow('Tuition Fee', data['tuitionAmount'], numberFormat),

          if (data.containsKey('zakatAmount'))
            _buildAmountRow('Zakat/Charity', data['zakatAmount'], numberFormat),
        ],
      ),
    );
  }

  Widget _buildAmountRow(
    String label,
    dynamic amount,
    NumberFormat format, {
    bool isBold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: isBold ? const TextStyle(fontWeight: FontWeight.bold) : null,
          ),
          Text(
            format.format(amount),
            style: isBold ? const TextStyle(fontWeight: FontWeight.bold) : null,
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentInstructions(String instructions) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'PAYMENT INSTRUCTIONS',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(instructions, style: TextStyle(color: Colors.grey[700])),
      ],
    );
  }

  Widget _buildBankDetails(Map<String, dynamic> bankDetails) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'BANK DETAILS',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text('Bank: ${bankDetails['bankName']}'),
        Text('Account: ${bankDetails['accountName']}'),
        Text('Account #: ${bankDetails['accountNumber']}'),
        Text('Branch: ${bankDetails['branchCode']}'),
      ],
    );
  }

  Widget _buildFooter(Map<String, dynamic> data, FeeCopyType copyType) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Divider(),
        const SizedBox(height: 8),
        Text(
          data['footerNote'] ?? '',
          style: TextStyle(
            fontStyle: FontStyle.italic,
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),

        if (copyType == FeeCopyType.schoolCopy &&
            data.containsKey('internalNotes'))
          Text(
            data['internalNotes'],
            style: TextStyle(color: Colors.grey[500], fontSize: 12),
          ),
      ],
    );
  }

  Widget _buildWatermark(FeeCopyType copyType) {
    return Positioned(
      right: 20,
      bottom: 20,
      child: Transform.rotate(
        angle: -0.5,
        child: Text(
          _getCopyLabel(copyType),
          style: TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.bold,
            color: _getCopyColor(copyType).withOpacity(0.1),
          ),
        ),
      ),
    );
  }

  Color _getCopyColor(FeeCopyType copyType) {
    switch (copyType) {
      case FeeCopyType.studentCopy:
        return Colors.blue;
      case FeeCopyType.schoolCopy:
        return Colors.green;
      case FeeCopyType.bankCopy:
        return Colors.orange;
    }
  }

  String _getCopyLabel(FeeCopyType copyType) {
    switch (copyType) {
      case FeeCopyType.studentCopy:
        return 'STUDENT COPY';
      case FeeCopyType.schoolCopy:
        return 'SCHOOL COPY';
      case FeeCopyType.bankCopy:
        return 'BANK COPY';
    }
  }

  String _getFormatName(FeeStructureFormat format) {
    switch (format) {
      case FeeStructureFormat.standard:
        return 'Standard Format';
      case FeeStructureFormat.simplified:
        return 'Simplified Format';
      case FeeStructureFormat.consolidated:
        return 'Consolidated Format';
    }
  }

  Future<void> _printInvoice() async {
    final feeEngine = ref.read(feeStructureEngineProvider);
    final configLoader = ref.read(institutionConfigLoaderProvider);

    try {
      // Show loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preparing invoice for printing...')),
      );

      // Generate the invoice data for printing
      final invoiceData = await feeEngine.generateFeeInvoice(
        institutionTypeId: widget.institutionTypeId,
        invoice: widget.invoice,
        feeStructures: widget.feeStructures,
        format: _selectedFormat,
      );

      final academicConfig = await configLoader.loadAcademicConfig(
        widget.institutionTypeId,
      );

      // Print based on current view mode
      if (_showAllCopies) {
        // Print all three copies
        final allCopies = await feeEngine.generateThreeCopies(
          institutionTypeId: widget.institutionTypeId,
          invoice: widget.invoice,
          feeStructures: widget.feeStructures,
          format: _selectedFormat,
        );

        await ThreeCopyInvoicePdfService.generateAndPrintThreeCopies(
          copies: allCopies,
          invoice: widget.invoice,
          institutionType: _getInstitutionTypeDisplayName(academicConfig.institutionTypeId),
          format: _selectedFormat,
        );
      } else {
        // Print single selected copy
        await ThreeCopyInvoicePdfService.generateAndPrintSingleCopy(
          invoiceData: invoiceData,
          invoice: widget.invoice,
          copyType: _selectedCopy,
          institutionType: _getInstitutionTypeDisplayName(academicConfig.institutionTypeId),
          format: _selectedFormat,
        );
      }

      // Show success message
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Invoice sent to printer')));
    } catch (e) {
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error printing invoice: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }
}
