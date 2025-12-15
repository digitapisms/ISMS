import 'visitor_type.dart';

class Visit {
  final String id;
  final String schoolId;
  final String visitorId;
  final VisitPurpose visitPurpose;
  final String? purposeDescription;
  final HostType hostType;
  final String? hostId;
  final String? hostName;
  final String? department;
  final DateTime? expectedArrivalTime;
  final DateTime? checkInTime;
  final DateTime? checkOutTime;
  final VisitStatus visitStatus;
  final String? badgeNumber;
  final String? entryGate;
  final String? exitGate;
  final String? vehicleNumber;
  final int numberOfVisitors;
  final String? securityNotes;
  final String? receptionNotes;
  final bool isEscortRequired;
  final String? escortUserId;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  Visit({
    required this.id,
    required this.schoolId,
    required this.visitorId,
    required this.visitPurpose,
    this.purposeDescription,
    required this.hostType,
    this.hostId,
    this.hostName,
    this.department,
    this.expectedArrivalTime,
    this.checkInTime,
    this.checkOutTime,
    this.visitStatus = VisitStatus.scheduled,
    this.badgeNumber,
    this.entryGate,
    this.exitGate,
    this.vehicleNumber,
    this.numberOfVisitors = 1,
    this.securityNotes,
    this.receptionNotes,
    this.isEscortRequired = false,
    this.escortUserId,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Visit.fromJson(Map<String, dynamic> json) {
    return Visit(
      id: json['id'] as String,
      schoolId: json['school_id'] as String,
      visitorId: json['visitor_id'] as String,
      visitPurpose: VisitPurposeX.fromDb(json['visit_purpose'] as String),
      purposeDescription: json['purpose_description'] as String?,
      hostType: HostTypeX.fromDb(json['host_type'] as String),
      hostId: json['host_id'] as String?,
      hostName: json['host_name'] as String?,
      department: json['department'] as String?,
      expectedArrivalTime: json['expected_arrival_time'] != null
          ? DateTime.parse(json['expected_arrival_time'] as String)
          : null,
      checkInTime: json['check_in_time'] != null
          ? DateTime.parse(json['check_in_time'] as String)
          : null,
      checkOutTime: json['check_out_time'] != null
          ? DateTime.parse(json['check_out_time'] as String)
          : null,
      visitStatus: VisitStatusX.fromDb(json['visit_status'] as String? ?? 'scheduled'),
      badgeNumber: json['badge_number'] as String?,
      entryGate: json['entry_gate'] as String?,
      exitGate: json['exit_gate'] as String?,
      vehicleNumber: json['vehicle_number'] as String?,
      numberOfVisitors: json['number_of_visitors'] as int? ?? 1,
      securityNotes: json['security_notes'] as String?,
      receptionNotes: json['reception_notes'] as String?,
      isEscortRequired: json['is_escort_required'] as bool? ?? false,
      escortUserId: json['escort_user_id'] as String?,
      createdBy: json['created_by'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'school_id': schoolId,
      'visitor_id': visitorId,
      'visit_purpose': visitPurpose.dbValue,
      'purpose_description': purposeDescription,
      'host_type': hostType.dbValue,
      'host_id': hostId,
      'host_name': hostName,
      'department': department,
      'expected_arrival_time': expectedArrivalTime?.toIso8601String(),
      'check_in_time': checkInTime?.toIso8601String(),
      'check_out_time': checkOutTime?.toIso8601String(),
      'visit_status': visitStatus.dbValue,
      'badge_number': badgeNumber,
      'entry_gate': entryGate,
      'exit_gate': exitGate,
      'vehicle_number': vehicleNumber,
      'number_of_visitors': numberOfVisitors,
      'security_notes': securityNotes,
      'reception_notes': receptionNotes,
      'is_escort_required': isEscortRequired,
      'escort_user_id': escortUserId,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

