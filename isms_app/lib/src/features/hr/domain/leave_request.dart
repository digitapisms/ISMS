import 'package:equatable/equatable.dart';

class LeaveRequest extends Equatable {
  const LeaveRequest({
    required this.id,
    required this.schoolId,
    required this.staffId,
    required this.leaveType,
    required this.startDate,
    required this.endDate,
    required this.totalDays,
    required this.reason,
    this.status = 'pending',
    this.approvedBy,
    this.approvedAt,
    this.rejectionReason,
    this.emergencyContactDuringLeave,
    this.handoverNotes,
    this.supportingDocuments = const [],
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String schoolId;
  final String staffId;
  final String leaveType;
  final DateTime startDate;
  final DateTime endDate;
  final int totalDays;
  final String reason;
  final String status;
  final String? approvedBy;
  final DateTime? approvedAt;
  final String? rejectionReason;
  final String? emergencyContactDuringLeave;
  final String? handoverNotes;
  final List<Map<String, dynamic>> supportingDocuments;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory LeaveRequest.fromMap(Map<String, dynamic> map) {
    return LeaveRequest(
      id: map['id'] as String,
      schoolId: map['school_id'] as String,
      staffId: map['staff_id'] as String,
      leaveType: map['leave_type'] as String,
      startDate: DateTime.parse(map['start_date'] as String),
      endDate: DateTime.parse(map['end_date'] as String),
      totalDays: map['total_days'] as int,
      reason: map['reason'] as String,
      status: map['status'] as String? ?? 'pending',
      approvedBy: map['approved_by'] as String?,
      approvedAt: map['approved_at'] != null
          ? DateTime.parse(map['approved_at'] as String)
          : null,
      rejectionReason: map['rejection_reason'] as String?,
      emergencyContactDuringLeave: map['emergency_contact_during_leave'] as String?,
      handoverNotes: map['handover_notes'] as String?,
      supportingDocuments: (map['supporting_documents'] as List?)?.cast<Map<String, dynamic>>() ?? [],
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'school_id': schoolId,
      'staff_id': staffId,
      'leave_type': leaveType,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'total_days': totalDays,
      'reason': reason,
      'status': status,
      'approved_by': approvedBy,
      'approved_at': approvedAt?.toIso8601String(),
      'rejection_reason': rejectionReason,
      'emergency_contact_during_leave': emergencyContactDuringLeave,
      'handover_notes': handoverNotes,
      'supporting_documents': supportingDocuments,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  LeaveRequest copyWith({
    String? id,
    String? schoolId,
    String? staffId,
    String? leaveType,
    DateTime? startDate,
    DateTime? endDate,
    int? totalDays,
    String? reason,
    String? status,
    String? approvedBy,
    DateTime? approvedAt,
    String? rejectionReason,
    String? emergencyContactDuringLeave,
    String? handoverNotes,
    List<Map<String, dynamic>>? supportingDocuments,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return LeaveRequest(
      id: id ?? this.id,
      schoolId: schoolId ?? this.schoolId,
      staffId: staffId ?? this.staffId,
      leaveType: leaveType ?? this.leaveType,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      totalDays: totalDays ?? this.totalDays,
      reason: reason ?? this.reason,
      status: status ?? this.status,
      approvedBy: approvedBy ?? this.approvedBy,
      approvedAt: approvedAt ?? this.approvedAt,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      emergencyContactDuringLeave: emergencyContactDuringLeave ?? this.emergencyContactDuringLeave,
      handoverNotes: handoverNotes ?? this.handoverNotes,
      supportingDocuments: supportingDocuments ?? this.supportingDocuments,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        schoolId,
        staffId,
        leaveType,
        startDate,
        endDate,
        totalDays,
        reason,
        status,
        approvedBy,
        approvedAt,
        rejectionReason,
        emergencyContactDuringLeave,
        handoverNotes,
        supportingDocuments,
        createdAt,
        updatedAt,
      ];
}