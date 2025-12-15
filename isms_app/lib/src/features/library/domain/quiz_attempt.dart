import 'package:equatable/equatable.dart';

enum QuizAttemptStatus {
  inProgress,
  completed,
  submitted,
  graded,
}

extension QuizAttemptStatusExtension on QuizAttemptStatus {
  String get dbValue {
    switch (this) {
      case QuizAttemptStatus.inProgress:
        return 'in_progress';
      case QuizAttemptStatus.completed:
        return 'completed';
      case QuizAttemptStatus.submitted:
        return 'submitted';
      case QuizAttemptStatus.graded:
        return 'graded';
    }
  }

  String get displayName {
    switch (this) {
      case QuizAttemptStatus.inProgress:
        return 'In Progress';
      case QuizAttemptStatus.completed:
        return 'Completed';
      case QuizAttemptStatus.submitted:
        return 'Submitted';
      case QuizAttemptStatus.graded:
        return 'Graded';
    }
  }

  static QuizAttemptStatus fromDbValue(String value) {
    switch (value) {
      case 'in_progress':
        return QuizAttemptStatus.inProgress;
      case 'completed':
        return QuizAttemptStatus.completed;
      case 'submitted':
        return QuizAttemptStatus.submitted;
      case 'graded':
        return QuizAttemptStatus.graded;
      default:
        return QuizAttemptStatus.inProgress;
    }
  }
}

class QuizAttempt extends Equatable {
  final String id;
  final String schoolId;
  final String resourceId;
  final String userId;
  final QuizAttemptStatus status;
  final int totalQuestions;
  final int correctAnswers;
  final int score;
  final int maxScore;
  final DateTime startedAt;
  final DateTime? completedAt;
  final DateTime? submittedAt;
  final DateTime? gradedAt;
  final Duration timeSpent;
  final Map<String, dynamic> answers;

  const QuizAttempt({
    required this.id,
    required this.schoolId,
    required this.resourceId,
    required this.userId,
    required this.status,
    required this.totalQuestions,
    required this.correctAnswers,
    required this.score,
    required this.maxScore,
    required this.startedAt,
    this.completedAt,
    this.submittedAt,
    this.gradedAt,
    required this.timeSpent,
    required this.answers,
  });

  double get percentage => maxScore > 0 ? (score / maxScore) * 100 : 0;

  factory QuizAttempt.fromMap(Map<String, dynamic> map) {
    return QuizAttempt(
      id: map['id'] as String,
      schoolId: map['school_id'] as String,
      resourceId: map['resource_id'] as String,
      userId: map['user_id'] as String,
      status: QuizAttemptStatus.fromDbValue(map['status'] as String),
      totalQuestions: map['total_questions'] as int,
      correctAnswers: map['correct_answers'] as int,
      score: map['score'] as int,
      maxScore: map['max_score'] as int,
      startedAt: DateTime.parse(map['started_at'] as String),
      completedAt: map['completed_at'] != null
          ? DateTime.parse(map['completed_at'] as String)
          : null,
      submittedAt: map['submitted_at'] != null
          ? DateTime.parse(map['submitted_at'] as String)
          : null,
      gradedAt: map['graded_at'] != null
          ? DateTime.parse(map['graded_at'] as String)
          : null,
      timeSpent: Duration(seconds: map['time_spent_seconds'] as int? ?? 0),
      answers: Map<String, dynamic>.from(map['answers'] as Map? ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'school_id': schoolId,
      'resource_id': resourceId,
      'user_id': userId,
      'status': status.dbValue,
      'total_questions': totalQuestions,
      'correct_answers': correctAnswers,
      'score': score,
      'max_score': maxScore,
      'started_at': startedAt.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'submitted_at': submittedAt?.toIso8601String(),
      'graded_at': gradedAt?.toIso8601String(),
      'time_spent_seconds': timeSpent.inSeconds,
      'answers': answers,
    };
  }

  @override
  List<Object?> get props => [
        id,
        schoolId,
        resourceId,
        userId,
        status,
        totalQuestions,
        correctAnswers,
        score,
        maxScore,
        startedAt,
        completedAt,
        submittedAt,
        gradedAt,
        timeSpent,
        answers,
      ];
}