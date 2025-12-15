enum NoteType {
  general,
  academic,
  behavior,
  attendance,
  other,
}

extension NoteTypeX on NoteType {
  String get dbValue {
    switch (this) {
      case NoteType.general:
        return 'general';
      case NoteType.academic:
        return 'academic';
      case NoteType.behavior:
        return 'behavior';
      case NoteType.attendance:
        return 'attendance';
      case NoteType.other:
        return 'other';
    }
  }

  String get displayName {
    switch (this) {
      case NoteType.general:
        return 'General';
      case NoteType.academic:
        return 'Academic';
      case NoteType.behavior:
        return 'Behavior';
      case NoteType.attendance:
        return 'Attendance';
      case NoteType.other:
        return 'Other';
    }
  }

  static NoteType fromDb(String value) {
    switch (value) {
      case 'general':
        return NoteType.general;
      case 'academic':
        return NoteType.academic;
      case 'behavior':
        return NoteType.behavior;
      case 'attendance':
        return NoteType.attendance;
      case 'other':
        return NoteType.other;
      default:
        return NoteType.general;
    }
  }
}

class PTMNote {
  final String id;
  final String meetingId;
  final NoteType noteType;
  final String content;
  final List<String> actionItems;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  PTMNote({
    required this.id,
    required this.meetingId,
    this.noteType = NoteType.general,
    required this.content,
    this.actionItems = const [],
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PTMNote.fromJson(Map<String, dynamic> json) {
    return PTMNote(
      id: json['id'] as String,
      meetingId: json['meeting_id'] as String,
      noteType: NoteTypeX.fromDb(json['note_type'] as String),
      content: json['content'] as String,
      actionItems: (json['action_items'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      createdBy: json['created_by'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'meeting_id': meetingId,
      'note_type': noteType.dbValue,
      'content': content,
      'action_items': actionItems,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

