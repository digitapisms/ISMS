import 'visitor_type.dart';

class VisitorLog {
  final String id;
  final String schoolId;
  final String visitId;
  final String visitorId;
  final ActionType actionType;
  final DateTime actionTime;
  final String? performedBy;
  final String? location;
  final String? notes;
  final Map<String, dynamic>? metadata;

  VisitorLog({
    required this.id,
    required this.schoolId,
    required this.visitId,
    required this.visitorId,
    required this.actionType,
    required this.actionTime,
    this.performedBy,
    this.location,
    this.notes,
    this.metadata,
  });

  factory VisitorLog.fromJson(Map<String, dynamic> json) {
    return VisitorLog(
      id: json['id'] as String,
      schoolId: json['school_id'] as String,
      visitId: json['visit_id'] as String,
      visitorId: json['visitor_id'] as String,
      actionType: ActionTypeX.fromDb(json['action_type'] as String),
      actionTime: DateTime.parse(json['action_time'] as String),
      performedBy: json['performed_by'] as String?,
      location: json['location'] as String?,
      notes: json['notes'] as String?,
      metadata: json['metadata'] != null
          ? json['metadata'] as Map<String, dynamic>
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'school_id': schoolId,
      'visit_id': visitId,
      'visitor_id': visitorId,
      'action_type': actionType.dbValue,
      'action_time': actionTime.toIso8601String(),
      'performed_by': performedBy,
      'location': location,
      'notes': notes,
      'metadata': metadata,
    };
  }
}

