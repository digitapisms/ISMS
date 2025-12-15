import 'package:equatable/equatable.dart';

class LearningSession extends Equatable {
  const LearningSession({
    required this.id,
    required this.schoolId,
    required this.userId,
    this.sessionType = 'resource_study',
    this.startTime,
    this.endTime,
    this.totalDurationSeconds = 0,
    this.resourcesAccessed = 0,
    this.totalProgressMade = 0.0,
    this.avgEngagementScore = 0.0,
    this.deviceType,
    this.ipAddress,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String schoolId;
  final String userId;
  final String sessionType;
  final DateTime? startTime;
  final DateTime? endTime;
  final int totalDurationSeconds;
  final int resourcesAccessed;
  final double totalProgressMade;
  final double avgEngagementScore;
  final String? deviceType;
  final String? ipAddress;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory LearningSession.fromMap(Map<String, dynamic> map) {
    return LearningSession(
      id: map['id'] as String,
      schoolId: map['school_id'] as String,
      userId: map['user_id'] as String,
      sessionType: (map['session_type'] as String?) ?? 'resource_study',
      startTime: map['start_time'] != null
          ? DateTime.parse(map['start_time'] as String)
          : null,
      endTime: map['end_time'] != null
          ? DateTime.parse(map['end_time'] as String)
          : null,
      totalDurationSeconds: (map['total_duration_seconds'] as int?) ?? 0,
      resourcesAccessed: (map['resources_accessed'] as int?) ?? 0,
      totalProgressMade: (map['total_progress_made'] as num?)?.toDouble() ?? 0.0,
      avgEngagementScore: (map['avg_engagement_score'] as num?)?.toDouble() ?? 0.0,
      deviceType: map['device_type'] as String?,
      ipAddress: map['ip_address'] as String?,
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
      'user_id': userId,
      'session_type': sessionType,
      'start_time': startTime?.toIso8601String(),
      'end_time': endTime?.toIso8601String(),
      'total_duration_seconds': totalDurationSeconds,
      'resources_accessed': resourcesAccessed,
      'total_progress_made': totalProgressMade,
      'avg_engagement_score': avgEngagementScore,
      'device_type': deviceType,
      'ip_address': ipAddress,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  String get durationFormatted {
    final hours = totalDurationSeconds ~/ 3600;
    final minutes = (totalDurationSeconds % 3600) ~/ 60;
    final seconds = totalDurationSeconds % 60;
    
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }

  bool get isActive => endTime == null;

  double get progressPercentage => totalProgressMade * 100;

  @override
  List<Object?> get props => [
        id,
        schoolId,
        userId,
        sessionType,
        startTime,
        endTime,
        totalDurationSeconds,
        resourcesAccessed,
        totalProgressMade,
        avgEngagementScore,
        deviceType,
        ipAddress,
        createdAt,
        updatedAt,
      ];
}