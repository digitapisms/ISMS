enum ConversationType {
  direct,
  group,
  classChat,
  broadcast,
}

extension ConversationTypeX on ConversationType {
  String get dbValue {
    switch (this) {
      case ConversationType.direct:
        return 'direct';
      case ConversationType.group:
        return 'group';
      case ConversationType.classChat:
        return 'class';
      case ConversationType.broadcast:
        return 'broadcast';
    }
  }

  String get displayName {
    switch (this) {
      case ConversationType.direct:
        return 'Direct';
      case ConversationType.group:
        return 'Group';
      case ConversationType.classChat:
        return 'Class';
      case ConversationType.broadcast:
        return 'Broadcast';
    }
  }

  static ConversationType fromDb(String value) {
    switch (value) {
      case 'direct':
        return ConversationType.direct;
      case 'group':
        return ConversationType.group;
      case 'class':
        return ConversationType.classChat;
      case 'broadcast':
        return ConversationType.broadcast;
      default:
        return ConversationType.direct;
    }
  }
}

enum MessageType {
  text,
  image,
  file,
  voice,
  video,
  location,
}

extension MessageTypeX on MessageType {
  String get dbValue {
    switch (this) {
      case MessageType.text:
        return 'text';
      case MessageType.image:
        return 'image';
      case MessageType.file:
        return 'file';
      case MessageType.voice:
        return 'voice';
      case MessageType.video:
        return 'video';
      case MessageType.location:
        return 'location';
    }
  }

  String get displayName {
    switch (this) {
      case MessageType.text:
        return 'Text';
      case MessageType.image:
        return 'Image';
      case MessageType.file:
        return 'File';
      case MessageType.voice:
        return 'Voice';
      case MessageType.video:
        return 'Video';
      case MessageType.location:
        return 'Location';
    }
  }

  static MessageType fromDb(String value) {
    switch (value) {
      case 'text':
        return MessageType.text;
      case 'image':
        return MessageType.image;
      case 'file':
        return MessageType.file;
      case 'voice':
        return MessageType.voice;
      case 'video':
        return MessageType.video;
      case 'location':
        return MessageType.location;
      default:
        return MessageType.text;
    }
  }
}

enum ParticipantRole {
  participant,
  admin,
  moderator,
}

extension ParticipantRoleX on ParticipantRole {
  String get dbValue {
    switch (this) {
      case ParticipantRole.participant:
        return 'participant';
      case ParticipantRole.admin:
        return 'admin';
      case ParticipantRole.moderator:
        return 'moderator';
    }
  }

  static ParticipantRole fromDb(String value) {
    switch (value) {
      case 'participant':
        return ParticipantRole.participant;
      case 'admin':
        return ParticipantRole.admin;
      case 'moderator':
        return ParticipantRole.moderator;
      default:
        return ParticipantRole.participant;
    }
  }
}

enum AnnouncementType {
  general,
  urgent,
  event,
  academic,
}

extension AnnouncementTypeX on AnnouncementType {
  String get dbValue {
    switch (this) {
      case AnnouncementType.general:
        return 'general';
      case AnnouncementType.urgent:
        return 'urgent';
      case AnnouncementType.event:
        return 'event';
      case AnnouncementType.academic:
        return 'academic';
    }
  }

  String get displayName {
    switch (this) {
      case AnnouncementType.general:
        return 'General';
      case AnnouncementType.urgent:
        return 'Urgent';
      case AnnouncementType.event:
        return 'Event';
      case AnnouncementType.academic:
        return 'Academic';
    }
  }

  static AnnouncementType fromDb(String value) {
    switch (value) {
      case 'general':
        return AnnouncementType.general;
      case 'urgent':
        return AnnouncementType.urgent;
      case 'event':
        return AnnouncementType.event;
      case 'academic':
        return AnnouncementType.academic;
      default:
        return AnnouncementType.general;
    }
  }
}

enum Priority {
  low,
  normal,
  high,
  urgent,
}

extension PriorityX on Priority {
  String get dbValue {
    switch (this) {
      case Priority.low:
        return 'low';
      case Priority.normal:
        return 'normal';
      case Priority.high:
        return 'high';
      case Priority.urgent:
        return 'urgent';
    }
  }

  String get displayName {
    switch (this) {
      case Priority.low:
        return 'Low';
      case Priority.normal:
        return 'Normal';
      case Priority.high:
        return 'High';
      case Priority.urgent:
        return 'Urgent';
    }
  }

  static Priority fromDb(String value) {
    switch (value) {
      case 'low':
        return Priority.low;
      case 'normal':
        return Priority.normal;
      case 'high':
        return Priority.high;
      case 'urgent':
        return Priority.urgent;
      default:
        return Priority.normal;
    }
  }
}

enum TargetAudience {
  all,
  students,
  parents,
  staff,
  teachers,
}

extension TargetAudienceX on TargetAudience {
  String get dbValue {
    switch (this) {
      case TargetAudience.all:
        return 'all';
      case TargetAudience.students:
        return 'students';
      case TargetAudience.parents:
        return 'parents';
      case TargetAudience.staff:
        return 'staff';
      case TargetAudience.teachers:
        return 'teachers';
    }
  }

  String get displayName {
    switch (this) {
      case TargetAudience.all:
        return 'All';
      case TargetAudience.students:
        return 'Students';
      case TargetAudience.parents:
        return 'Parents';
      case TargetAudience.staff:
        return 'Staff';
      case TargetAudience.teachers:
        return 'Teachers';
    }
  }

  static TargetAudience fromDb(String value) {
    switch (value) {
      case 'all':
        return TargetAudience.all;
      case 'students':
        return TargetAudience.students;
      case 'parents':
        return TargetAudience.parents;
      case 'staff':
        return TargetAudience.staff;
      case 'teachers':
        return TargetAudience.teachers;
      default:
        return TargetAudience.all;
    }
  }
}

enum CircularType {
  general,
  academic,
  administrative,
  event,
}

extension CircularTypeX on CircularType {
  String get dbValue {
    switch (this) {
      case CircularType.general:
        return 'general';
      case CircularType.academic:
        return 'academic';
      case CircularType.administrative:
        return 'administrative';
      case CircularType.event:
        return 'event';
    }
  }

  String get displayName {
    switch (this) {
      case CircularType.general:
        return 'General';
      case CircularType.academic:
        return 'Academic';
      case CircularType.administrative:
        return 'Administrative';
      case CircularType.event:
        return 'Event';
    }
  }

  static CircularType fromDb(String value) {
    switch (value) {
      case 'general':
        return CircularType.general;
      case 'academic':
        return CircularType.academic;
      case 'administrative':
        return CircularType.administrative;
      case 'event':
        return CircularType.event;
      default:
        return CircularType.general;
    }
  }
}

enum TemplateCategory {
  attendance,
  fee,
  assignment,
  general,
  transport,
  examination,
}

extension TemplateCategoryX on TemplateCategory {
  String get dbValue {
    switch (this) {
      case TemplateCategory.attendance:
        return 'attendance';
      case TemplateCategory.fee:
        return 'fee';
      case TemplateCategory.assignment:
        return 'assignment';
      case TemplateCategory.general:
        return 'general';
      case TemplateCategory.transport:
        return 'transport';
      case TemplateCategory.examination:
        return 'examination';
    }
  }

  String get displayName {
    switch (this) {
      case TemplateCategory.attendance:
        return 'Attendance';
      case TemplateCategory.fee:
        return 'Fee';
      case TemplateCategory.assignment:
        return 'Assignment';
      case TemplateCategory.general:
        return 'General';
      case TemplateCategory.transport:
        return 'Transport';
      case TemplateCategory.examination:
        return 'Examination';
    }
  }

  static TemplateCategory fromDb(String value) {
    switch (value) {
      case 'attendance':
        return TemplateCategory.attendance;
      case 'fee':
        return TemplateCategory.fee;
      case 'assignment':
        return TemplateCategory.assignment;
      case 'general':
        return TemplateCategory.general;
      case 'transport':
        return TemplateCategory.transport;
      case 'examination':
        return TemplateCategory.examination;
      default:
        return TemplateCategory.general;
    }
  }
}

