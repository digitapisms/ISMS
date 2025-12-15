class DisciplineIncident {
  final String id;
  final String schoolId;
  final String studentId;
  final DateTime incidentDate;
  final IncidentType incidentType;
  final String? category;
  final String description;
  final String? location;
  final String? reportedBy;
  final List<String> witnesses;
  final List<String> evidenceUrls;
  final IncidentStatus status;
  final SeverityLevel severityLevel;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  DisciplineIncident({
    required this.id,
    required this.schoolId,
    required this.studentId,
    required this.incidentDate,
    required this.incidentType,
    this.category,
    required this.description,
    this.location,
    this.reportedBy,
    this.witnesses = const [],
    this.evidenceUrls = const [],
    this.status = IncidentStatus.reported,
    this.severityLevel = SeverityLevel.low,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory DisciplineIncident.fromJson(Map<String, dynamic> json) {
    return DisciplineIncident(
      id: json['id'] as String,
      schoolId: json['school_id'] as String,
      studentId: json['student_id'] as String,
      incidentDate: DateTime.parse(json['incident_date'] as String),
      incidentType: IncidentTypeX.fromDb(json['incident_type'] as String),
      category: json['category'] as String?,
      description: json['description'] as String,
      location: json['location'] as String?,
      reportedBy: json['reported_by'] as String?,
      witnesses: (json['witnesses'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      evidenceUrls: (json['evidence_urls'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      status: IncidentStatusX.fromDb(json['status'] as String),
      severityLevel: SeverityLevelX.fromDb(json['severity_level'] as String),
      createdBy: json['created_by'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'school_id': schoolId,
      'student_id': studentId,
      'incident_date': incidentDate.toIso8601String(),
      'incident_type': incidentType.dbValue,
      'category': category,
      'description': description,
      'location': location,
      'reported_by': reportedBy,
      'witnesses': witnesses,
      'evidence_urls': evidenceUrls,
      'status': status.dbValue,
      'severity_level': severityLevel.dbValue,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

enum IncidentType {
  minor,
  major,
  serious,
  critical,
}

extension IncidentTypeX on IncidentType {
  String get dbValue {
    switch (this) {
      case IncidentType.minor:
        return 'minor';
      case IncidentType.major:
        return 'major';
      case IncidentType.serious:
        return 'serious';
      case IncidentType.critical:
        return 'critical';
    }
  }

  String get displayName {
    switch (this) {
      case IncidentType.minor:
        return 'Minor';
      case IncidentType.major:
        return 'Major';
      case IncidentType.serious:
        return 'Serious';
      case IncidentType.critical:
        return 'Critical';
    }
  }

  static IncidentType fromDb(String value) {
    switch (value) {
      case 'minor':
        return IncidentType.minor;
      case 'major':
        return IncidentType.major;
      case 'serious':
        return IncidentType.serious;
      case 'critical':
        return IncidentType.critical;
      default:
        return IncidentType.minor;
    }
  }
}

enum IncidentStatus {
  reported,
  investigating,
  resolved,
  closed,
}

extension IncidentStatusX on IncidentStatus {
  String get dbValue {
    switch (this) {
      case IncidentStatus.reported:
        return 'reported';
      case IncidentStatus.investigating:
        return 'investigating';
      case IncidentStatus.resolved:
        return 'resolved';
      case IncidentStatus.closed:
        return 'closed';
    }
  }

  String get displayName {
    switch (this) {
      case IncidentStatus.reported:
        return 'Reported';
      case IncidentStatus.investigating:
        return 'Investigating';
      case IncidentStatus.resolved:
        return 'Resolved';
      case IncidentStatus.closed:
        return 'Closed';
    }
  }

  static IncidentStatus fromDb(String value) {
    switch (value) {
      case 'reported':
        return IncidentStatus.reported;
      case 'investigating':
        return IncidentStatus.investigating;
      case 'resolved':
        return IncidentStatus.resolved;
      case 'closed':
        return IncidentStatus.closed;
      default:
        return IncidentStatus.reported;
    }
  }
}

enum SeverityLevel {
  low,
  medium,
  high,
  critical,
}

extension SeverityLevelX on SeverityLevel {
  String get dbValue {
    switch (this) {
      case SeverityLevel.low:
        return 'low';
      case SeverityLevel.medium:
        return 'medium';
      case SeverityLevel.high:
        return 'high';
      case SeverityLevel.critical:
        return 'critical';
    }
  }

  String get displayName {
    switch (this) {
      case SeverityLevel.low:
        return 'Low';
      case SeverityLevel.medium:
        return 'Medium';
      case SeverityLevel.high:
        return 'High';
      case SeverityLevel.critical:
        return 'Critical';
    }
  }

  static SeverityLevel fromDb(String value) {
    switch (value) {
      case 'low':
        return SeverityLevel.low;
      case 'medium':
        return SeverityLevel.medium;
      case 'high':
        return SeverityLevel.high;
      case 'critical':
        return SeverityLevel.critical;
      default:
        return SeverityLevel.low;
    }
  }
}

