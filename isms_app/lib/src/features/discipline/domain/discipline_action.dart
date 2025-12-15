class DisciplineAction {
  final String id;
  final String schoolId;
  final String incidentId;
  final String studentId;
  final ActionType actionType;
  final DateTime actionDate;
  final String description;
  final int? durationDays;
  final DateTime? startDate;
  final DateTime? endDate;
  final String assignedBy;
  final ActionStatus status;
  final bool followUpRequired;
  final DateTime? followUpDate;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  DisciplineAction({
    required this.id,
    required this.schoolId,
    required this.incidentId,
    required this.studentId,
    required this.actionType,
    required this.actionDate,
    required this.description,
    this.durationDays,
    this.startDate,
    this.endDate,
    required this.assignedBy,
    this.status = ActionStatus.active,
    this.followUpRequired = false,
    this.followUpDate,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory DisciplineAction.fromJson(Map<String, dynamic> json) {
    return DisciplineAction(
      id: json['id'] as String,
      schoolId: json['school_id'] as String,
      incidentId: json['incident_id'] as String,
      studentId: json['student_id'] as String,
      actionType: ActionTypeX.fromDb(json['action_type'] as String),
      actionDate: DateTime.parse(json['action_date'] as String),
      description: json['description'] as String,
      durationDays: json['duration_days'] as int?,
      startDate: json['start_date'] != null
          ? DateTime.parse(json['start_date'] as String)
          : null,
      endDate: json['end_date'] != null
          ? DateTime.parse(json['end_date'] as String)
          : null,
      assignedBy: json['assigned_by'] as String,
      status: ActionStatusX.fromDb(json['status'] as String),
      followUpRequired: json['follow_up_required'] as bool? ?? false,
      followUpDate: json['follow_up_date'] != null
          ? DateTime.parse(json['follow_up_date'] as String)
          : null,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'school_id': schoolId,
      'incident_id': incidentId,
      'student_id': studentId,
      'action_type': actionType.dbValue,
      'action_date': actionDate.toIso8601String(),
      'description': description,
      'duration_days': durationDays,
      'start_date': startDate?.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'assigned_by': assignedBy,
      'status': status.dbValue,
      'follow_up_required': followUpRequired,
      'follow_up_date': followUpDate?.toIso8601String(),
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

enum ActionType {
  warning,
  detention,
  suspension,
  expulsion,
  counseling,
  communityService,
  parentConference,
  other,
}

extension ActionTypeX on ActionType {
  String get dbValue {
    switch (this) {
      case ActionType.warning:
        return 'warning';
      case ActionType.detention:
        return 'detention';
      case ActionType.suspension:
        return 'suspension';
      case ActionType.expulsion:
        return 'expulsion';
      case ActionType.counseling:
        return 'counseling';
      case ActionType.communityService:
        return 'community_service';
      case ActionType.parentConference:
        return 'parent_conference';
      case ActionType.other:
        return 'other';
    }
  }

  String get displayName {
    switch (this) {
      case ActionType.warning:
        return 'Warning';
      case ActionType.detention:
        return 'Detention';
      case ActionType.suspension:
        return 'Suspension';
      case ActionType.expulsion:
        return 'Expulsion';
      case ActionType.counseling:
        return 'Counseling';
      case ActionType.communityService:
        return 'Community Service';
      case ActionType.parentConference:
        return 'Parent Conference';
      case ActionType.other:
        return 'Other';
    }
  }

  static ActionType fromDb(String value) {
    switch (value) {
      case 'warning':
        return ActionType.warning;
      case 'detention':
        return ActionType.detention;
      case 'suspension':
        return ActionType.suspension;
      case 'expulsion':
        return ActionType.expulsion;
      case 'counseling':
        return ActionType.counseling;
      case 'community_service':
        return ActionType.communityService;
      case 'parent_conference':
        return ActionType.parentConference;
      case 'other':
        return ActionType.other;
      default:
        return ActionType.warning;
    }
  }
}

enum ActionStatus {
  active,
  completed,
  cancelled,
}

extension ActionStatusX on ActionStatus {
  String get dbValue {
    switch (this) {
      case ActionStatus.active:
        return 'active';
      case ActionStatus.completed:
        return 'completed';
      case ActionStatus.cancelled:
        return 'cancelled';
    }
  }

  String get displayName {
    switch (this) {
      case ActionStatus.active:
        return 'Active';
      case ActionStatus.completed:
        return 'Completed';
      case ActionStatus.cancelled:
        return 'Cancelled';
    }
  }

  static ActionStatus fromDb(String value) {
    switch (value) {
      case 'active':
        return ActionStatus.active;
      case 'completed':
        return ActionStatus.completed;
      case 'cancelled':
        return ActionStatus.cancelled;
      default:
        return ActionStatus.active;
    }
  }
}

