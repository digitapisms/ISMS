import 'package:equatable/equatable.dart';

class UserLearningAnalytics extends Equatable {
  const UserLearningAnalytics({
    required this.id,
    required this.schoolId,
    required this.userId,
    required this.date,
    this.totalLearningTimeSeconds = 0,
    this.resourcesAccessed = 0,
    this.resourcesCompleted = 0,
    this.avgCompletionRate = 0.0,
    this.totalProgressMade = 0.0,
    this.engagementScore = 0.0,
    this.learningPattern,
    this.preferredResourceTypes = const [],
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String schoolId;
  final String userId;
  final DateTime date;
  final int totalLearningTimeSeconds;
  final int resourcesAccessed;
  final int resourcesCompleted;
  final double avgCompletionRate;
  final double totalProgressMade;
  final double engagementScore;
  final String? learningPattern;
  final List<String> preferredResourceTypes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory UserLearningAnalytics.fromMap(Map<String, dynamic> map) {
    return UserLearningAnalytics(
      id: map['id'] as String,
      schoolId: map['school_id'] as String,
      userId: map['user_id'] as String,
      date: DateTime.parse(map['date'] as String),
      totalLearningTimeSeconds: (map['total_learning_time_seconds'] as int?) ?? 0,
      resourcesAccessed: (map['resources_accessed'] as int?) ?? 0,
      resourcesCompleted: (map['resources_completed'] as int?) ?? 0,
      avgCompletionRate: (map['avg_completion_rate'] as num?)?.toDouble() ?? 0.0,
      totalProgressMade: (map['total_progress_made'] as num?)?.toDouble() ?? 0.0,
      engagementScore: (map['engagement_score'] as num?)?.toDouble() ?? 0.0,
      learningPattern: map['learning_pattern'] as String?,
      preferredResourceTypes: (map['preferred_resource_types'] as List<dynamic>?)?.cast<String>() ?? const [],
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
      'date': date.toIso8601String(),
      'total_learning_time_seconds': totalLearningTimeSeconds,
      'resources_accessed': resourcesAccessed,
      'resources_completed': resourcesCompleted,
      'avg_completion_rate': avgCompletionRate,
      'total_progress_made': totalProgressMade,
      'engagement_score': engagementScore,
      'learning_pattern': learningPattern,
      'preferred_resource_types': preferredResourceTypes,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  String get learningTimeFormatted {
    final hours = totalLearningTimeSeconds ~/ 3600;
    final minutes = (totalLearningTimeSeconds % 3600) ~/ 60;
    
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else if (minutes > 0) {
      return '${minutes}m';
    } else {
      return 'Less than 1m';
    }
  }

  double get completionRatePercentage => avgCompletionRate * 100;

  double get completionRate {
    if (resourcesAccessed == 0) return 0.0;
    return resourcesCompleted / resourcesAccessed;
  }

  @override
  List<Object?> get props => [
        id,
        schoolId,
        userId,
        date,
        totalLearningTimeSeconds,
        resourcesAccessed,
        resourcesCompleted,
        avgCompletionRate,
        totalProgressMade,
        engagementScore,
        learningPattern,
        preferredResourceTypes,
        createdAt,
        updatedAt,
      ];
}