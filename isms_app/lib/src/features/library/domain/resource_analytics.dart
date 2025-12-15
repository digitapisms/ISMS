import 'package:equatable/equatable.dart';

class ResourceAnalytics extends Equatable {
  const ResourceAnalytics({
    required this.id,
    required this.schoolId,
    required this.resourceId,
    required this.date,
    this.totalViews = 0,
    this.uniqueUsers = 0,
    this.totalTimeSpentSeconds = 0,
    this.avgTimeSpentSeconds = 0.0,
    this.completionCount = 0,
    this.completionRate = 0.0,
    this.avgEngagementScore = 0.0,
    this.popularSections = const [],
    this.difficultyRating = 0.0,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String schoolId;
  final String resourceId;
  final DateTime date;
  final int totalViews;
  final int uniqueUsers;
  final int totalTimeSpentSeconds;
  final double avgTimeSpentSeconds;
  final int completionCount;
  final double completionRate;
  final double avgEngagementScore;
  final List<String> popularSections;
  final double difficultyRating;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory ResourceAnalytics.fromMap(Map<String, dynamic> map) {
    return ResourceAnalytics(
      id: map['id'] as String,
      schoolId: map['school_id'] as String,
      resourceId: map['resource_id'] as String,
      date: DateTime.parse(map['date'] as String),
      totalViews: (map['total_views'] as int?) ?? 0,
      uniqueUsers: (map['unique_users'] as int?) ?? 0,
      totalTimeSpentSeconds: (map['total_time_spent_seconds'] as int?) ?? 0,
      avgTimeSpentSeconds: (map['avg_time_spent_seconds'] as num?)?.toDouble() ?? 0.0,
      completionCount: (map['completion_count'] as int?) ?? 0,
      completionRate: (map['completion_rate'] as num?)?.toDouble() ?? 0.0,
      avgEngagementScore: (map['avg_engagement_score'] as num?)?.toDouble() ?? 0.0,
      popularSections: (map['popular_sections'] as List<dynamic>?)?.cast<String>() ?? const [],
      difficultyRating: (map['difficulty_rating'] as num?)?.toDouble() ?? 0.0,
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
      'date': date.toIso8601String(),
      'total_views': totalViews,
      'unique_users': uniqueUsers,
      'total_time_spent_seconds': totalTimeSpentSeconds,
      'avg_time_spent_seconds': avgTimeSpentSeconds,
      'completion_count': completionCount,
      'completion_rate': completionRate,
      'avg_engagement_score': avgEngagementScore,
      'popular_sections': popularSections,
      'difficulty_rating': difficultyRating,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  String get avgTimeSpentFormatted {
    final hours = avgTimeSpentSeconds ~/ 3600;
    final minutes = (avgTimeSpentSeconds % 3600) ~/ 60;
    final seconds = avgTimeSpentSeconds % 60;
    
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }

  String get totalTimeSpentFormatted {
    final hours = totalTimeSpentSeconds ~/ 3600;
    final minutes = (totalTimeSpentSeconds % 3600) ~/ 60;
    
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else if (minutes > 0) {
      return '${minutes}m';
    } else {
      return 'Less than 1m';
    }
  }

  double get completionRatePercentage => completionRate * 100;

  double get engagementScorePercentage => avgEngagementScore * 100;

  @override
  List<Object?> get props => [
        id,
        schoolId,
        resourceId,
        date,
        totalViews,
        uniqueUsers,
        totalTimeSpentSeconds,
        avgTimeSpentSeconds,
        completionCount,
        completionRate,
        avgEngagementScore,
        popularSections,
        difficultyRating,
        createdAt,
        updatedAt,
      ];
}