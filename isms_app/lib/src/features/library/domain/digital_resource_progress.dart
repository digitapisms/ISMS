import 'package:equatable/equatable.dart';

class DigitalResourceProgress extends Equatable {
  const DigitalResourceProgress({
    required this.id,
    required this.schoolId,
    required this.resourceId,
    required this.userId,
    this.currentPage = 1,
    this.totalPages,
    this.percentageCompleted = 0.0,
    this.timeSpentSeconds = 0,
    this.lastPosition,
    this.lastAccessedAt,
    this.completedAt,
    this.bookmarkedPages = const [],
    this.notesCount = 0,
    this.highlightsCount = 0,
    this.quizScore,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String schoolId;
  final String resourceId;
  final String userId;
  final int currentPage;
  final int? totalPages;
  final double percentageCompleted;
  final int timeSpentSeconds;
  final String? lastPosition;
  final DateTime? lastAccessedAt;
  final DateTime? completedAt;
  final List<int> bookmarkedPages;
  final int notesCount;
  final int highlightsCount;
  final double? quizScore;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory DigitalResourceProgress.fromMap(Map<String, dynamic> map) {
    return DigitalResourceProgress(
      id: map['id'] as String,
      schoolId: map['school_id'] as String,
      resourceId: map['resource_id'] as String,
      userId: map['user_id'] as String,
      currentPage: (map['current_page'] as int?) ?? 1,
      totalPages: map['total_pages'] as int?,
      percentageCompleted: (map['percentage_completed'] as num?)?.toDouble() ?? 0.0,
      timeSpentSeconds: (map['time_spent_seconds'] as int?) ?? 0,
      lastPosition: map['last_position'] as String?,
      lastAccessedAt: map['last_accessed_at'] != null
          ? DateTime.parse(map['last_accessed_at'] as String)
          : null,
      completedAt: map['completed_at'] != null
          ? DateTime.parse(map['completed_at'] as String)
          : null,
      bookmarkedPages: (map['bookmarked_pages'] as List<dynamic>?)?.cast<int>() ?? const [],
      notesCount: (map['notes_count'] as int?) ?? 0,
      highlightsCount: (map['highlights_count'] as int?) ?? 0,
      quizScore: (map['quiz_score'] as num?)?.toDouble(),
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
      'current_page': currentPage,
      'total_pages': totalPages,
      'percentage_completed': percentageCompleted,
      'time_spent_seconds': timeSpentSeconds,
      'last_position': lastPosition,
      'last_accessed_at': lastAccessedAt?.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'bookmarked_pages': bookmarkedPages,
      'notes_count': notesCount,
      'highlights_count': highlightsCount,
      'quiz_score': quizScore,
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

  bool get isCompleted => percentageCompleted >= 95.0;

  @override
  List<Object?> get props => [
        id,
        schoolId,
        resourceId,
        userId,
        currentPage,
        totalPages,
        percentageCompleted,
        timeSpentSeconds,
        lastPosition,
        lastAccessedAt,
        completedAt,
        bookmarkedPages,
        notesCount,
        highlightsCount,
        quizScore,
        createdAt,
        updatedAt,
      ];
}