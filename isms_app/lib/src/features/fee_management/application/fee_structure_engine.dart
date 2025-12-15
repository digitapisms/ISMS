import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../institution/application/institution_config_loader.dart';
import '../../institution/domain/academic_structure.dart';
import '../domain/fee_invoice.dart';
import '../domain/fee_structure.dart';

part 'fee_structure_engine.g.dart';

/// Enum for different fee structure formats
enum FeeStructureFormat {
  standard,      // Traditional school format with detailed breakdown
  simplified,    // Simplified format for coaching/tuition centers
  consolidated,  // Consolidated format for madrasas with zakat/charity
}

/// Enum for different copy types
enum FeeCopyType {
  studentCopy,   // Copy for student/parent
  schoolCopy,    // Copy for school records
  bankCopy,      // Copy for bank processing
}

/// Service for managing institution-specific fee structures and formats
class FeeStructureEngine {
  final InstitutionConfigLoader _configLoader;

  FeeStructureEngine(this._configLoader);

  /// Get supported fee structure formats for a specific institution type
  Future<List<FeeStructureFormat>> getSupportedFormats(String institutionTypeId) async {
    final academicConfig = await _configLoader.loadAcademicConfig(institutionTypeId);
    
    switch (academicConfig.institutionType) {
      case InstitutionType.school:
        return [FeeStructureFormat.standard, FeeStructureFormat.simplified];
      case InstitutionType.madrasa:
        return [FeeStructureFormat.consolidated, FeeStructureFormat.standard];
      case InstitutionType.coachingCenter:
      case InstitutionType.tuitionCenter:
        return [FeeStructureFormat.simplified, FeeStructureFormat.standard];
    }
  }

  /// Generate fee invoice with institution-specific formatting
  Future<Map<String, dynamic>> generateFeeInvoice({
    required String institutionTypeId,
    required FeeInvoice invoice,
    required List<FeeStructure> feeStructures,
    required FeeStructureFormat format,
  }) async {
    final academicConfig = await _configLoader.loadAcademicConfig(institutionTypeId);
    
    return _formatInvoice(invoice, feeStructures, format, academicConfig);
  }

  /// Generate three copies of fee invoice (student, school, bank)
  Future<Map<FeeCopyType, Map<String, dynamic>>> generateThreeCopies({
    required String institutionTypeId,
    required FeeInvoice invoice,
    required List<FeeStructure> feeStructures,
    required FeeStructureFormat format,
  }) async {
    final academicConfig = await _configLoader.loadAcademicConfig(institutionTypeId);
    
    return {
      FeeCopyType.studentCopy: _formatStudentCopy(invoice, feeStructures, format, academicConfig),
      FeeCopyType.schoolCopy: _formatSchoolCopy(invoice, feeStructures, format, academicConfig),
      FeeCopyType.bankCopy: _formatBankCopy(invoice, feeStructures, format, academicConfig),
    };
  }

  /// Get default fee structure format for institution type
  Future<FeeStructureFormat> getDefaultFormat(String institutionTypeId) async {
    final academicConfig = await _configLoader.loadAcademicConfig(institutionTypeId);
    
    switch (academicConfig.institutionType) {
      case InstitutionType.school:
        return FeeStructureFormat.standard;
      case InstitutionType.madrasa:
        return FeeStructureFormat.consolidated;
      case InstitutionType.coachingCenter:
      case InstitutionType.tuitionCenter:
        return FeeStructureFormat.simplified;
    }
  }

  /// Validate fee structure against institution constraints
  Future<List<String>> validateFeeStructure({
    required String institutionTypeId,
    required FeeStructure structure,
  }) async {
    final errors = <String>[];
    final academicConfig = await _configLoader.loadAcademicConfig(institutionTypeId);
    
    // Institution-specific validation rules
    switch (academicConfig.institutionType) {
      case InstitutionType.madrasa:
        // Madrasas typically have lower fee amounts
        if (structure.amount > 5000) {
          errors.add('Fee amount seems high for madrasa. Typical range: 500-3000 PKR');
        }
        break;
      case InstitutionType.coachingCenter:
        // Coaching centers may have higher fees
        if (structure.amount < 1000) {
          errors.add('Fee amount seems low for coaching center. Typical range: 1000-10000 PKR');
        }
        break;
      case InstitutionType.tuitionCenter:
        // Tuition centers moderate fees
        if (structure.amount < 500 || structure.amount > 5000) {
          errors.add('Fee amount outside typical range for tuition center (500-5000 PKR)');
        }
        break;
      case InstitutionType.school:
        // Schools have wide range, no specific validation
        break;
    }
    
    return errors;
  }

  // Private formatting methods
  Map<String, dynamic> _formatInvoice(
    FeeInvoice invoice,
    List<FeeStructure> structures,
    FeeStructureFormat format,
    InstitutionAcademicConfig config,
  ) {
    switch (format) {
      case FeeStructureFormat.standard:
        return _formatStandardInvoice(invoice, structures, config);
      case FeeStructureFormat.simplified:
        return _formatSimplifiedInvoice(invoice, structures, config);
      case FeeStructureFormat.consolidated:
        return _formatConsolidatedInvoice(invoice, structures, config);
    }
  }

  Map<String, dynamic> _formatStandardInvoice(
    FeeInvoice invoice,
    List<FeeStructure> structures,
    InstitutionAcademicConfig config,
  ) {
    return {
      'format': 'standard',
      'institutionType': config.institutionType.name,
      'invoiceNumber': invoice.invoiceNumber,
      'issueDate': invoice.issueDate?.toIso8601String(),
      'dueDate': invoice.dueDate.toIso8601String(),
      'studentDetails': _getStudentDetails(),
      'feeBreakdown': structures.map((s) => {
        'category': s.name,
        'amount': s.amount,
        'description': s.description,
      }).toList(),
      'totalAmount': invoice.totalAmount,
      'paidAmount': invoice.paidAmount,
      'outstandingAmount': invoice.outstandingAmount,
      'paymentInstructions': _getPaymentInstructions(config),
      'footerNote': 'Generated by ${config.institutionType.displayName} Management System',
    };
  }

  Map<String, dynamic> _formatSimplifiedInvoice(
    FeeInvoice invoice,
    List<FeeStructure> structures,
    InstitutionAcademicConfig config,
  ) {
    return {
      'format': 'simplified',
      'institutionType': config.institutionType.name,
      'invoiceNumber': invoice.invoiceNumber,
      'dueDate': invoice.dueDate.toIso8601String(),
      'totalAmount': invoice.totalAmount,
      'paidAmount': invoice.paidAmount,
      'outstandingAmount': invoice.outstandingAmount,
      'paymentInstructions': _getSimplifiedInstructions(config),
      'footerNote': 'Thank you for your payment',
    };
  }

  Map<String, dynamic> _formatConsolidatedInvoice(
    FeeInvoice invoice,
    List<FeeStructure> structures,
    InstitutionAcademicConfig config,
  ) {
    final totalZakat = structures
        .where((s) => s.name.toLowerCase().contains('zakat') || s.name.toLowerCase().contains('charity'))
        .fold(0.0, (sum, s) => sum + s.amount);
    
    final totalTuition = structures
        .where((s) => !s.name.toLowerCase().contains('zakat') && !s.name.toLowerCase().contains('charity'))
        .fold(0.0, (sum, s) => sum + s.amount);
    
    return {
      'format': 'consolidated',
      'institutionType': config.institutionType.name,
      'invoiceNumber': invoice.invoiceNumber,
      'dueDate': invoice.dueDate.toIso8601String(),
      'tuitionAmount': totalTuition,
      'zakatAmount': totalZakat,
      'totalAmount': invoice.totalAmount,
      'paidAmount': invoice.paidAmount,
      'outstandingAmount': invoice.outstandingAmount,
      'paymentInstructions': _getMadrasaInstructions(),
      'footerNote': 'جزاك الله خيرا - May Allah reward you with goodness',
    };
  }

  Map<String, dynamic> _formatStudentCopy(
    FeeInvoice invoice,
    List<FeeStructure> structures,
    FeeStructureFormat format,
    InstitutionAcademicConfig config,
  ) {
    final base = _formatInvoice(invoice, structures, format, config);
    return {
      ...base,
      'copyType': 'student',
      'watermark': 'STUDENT COPY',
      'notes': 'Please keep this copy for your records',
    };
  }

  Map<String, dynamic> _formatSchoolCopy(
    FeeInvoice invoice,
    List<FeeStructure> structures,
    FeeStructureFormat format,
    InstitutionAcademicConfig config,
  ) {
    final base = _formatInvoice(invoice, structures, format, config);
    return {
      ...base,
      'copyType': 'school',
      'watermark': 'SCHOOL COPY',
      'internalNotes': 'For accounting and record keeping',
      'auditTrail': _getAuditTrail(),
    };
  }

  Map<String, dynamic> _formatBankCopy(
    FeeInvoice invoice,
    List<FeeStructure> structures,
    FeeStructureFormat format,
    InstitutionAcademicConfig config,
  ) {
    final base = _formatInvoice(invoice, structures, format, config);
    return {
      ...base,
      'copyType': 'bank',
      'watermark': 'BANK COPY',
      'bankDetails': _getBankDetails(),
      'processingInstructions': 'Process through fee collection system',
    };
  }

  // Helper methods for formatting
  Map<String, dynamic> _getStudentDetails() {
    return {
      'name': '[Student Name]',
      'class': '[Class]',
      'section': '[Section]',
      'rollNumber': '[Roll Number]',
    };
  }

  String _getPaymentInstructions(InstitutionAcademicConfig config) {
    switch (config.institutionType) {
      case InstitutionType.school:
        return 'Please pay by due date to avoid late fees. Payment can be made at school office or through bank transfer.';
      case InstitutionType.madrasa:
        return 'Payment can be made at madrasa office. Zakat payments are welcome and will be used for needy students.';
      case InstitutionType.coachingCenter:
        return 'Payments accepted at reception. Monthly installments available upon request.';
      case InstitutionType.tuitionCenter:
        return 'Fee payment due by 5th of each month. Late payments may result in service suspension.';
    }
  }

  String _getSimplifiedInstructions(InstitutionAcademicConfig config) {
    return 'Total Amount: \${invoice.totalAmount.toStringAsFixed(2)}. Due: ${invoice.dueDate.toLocal().toString().split(' ')[0]}';
  }

  String _getMadrasaInstructions() {
    return 'Tuition: \${totalTuition.toStringAsFixed(2)} | Zakat: \${totalZakat.toStringAsFixed(2)}. May Allah accept your donations.';
  }

  Map<String, dynamic> _getAuditTrail() {
    return {
      'generatedBy': '[System User]',
      'generatedAt': DateTime.now().toIso8601String(),
      'version': '1.0',
    };
  }

  Map<String, dynamic> _getBankDetails() {
    return {
      'accountName': '[School Bank Account]',
      'accountNumber': '[XXXX-XXXX-XXXX-XXXX]',
      'bankName': '[Bank Name]',
      'branchCode': '[Branch Code]',
      'routingNumber': '[Routing Number]',
    };
  }
}

/// Riverpod provider for the fee structure engine
@riverpod
FeeStructureEngine feeStructureEngine(FeeStructureEngineRef ref) {
  final configLoader = ref.watch(institutionConfigLoaderProvider);
  return FeeStructureEngine(configLoader);
}