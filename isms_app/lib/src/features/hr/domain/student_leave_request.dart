import 'package:equatable/equatable.dart';

class StudentLeaveRequest extends Equatable {
  const StudentLeaveRequest({
    required this.id,
    required this.schoolId,
    required this.studentId,
    required this.leaveType,
    required this.startDate,
    required this.endDate,
    required this.totalDays,
    required this.reason,
    this.requestedBy,
    this.requestedByRole,
    this.requestedAt,
    this.status = 'pending',
    this.approvedBy,
    this.approvedAt,
    this.rejectionReason,
    this.emergencyContactDuringLeave,
    this.supportingDocuments = const [],
    this.classId,
    this.sectionId,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String schoolId;
  final String studentId;
  final String leaveType;
  final DateTime startDate;
  final DateTime endDate;
  final int totalDays;
  final String reason;
  final String? requestedBy;
  final String? requestedByRole;
  final DateTime? requestedAt;
  final String status;
  final String? approvedBy;
  final DateTime? approvedAt;
  final String? rejectionReason;
  final String? emergencyContactDuringLeave;
  final List<Map<String, dynamic>> supportingDocuments;
  final int? classId;
  final int? sectionId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory StudentLeaveRequest.fromMap(Map<String, dynamic> map) {
    return StudentLeaveRequest(
      id: map['id'] as String,
      schoolId: map['school_id'] as String,
      studentId: map['student_id'] as String,
      leaveType: map['leave_type'] as String,
      startDate: DateTime.parse(map['start_date'] as String),
      endDate: DateTime.parse(map['end_date'] as String),
      totalDays: map['total_days'] as int,
      reason: map['reason'] as String,
      requestedBy: map['requested_by'] as String?,
      requestedByRole: map['requested_by_role'] as String?,
      requestedAt: map['requested_at'] != null
          ? DateTime.parse(map['requested_at'] as String)
          : null,
      status: map['status'] as String? ?? 'pending',
      approvedBy: map['approved_by'] as String?,
      approvedAt: map['approved_at'] != null
          ? DateTime.parse(map['approved_at'] as String)
          : null,
      rejectionReason: map['rejection_reason'] as String?,
      emergencyContactDuringLeave: map['emergency_contact_during_leave'] as String?,
      supportingDocuments: (map['supporting_documents'] as List?)?.cast<Map<String, dynamic>>() ?? [],
      classId: map['class_id'] as int?,
      sectionId: map['section_id'] as int?,
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
      'student_id': studentId,
      'leave_type': leaveType,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'total_days': totalDays,
      'reason': reason,
      'requested_by': requestedBy,
      'requested_by_role': requestedByRole,
      'requested_at': requestedAt?.toIso8601String(),
      'status': status,
      'approved_by': approvedBy,
      'approved_at': approvedAt?.toIso8601String(),
      'rejection_reason': rejectionReason,
      'emergency_contact_during_leave': emergencyContactDuringLeave,
      'supporting_documents': supportingDocuments,
      'class_id': classId,
      'section_id': sectionId,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  StudentLeaveRequest copyWith({
    String? id,
    String? schoolId,
    String? studentId,
    String? leaveType,
    DateTime? startDate,
    DateTime? endDate,
    int? totalDays,
    String? reason,
    String? requestedBy,
    String? requestedByRole,
    DateTime? requestedAt,
    String? status,
    String? approvedBy,
    DateTime? approvedAt,
    String? rejectionReason,
    String? emergencyContactDuringLeave,
    List<Map<String, dynamic>>? supportingDocuments,
    int? classId,
    int? sectionId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return StudentLeaveRequest(
      id: id ?? this.id,
      schoolId: schoolId ?? this.schoolId,
      studentId: studentId ?? this.studentId,
      leaveType: leaveType ?? this.leaveType,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      totalDays: totalDays ?? this.totalDays,
      reason: reason ?? this.reason,
      requestedBy: requestedBy ?? this.requestedBy,
      requestedByRole: requestedByRole ?? this.requestedByRole,
      requestedAt: requestedAt ?? this.requestedAt,
      status: status ?? this.status,
      approvedBy: approvedBy ?? this.approvedBy,
      approvedAt: approvedAt ?? this.approvedAt,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      emergencyContactDuringLeave: emergencyContactDuringLeave ?? this.emergencyContactDuringLeave,
      supportingDocuments: supportingDocuments ?? this.supportingDocuments,
      classId: classId ?? this.classId,
      sectionId: sectionId ?? this.sectionId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        schoolId,
        studentId,
        leaveType,
        startDate,
        endDate,
        totalDays,
        reason,
        requestedBy,
        requestedByRole,
        requestedAt,
        status,
        approvedBy,
        approvedAt,
        rejectionReason,
        emergencyContactDuringLeave,
        supportingDocuments,
        classId,
        sectionId,
        createdAt,
        updatedAt,
      ];
}