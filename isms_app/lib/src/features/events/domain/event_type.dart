import 'package:flutter/material.dart';

enum EventType {
  academic,
  sports,
  cultural,
  celebration,
  meeting,
  workshop,
  fieldTrip,
  competition,
  other,
}

extension EventTypeX on EventType {
  String get dbValue {
    switch (this) {
      case EventType.academic:
        return 'academic';
      case EventType.sports:
        return 'sports';
      case EventType.cultural:
        return 'cultural';
      case EventType.celebration:
        return 'celebration';
      case EventType.meeting:
        return 'meeting';
      case EventType.workshop:
        return 'workshop';
      case EventType.fieldTrip:
        return 'field_trip';
      case EventType.competition:
        return 'competition';
      case EventType.other:
        return 'other';
    }
  }

  String get displayName {
    switch (this) {
      case EventType.academic:
        return 'Academic';
      case EventType.sports:
        return 'Sports';
      case EventType.cultural:
        return 'Cultural';
      case EventType.celebration:
        return 'Celebration';
      case EventType.meeting:
        return 'Meeting';
      case EventType.workshop:
        return 'Workshop';
      case EventType.fieldTrip:
        return 'Field Trip';
      case EventType.competition:
        return 'Competition';
      case EventType.other:
        return 'Other';
    }
  }

  IconData get icon {
    switch (this) {
      case EventType.academic:
        return Icons.school;
      case EventType.sports:
        return Icons.sports_soccer;
      case EventType.cultural:
        return Icons.theater_comedy;
      case EventType.celebration:
        return Icons.celebration;
      case EventType.meeting:
        return Icons.meeting_room;
      case EventType.workshop:
        return Icons.workspace_premium;
      case EventType.fieldTrip:
        return Icons.explore;
      case EventType.competition:
        return Icons.emoji_events;
      case EventType.other:
        return Icons.event;
    }
  }

  Color get color {
    switch (this) {
      case EventType.academic:
        return Colors.blue;
      case EventType.sports:
        return Colors.green;
      case EventType.cultural:
        return Colors.purple;
      case EventType.celebration:
        return Colors.orange;
      case EventType.meeting:
        return Colors.grey;
      case EventType.workshop:
        return Colors.teal;
      case EventType.fieldTrip:
        return Colors.brown;
      case EventType.competition:
        return Colors.amber;
      case EventType.other:
        return Colors.indigo;
    }
  }

  static EventType fromDb(String value) {
    switch (value) {
      case 'academic':
        return EventType.academic;
      case 'sports':
        return EventType.sports;
      case 'cultural':
        return EventType.cultural;
      case 'celebration':
        return EventType.celebration;
      case 'meeting':
        return EventType.meeting;
      case 'workshop':
        return EventType.workshop;
      case 'field_trip':
        return EventType.fieldTrip;
      case 'competition':
        return EventType.competition;
      case 'other':
        return EventType.other;
      default:
        return EventType.other;
    }
  }
}

enum EventStatus {
  draft,
  published,
  ongoing,
  completed,
  cancelled,
}

extension EventStatusX on EventStatus {
  String get dbValue {
    switch (this) {
      case EventStatus.draft:
        return 'draft';
      case EventStatus.published:
        return 'published';
      case EventStatus.ongoing:
        return 'ongoing';
      case EventStatus.completed:
        return 'completed';
      case EventStatus.cancelled:
        return 'cancelled';
    }
  }

  String get displayName {
    switch (this) {
      case EventStatus.draft:
        return 'Draft';
      case EventStatus.published:
        return 'Published';
      case EventStatus.ongoing:
        return 'Ongoing';
      case EventStatus.completed:
        return 'Completed';
      case EventStatus.cancelled:
        return 'Cancelled';
    }
  }

  Color get color {
    switch (this) {
      case EventStatus.draft:
        return Colors.grey;
      case EventStatus.published:
        return Colors.blue;
      case EventStatus.ongoing:
        return Colors.green;
      case EventStatus.completed:
        return Colors.teal;
      case EventStatus.cancelled:
        return Colors.red;
    }
  }

  static EventStatus fromDb(String value) {
    switch (value) {
      case 'draft':
        return EventStatus.draft;
      case 'published':
        return EventStatus.published;
      case 'ongoing':
        return EventStatus.ongoing;
      case 'completed':
        return EventStatus.completed;
      case 'cancelled':
        return EventStatus.cancelled;
      default:
        return EventStatus.draft;
    }
  }
}

