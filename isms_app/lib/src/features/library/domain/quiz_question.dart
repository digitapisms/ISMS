import 'package:equatable/equatable.dart';

enum QuestionType {
  multipleChoice,
  trueFalse,
  shortAnswer,
  essay,
}

extension QuestionTypeExtension on QuestionType {
  String get dbValue {
    switch (this) {
      case QuestionType.multipleChoice:
        return 'multiple_choice';
      case QuestionType.trueFalse:
        return 'true_false';
      case QuestionType.shortAnswer:
        return 'short_answer';
      case QuestionType.essay:
        return 'essay';
    }
  }

  String get displayName {
    switch (this) {
      case QuestionType.multipleChoice:
        return 'Multiple Choice';
      case QuestionType.trueFalse:
        return 'True/False';
      case QuestionType.shortAnswer:
        return 'Short Answer';
      case QuestionType.essay:
        return 'Essay';
    }
  }

  static QuestionType fromDbValue(String value) {
    switch (value) {
      case 'multiple_choice':
        return QuestionType.multipleChoice;
      case 'true_false':
        return QuestionType.trueFalse;
      case 'short_answer':
        return QuestionType.shortAnswer;
      case 'essay':
        return QuestionType.essay;
      default:
        return QuestionType.multipleChoice;
    }
  }
}

class QuizQuestion extends Equatable {
  final String id;
  final String schoolId;
  final String resourceId;
  final String questionText;
  final QuestionType type;
  final List<String> options;
  final List<int> correctAnswers;
  final String explanation;
  final int points;
  final int timeLimitSeconds;
  final int pageNumber;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const QuizQuestion({
    required this.id,
    required this.schoolId,
    required this.resourceId,
    required this.questionText,
    required this.type,
    required this.options,
    required this.correctAnswers,
    required this.explanation,
    required this.points,
    required this.timeLimitSeconds,
    required this.pageNumber,
    required this.createdAt,
    this.updatedAt,
  });

  factory QuizQuestion.fromMap(Map<String, dynamic> map) {
    return QuizQuestion(
      id: map['id'] as String,
      schoolId: map['school_id'] as String,
      resourceId: map['resource_id'] as String,
      questionText: map['question_text'] as String,
      type: QuestionType.fromDbValue(map['type'] as String),
      options: List<String>.from(map['options'] as List),
      correctAnswers: List<int>.from(map['correct_answers'] as List),
      explanation: map['explanation'] as String? ?? '',
      points: map['points'] as int,
      timeLimitSeconds: map['time_limit_seconds'] as int? ?? 60,
      pageNumber: map['page_number'] as int? ?? 1,
      createdAt: DateTime.parse(map['created_at'] as String),
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
      'question_text': questionText,
      'type': type.dbValue,
      'options': options,
      'correct_answers': correctAnswers,
      'explanation': explanation,
      'points': points,
      'time_limit_seconds': timeLimitSeconds,
      'page_number': pageNumber,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
        id,
        schoolId,
        resourceId,
        questionText,
        type,
        options,
        correctAnswers,
        explanation,
        points,
        timeLimitSeconds,
        pageNumber,
        createdAt,
        updatedAt,
      ];
}