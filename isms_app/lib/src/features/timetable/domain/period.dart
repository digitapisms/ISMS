import 'package:equatable/equatable.dart';

enum PeriodType { regular, breakPeriod, lunch, assembly }

extension PeriodTypeX on PeriodType {
  String get dbValue {
    switch (this) {
      case PeriodType.regular:
        return 'regular';
      case PeriodType.breakPeriod:
        return 'break';
      case PeriodType.lunch:
        return 'lunch';
      case PeriodType.assembly:
        return 'assembly';
    }
  }

  static PeriodType fromDb(String value) {
    switch (value) {
      case 'regular':
        return PeriodType.regular;
      case 'break':
        return PeriodType.breakPeriod;
      case 'lunch':
        return PeriodType.lunch;
      case 'assembly':
        return PeriodType.assembly;
      default:
        return PeriodType.regular;
    }
  }
}

class Period extends Equatable {
  const Period({
    required this.id,
    required this.schoolId,
    required this.name,
    required this.startTime,
    required this.endTime,
    this.periodType = PeriodType.regular,
    this.displayOrder = 0,
    this.isActive = true,
    this.durationMinutes,
    this.createdAt,
    this.updatedAt,
  });

  final int id;
  final String schoolId;
  final String name;
  final DateTime startTime; // Time only
  final DateTime endTime; // Time only
  final PeriodType periodType;
  final int displayOrder;
  final bool isActive;
  final int? durationMinutes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory Period.fromMap(Map<String, dynamic> map) {
    return Period(
      id: map['id'] as int,
      schoolId: map['school_id'] as String,
      name: map['name'] as String,
      startTime: DateTime.parse('2000-01-01 ${map['start_time']}'),
      endTime: DateTime.parse('2000-01-01 ${map['end_time']}'),
      periodType: PeriodTypeX.fromDb(
        map['period_type'] as String? ?? 'regular',
      ),
      displayOrder: (map['display_order'] as int?) ?? 0,
      isActive: (map['is_active'] as bool?) ?? true,
      durationMinutes: map['duration_minutes'] as int?,
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
      'name': name,
      'start_time': startTime.toIso8601String().split('T')[1].substring(0, 8),
      'end_time': endTime.toIso8601String().split('T')[1].substring(0, 8),
      'period_type': periodType.dbValue,
      'display_order': displayOrder,
      'is_active': isActive,
      'duration_minutes': durationMinutes,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  String get timeRange {
    final start =
        '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}';
    final end =
        '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}';
    return '$start - $end';
  }

  @override
  List<Object?> get props => [
    id,
    schoolId,
    name,
    startTime,
    endTime,
    periodType,
    displayOrder,
    isActive,
    durationMinutes,
    createdAt,
    updatedAt,
  ];
}
