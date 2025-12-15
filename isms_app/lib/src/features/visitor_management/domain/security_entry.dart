import 'visitor_type.dart';

class SecurityEntry {
  final String id;
  final String schoolId;
  final String? visitId;
  final String? visitorId;
  final EntryType entryType;
  final DateTime entryTime;
  final DateTime? exitTime;
  final String gateName;
  final String direction; // entry or exit
  final String? personName;
  final String? personId;
  final String? vehicleNumber;
  final String? vehicleType;
  final String? purpose;
  final String? securityOfficerId;
  final bool isAuthorized;
  final String? authorizationNotes;
  final AlertLevel alertLevel;
  final String? alertReason;
  final DateTime createdAt;

  SecurityEntry({
    required this.id,
    required this.schoolId,
    this.visitId,
    this.visitorId,
    required this.entryType,
    required this.entryTime,
    this.exitTime,
    required this.gateName,
    required this.direction,
    this.personName,
    this.personId,
    this.vehicleNumber,
    this.vehicleType,
    this.purpose,
    this.securityOfficerId,
    this.isAuthorized = true,
    this.authorizationNotes,
    this.alertLevel = AlertLevel.normal,
    this.alertReason,
    required this.createdAt,
  });

  factory SecurityEntry.fromJson(Map<String, dynamic> json) {
    return SecurityEntry(
      id: json['id'] as String,
      schoolId: json['school_id'] as String,
      visitId: json['visit_id'] as String?,
      visitorId: json['visitor_id'] as String?,
      entryType: EntryTypeX.fromDb(json['entry_type'] as String),
      entryTime: DateTime.parse(json['entry_time'] as String),
      exitTime: json['exit_time'] != null
          ? DateTime.parse(json['exit_time'] as String)
          : null,
      gateName: json['gate_name'] as String,
      direction: json['direction'] as String,
      personName: json['person_name'] as String?,
      personId: json['person_id'] as String?,
      vehicleNumber: json['vehicle_number'] as String?,
      vehicleType: json['vehicle_type'] as String?,
      purpose: json['purpose'] as String?,
      securityOfficerId: json['security_officer_id'] as String?,
      isAuthorized: json['is_authorized'] as bool? ?? true,
      authorizationNotes: json['authorization_notes'] as String?,
      alertLevel: AlertLevelX.fromDb(json['security_alert_level'] as String? ?? 'normal'),
      alertReason: json['alert_reason'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'school_id': schoolId,
      'visit_id': visitId,
      'visitor_id': visitorId,
      'entry_type': entryType.dbValue,
      'entry_time': entryTime.toIso8601String(),
      'exit_time': exitTime?.toIso8601String(),
      'gate_name': gateName,
      'direction': direction,
      'person_name': personName,
      'person_id': personId,
      'vehicle_number': vehicleNumber,
      'vehicle_type': vehicleType,
      'purpose': purpose,
      'security_officer_id': securityOfficerId,
      'is_authorized': isAuthorized,
      'authorization_notes': authorizationNotes,
      'security_alert_level': alertLevel.dbValue,
      'alert_reason': alertReason,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

