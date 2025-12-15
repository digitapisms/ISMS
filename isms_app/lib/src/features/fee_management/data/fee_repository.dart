import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/network/supabase_client.dart';
import '../domain/fee_category.dart';
import '../domain/fee_frequency.dart';
import '../domain/fee_invoice.dart';
import '../domain/fee_invoice_item.dart';
import '../domain/fee_payment.dart';
import '../domain/fee_structure.dart';
import '../domain/fee_summary.dart';
import '../domain/invoice_status.dart';

class FeeRepository {
  SupabaseClient get _client => SupabaseManager.client;

  String? _schoolId;

  void setSchoolId(String? schoolId) {
    _schoolId = schoolId;
  }

  String? get schoolId => _schoolId;

  String _requireSchoolId() {
    final id = _schoolId;
    if (id == null) {
      throw Exception(
        'School context is required. Please ensure you are signed in to a school tenant.',
      );
    }
    return id;
  }

  Future<String?> _getCurrentUserId() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;

    final response = await _client
        .from('users')
        .select('id')
        .eq('auth_id', user.id)
        .maybeSingle();

    return response?['id'] as String?;
  }

  // ==================== Fee Categories ====================

  Future<List<FeeCategory>> fetchFeeCategories({
    String? schoolId,
    bool? isActive,
  }) async {
    final schoolIdValue = schoolId ?? _requireSchoolId();
    dynamic query = _client
        .from('fee_categories')
        .select()
        .eq('school_id', schoolIdValue)
        .order('display_order');

    if (isActive != null) {
      query = query.eq('is_active', isActive);
    }

    final response = await query;
    final List<dynamic> categories = response;
    return categories
        .map((c) => FeeCategory.fromMap(c as Map<String, dynamic>))
        .toList();
  }

  Future<FeeCategory> createFeeCategory({
    required String schoolId,
    required String name,
    String? code,
    String? description,
    int? displayOrder,
  }) async {
    final response = await _client
        .from('fee_categories')
        .insert({
          'school_id': schoolId,
          'name': name,
          'code': code,
          'description': description,
          'display_order': displayOrder ?? 0,
        })
        .select()
        .single();

    return FeeCategory.fromMap(response);
  }

  Future<FeeCategory> updateFeeCategory({
    required String id,
    String? name,
    String? code,
    String? description,
    bool? isActive,
    int? displayOrder,
  }) async {
    final updates = <String, dynamic>{};
    if (name != null) updates['name'] = name;
    if (code != null) updates['code'] = code;
    if (description != null) updates['description'] = description;
    if (isActive != null) updates['is_active'] = isActive;
    if (displayOrder != null) updates['display_order'] = displayOrder;

    final response = await _client
        .from('fee_categories')
        .update(updates)
        .eq('id', id)
        .select()
        .single();

    return FeeCategory.fromMap(response);
  }

  // ==================== Fee Structures ====================

  Future<List<FeeStructure>> fetchFeeStructures({
    String? schoolId,
    String? categoryId,
    int? classId,
    String? studentId,
    bool? isActive,
  }) async {
    final schoolIdValue = schoolId ?? _requireSchoolId();
    dynamic query = _client
        .from('fee_structures_new')
        .select()
        .eq('school_id', schoolIdValue);

    if (categoryId != null) {
      query = query.eq('category_id', categoryId);
    }
    if (classId != null) {
      query = query.eq('class_id', classId);
    }
    if (studentId != null) {
      query = query.eq('student_id', studentId);
    }
    if (isActive != null) {
      query = query.eq('is_active', isActive);
    }

    query = query.order('created_at', ascending: false);

    final response = await query;
    final List<dynamic> structures = response;
    return structures
        .map((s) => FeeStructure.fromMap(s as Map<String, dynamic>))
        .toList();
  }

  Future<FeeStructure> createFeeStructure({
    required String schoolId,
    required String categoryId,
    required String name,
    required double amount,
    String? description,
    String currency = 'PKR',
    FeeFrequency frequency = FeeFrequency.monthly,
    FeeApplicability applicableTo = FeeApplicability.all,
    int? classId,
    int? sectionId,
    String? studentId,
    DateTime? startDate,
    DateTime? endDate,
    double lateFeePercentage = 0,
    double lateFeeFixedAmount = 0,
    double discountPercentage = 0,
    double discountFixedAmount = 0,
  }) async {
    final userId = await _getCurrentUserId();
    final response = await _client
        .from('fee_structures_new')
        .insert({
          'school_id': schoolId,
          'category_id': categoryId,
          'name': name,
          'description': description,
          'amount': amount,
          'currency': currency,
          'frequency': frequency.dbValue,
          'applicable_to': applicableTo.dbValue,
          if (classId != null) 'class_id': classId,
          if (sectionId != null) 'section_id': sectionId,
          if (studentId != null) 'student_id': studentId,
          if (startDate != null)
            'start_date': startDate.toIso8601String().split('T')[0],
          if (endDate != null)
            'end_date': endDate.toIso8601String().split('T')[0],
          'late_fee_percentage': lateFeePercentage,
          'late_fee_fixed_amount': lateFeeFixedAmount,
          'discount_percentage': discountPercentage,
          'discount_fixed_amount': discountFixedAmount,
          'created_by': userId,
        })
        .select()
        .single();

    return FeeStructure.fromMap(response);
  }

  Future<FeeStructure> updateFeeStructure({
    required String id,
    String? name,
    String? description,
    double? amount,
    FeeFrequency? frequency,
    FeeApplicability? applicableTo,
    bool? isActive,
    double? lateFeePercentage,
    double? lateFeeFixedAmount,
    double? discountPercentage,
    double? discountFixedAmount,
  }) async {
    final updates = <String, dynamic>{};
    if (name != null) updates['name'] = name;
    if (description != null) updates['description'] = description;
    if (amount != null) updates['amount'] = amount;
    if (frequency != null) updates['frequency'] = frequency.dbValue;
    if (applicableTo != null) updates['applicable_to'] = applicableTo.dbValue;
    if (isActive != null) updates['is_active'] = isActive;
    if (lateFeePercentage != null) {
      updates['late_fee_percentage'] = lateFeePercentage;
    }
    if (lateFeeFixedAmount != null) {
      updates['late_fee_fixed_amount'] = lateFeeFixedAmount;
    }
    if (discountPercentage != null) {
      updates['discount_percentage'] = discountPercentage;
    }
    if (discountFixedAmount != null) {
      updates['discount_fixed_amount'] = discountFixedAmount;
    }

    final response = await _client
        .from('fee_structures_new')
        .update(updates)
        .eq('id', id)
        .select()
        .single();

    return FeeStructure.fromMap(response);
  }

  // ==================== Fee Invoices ====================

  Future<String> generateInvoiceNumber(String schoolId) async {
    final response = await _client.rpc(
      'generate_fee_invoice_number',
      params: {'p_school_id': schoolId},
    );
    return response as String;
  }

  Future<FeeInvoice> createFeeInvoice({
    required String schoolId,
    required String studentId,
    required DateTime dueDate,
    required List<FeeInvoiceItem> items,
    InvoiceType invoiceType = InvoiceType.fee,
    DateTime? issueDate,
    double discountAmount = 0,
    double lateFeeAmount = 0,
    String currency = 'PKR',
    String? notes,
  }) async {
    final userId = await _getCurrentUserId();
    final invoiceNumber = await generateInvoiceNumber(schoolId);

    // Calculate total amount
    final totalAmount =
        items.fold<double>(
          0,
          (sum, item) => sum + item.totalAmount - item.discountAmount,
        ) -
        discountAmount +
        lateFeeAmount;

    // Create invoice
    final invoiceResponse = await _client
        .from('fee_invoices')
        .insert({
          'school_id': schoolId,
          'student_id': studentId,
          'invoice_number': invoiceNumber,
          'invoice_type': invoiceType.dbValue,
          'issue_date':
              issueDate?.toIso8601String().split('T')[0] ??
              DateTime.now().toIso8601String().split('T')[0],
          'due_date': dueDate.toIso8601String().split('T')[0],
          'total_amount': totalAmount,
          'discount_amount': discountAmount,
          'late_fee_amount': lateFeeAmount,
          'currency': currency,
          'notes': notes,
          'created_by': userId,
        })
        .select()
        .single();

    final invoice = FeeInvoice.fromMap(invoiceResponse);

    // Create invoice items
    for (final item in items) {
      await _client.from('fee_invoice_items').insert({
        'invoice_id': invoice.id,
        'fee_structure_id': item.feeStructureId,
        'category_id': item.categoryId,
        'description': item.description,
        'quantity': item.quantity,
        'unit_amount': item.unitAmount,
        'total_amount': item.totalAmount,
        'discount_amount': item.discountAmount,
      });
    }

    return invoice;
  }

  Future<List<FeeInvoice>> fetchFeeInvoices({
    String? schoolId,
    String? studentId,
    InvoiceStatus? status,
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
  }) async {
    final schoolIdValue = schoolId ?? _requireSchoolId();
    dynamic query = _client
        .from('fee_invoices')
        .select()
        .eq('school_id', schoolIdValue)
        .order('created_at', ascending: false);

    if (studentId != null) {
      query = query.eq('student_id', studentId);
    }
    if (status != null) {
      query = query.eq('status', status.dbValue);
    }
    if (startDate != null) {
      query = query.gte('due_date', startDate.toIso8601String().split('T')[0]);
    }
    if (endDate != null) {
      query = query.lte('due_date', endDate.toIso8601String().split('T')[0]);
    }
    if (limit != null) {
      query = query.limit(limit);
    }

    final response = await query;
    final List<dynamic> invoices = response;
    return invoices
        .map((i) => FeeInvoice.fromMap(i as Map<String, dynamic>))
        .toList();
  }

  Future<FeeInvoice> getFeeInvoice(String invoiceId) async {
    final response = await _client
        .from('fee_invoices')
        .select()
        .eq('id', invoiceId)
        .single();

    return FeeInvoice.fromMap(response);
  }

  Future<List<FeeInvoiceItem>> fetchInvoiceItems(String invoiceId) async {
    final response = await _client
        .from('fee_invoice_items')
        .select()
        .eq('invoice_id', invoiceId)
        .order('created_at');

    final List<dynamic> items = response;
    return items
        .map((i) => FeeInvoiceItem.fromMap(i as Map<String, dynamic>))
        .toList();
  }

  // ==================== Fee Payments ====================

  Future<FeePayment> recordFeePayment({
    required String schoolId,
    required String invoiceId,
    required String studentId,
    required String paymentMethod,
    required double amount,
    required DateTime paymentDate,
    String? paymentTransactionId,
    String? cashReceiptId,
    String currency = 'PKR',
    String? paymentReference,
    String? notes,
  }) async {
    final userId = await _getCurrentUserId();
    final response = await _client
        .from('fee_payments')
        .insert({
          'school_id': schoolId,
          'invoice_id': invoiceId,
          'student_id': studentId,
          'payment_transaction_id': paymentTransactionId,
          'cash_receipt_id': cashReceiptId,
          'payment_method': paymentMethod,
          'amount': amount,
          'currency': currency,
          'payment_date': paymentDate.toIso8601String().split('T')[0],
          'payment_reference': paymentReference,
          'notes': notes,
          'received_by': userId,
        })
        .select()
        .single();

    return FeePayment.fromMap(response);
  }

  Future<List<FeePayment>> fetchFeePayments({
    String? schoolId,
    String? invoiceId,
    String? studentId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final schoolIdValue = schoolId ?? _requireSchoolId();
    dynamic query = _client
        .from('fee_payments')
        .select()
        .eq('school_id', schoolIdValue)
        .order('payment_date', ascending: false);

    if (invoiceId != null) {
      query = query.eq('invoice_id', invoiceId);
    }
    if (studentId != null) {
      query = query.eq('student_id', studentId);
    }
    if (startDate != null) {
      query = query.gte(
        'payment_date',
        startDate.toIso8601String().split('T')[0],
      );
    }
    if (endDate != null) {
      query = query.lte(
        'payment_date',
        endDate.toIso8601String().split('T')[0],
      );
    }

    final response = await query;
    final List<dynamic> payments = response;
    return payments
        .map((p) => FeePayment.fromMap(p as Map<String, dynamic>))
        .toList();
  }

  // ==================== Fee Summary ====================

  Future<FeeSummary> getStudentFeeSummary({
    required String studentId,
    String? schoolId,
  }) async {
    final schoolIdValue = schoolId ?? _requireSchoolId();
    final response = await _client.rpc(
      'get_student_fee_summary',
      params: {'p_student_id': studentId, 'p_school_id': schoolIdValue},
    );

    final result = response as List;
    if (result.isEmpty) {
      return const FeeSummary(
        totalInvoices: 0,
        pendingInvoices: 0,
        paidInvoices: 0,
        overdueInvoices: 0,
        totalDueAmount: 0,
        totalPaidAmount: 0,
        totalOutstanding: 0,
      );
    }

    return FeeSummary.fromMap(result.first as Map<String, dynamic>);
  }
}
