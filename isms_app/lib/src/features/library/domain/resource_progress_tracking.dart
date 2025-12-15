import 'package:equatable/equatable.dart';

class ResourceProgressTracking extends Equatable {
  const ResourceProgressTracking({
    required this.id,
    required this.schoolId,
    required this.resourceId,
    required this.userId,
    required this.sessionId,
    this.progressType = 'view',
    this.progressValue = 0.0,
    this.timeSpentSeconds = 0,
    this.pageNumber,
    this.totalPages,
    this.startTime,
    this.endTime,
    this.isCompleted = false,
    this.completionPercentage = 0.0,
    this.engagementScore = 0.0,
    this.deviceInfo,
    this.ipAddress,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String schoolId;
  final String resourceId;
  final String userId;
  final String sessionId;
  final String progressType;
  final double progressValue;
  final int timeSpentSeconds;
  final int? pageNumber;
  final int? totalPages;
  final DateTime? startTime;
  final DateTime? endTime;
  final bool isCompleted;
  final double completionPercentage;
  final double engagementScore;
  final String? deviceInfo;
  final String? ipAddress;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory ResourceProgressTracking.fromMap(Map<String, dynamic> map) {
    return ResourceProgressTracking(
      id: map['id'] as String,
      schoolId: map['school_id'] as String,
      resourceId: map['resource_id'] as String,
      userId: map['user_id'] as String,
      sessionId: map['session_id'] as String,
      progressType: (map['progress_type'] as String?) ?? 'view',
      progressValue: (map['progress_value'] as num?)?.toDouble() ?? 0.0,
      timeSpentSeconds: (map['time_spent_seconds'] as int?) ?? 0,
      pageNumber: map['page_number'] as int?,
      totalPages: map['total_pages'] as int?,
      startTime: map['start_time'] != null
          ? DateTime.parse(map['start_time'] as String)
          : null,
      endTime: map['end_time'] != null
          ? DateTime.parse(map['end_time'] as String)
          : null,
      isCompleted: (map['is_completed'] as bool?) ?? false,
      completionPercentage: (map['completion_percentage'] as num?)?.toDouble() ?? 0.0,
      engagementScore: (map['engagement_score'] as num?)?.toDouble() ?? 0.0,
      deviceInfo: map['device_info'] as String?,
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
      'resource_id': resourceId,
      'user_id': userId,
      'session_id': sessionId,
      'progress_type': progressType,
      'progress_value': progressValue,
      'time_spent_seconds': timeSpentSeconds,
      'page_number': pageNumber,
      'total_pages': totalPages,
      'start_time': startTime?.toIso8601String(),
      'end_time': endTime?.toIso8601String(),
      'is_completed': isCompleted,
      'completion_percentage': completionPercentage,
      'engagement_score': engagementScore,
      'device_info': deviceInfo,
      'ip_address': ipAddress,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  String get timeSpentFormatted {
    final hours = timeSpentSeconds ~/ 3600;
    final minutes = (timeSpentSeconds % 3600) ~/ 60;
    final seconds = timeSpentSeconds % 60;
    
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }

  bool get hasEnded => endTime != null;

  @override
  List<Object?> get props => [
        id,
        schoolId,
        resourceId,
        userId,
        sessionId,
        progressType,
        progressValue,
        timeSpentSeconds,
        pageNumber,
        totalPages,
        startTime,
        endTime,
        isCompleted,
        completionPercentage,
        engagementScore,
        deviceInfo,
        ipAddress,
        createdAt,
        updatedAt,
      ];
}