enum ClubStatus { active, inactive, archived }

enum ClubMemberRole { member, mentor, assistant }

enum ClubMemberStatus { pending, approved, rejected, left }

class Club {
  final String id;
  final String schoolId;
  final String? categoryId;
  final String name;
  final String? description;
  final String? mentorId;
  final String? meetingSchedule;
  final int? capacity;
  final List<String> tags;
  final ClubStatus status;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;
  final DateTime updatedAt;

  Club({
    required this.id,
    required this.schoolId,
    this.categoryId,
    required this.name,
    this.description,
    this.mentorId,
    this.meetingSchedule,
    this.capacity,
    required this.tags,
    required this.status,
    required this.metadata,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Club.fromMap(Map<String, dynamic> map) {
    final tagsData = map['tags'];
    List<String> tags = [];
    if (tagsData is List) {
      tags = tagsData.map((e) => e.toString()).toList();
    }

    return Club(
      id: map['id'] as String,
      schoolId: map['school_id'] as String,
      categoryId: map['category_id'] as String?,
      name: map['name'] as String,
      description: map['description'] as String?,
      mentorId: map['mentor_id'] as String?,
      meetingSchedule: map['meeting_schedule'] as String?,
      capacity: map['capacity'] as int?,
      tags: tags,
      status: ClubStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => ClubStatus.active,
      ),
      metadata: (map['metadata'] as Map<String, dynamic>?) ?? {},
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'school_id': schoolId,
      'category_id': categoryId,
      'name': name,
      'description': description,
      'mentor_id': mentorId,
      'meeting_schedule': meetingSchedule,
      'capacity': capacity,
      'tags': tags,
      'status': status.name,
      'metadata': metadata,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

class ClubMember {
  final String id;
  final String clubId;
  final String userId;
  final ClubMemberRole role;
  final ClubMemberStatus status;
  final DateTime? joinedAt;
  final DateTime? leftAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  ClubMember({
    required this.id,
    required this.clubId,
    required this.userId,
    required this.role,
    required this.status,
    this.joinedAt,
    this.leftAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ClubMember.fromMap(Map<String, dynamic> map) {
    return ClubMember(
      id: map['id'] as String,
      clubId: map['club_id'] as String,
      userId: map['user_id'] as String,
      role: ClubMemberRole.values.firstWhere(
        (e) => e.name == map['role'],
        orElse: () => ClubMemberRole.member,
      ),
      status: ClubMemberStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => ClubMemberStatus.pending,
      ),
      joinedAt: map['joined_at'] != null
          ? DateTime.parse(map['joined_at'] as String)
          : null,
      leftAt: map['left_at'] != null
          ? DateTime.parse(map['left_at'] as String)
          : null,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'club_id': clubId,
      'user_id': userId,
      'role': role.name,
      'status': status.name,
      'joined_at': joinedAt?.toIso8601String(),
      'left_at': leftAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

enum ClubEventStatus { scheduled, completed, cancelled }

class ClubEvent {
  final String id;
  final String clubId;
  final String title;
  final String? description;
  final DateTime startTime;
  final DateTime? endTime;
  final String? location;
  final int? maxParticipants;
  final ClubEventStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  ClubEvent({
    required this.id,
    required this.clubId,
    required this.title,
    this.description,
    required this.startTime,
    this.endTime,
    this.location,
    this.maxParticipants,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ClubEvent.fromMap(Map<String, dynamic> map) {
    return ClubEvent(
      id: map['id'] as String,
      clubId: map['club_id'] as String,
      title: map['title'] as String,
      description: map['description'] as String?,
      startTime: DateTime.parse(map['start_time'] as String),
      endTime: map['end_time'] != null
          ? DateTime.parse(map['end_time'] as String)
          : null,
      location: map['location'] as String?,
      maxParticipants: map['max_participants'] as int?,
      status: ClubEventStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => ClubEventStatus.scheduled,
      ),
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'club_id': clubId,
      'title': title,
      'description': description,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime?.toIso8601String(),
      'location': location,
      'max_participants': maxParticipants,
      'status': status.name,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
