enum QuizMode { practice, live }

enum QuizVisibility { public, class_, private }

enum QuizStatus { draft, published, archived }

class Quiz {
  final String id;
  final String schoolId;
  final String? categoryId;
  final String title;
  final String? description;
  final QuizMode mode;
  final QuizVisibility visibility;
  final String? targetClassId;
  final String createdBy;
  final String? aiPromptKey;
  final int? timeLimitSeconds;
  final int passingScorePercent;
  final int? maxAttempts;
  final QuizStatus status;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;
  final DateTime updatedAt;

  Quiz({
    required this.id,
    required this.schoolId,
    this.categoryId,
    required this.title,
    this.description,
    required this.mode,
    required this.visibility,
    this.targetClassId,
    required this.createdBy,
    this.aiPromptKey,
    this.timeLimitSeconds,
    required this.passingScorePercent,
    this.maxAttempts,
    required this.status,
    required this.metadata,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Quiz.fromMap(Map<String, dynamic> map) {
    return Quiz(
      id: map['id'] as String,
      schoolId: map['school_id'] as String,
      categoryId: map['category_id'] as String?,
      title: map['title'] as String,
      description: map['description'] as String?,
      mode: QuizMode.values.firstWhere(
        (e) => e.name == map['mode'],
        orElse: () => QuizMode.practice,
      ),
      visibility: QuizVisibility.values.firstWhere(
        (e) =>
            e.name ==
            (map['visibility'] == 'class' ? 'class_' : map['visibility']),
        orElse: () => QuizVisibility.public,
      ),
      targetClassId: map['target_class_id'] as String?,
      createdBy: map['created_by'] as String,
      aiPromptKey: map['ai_prompt_key'] as String?,
      timeLimitSeconds: map['time_limit_seconds'] as int?,
      passingScorePercent:
          (map['passing_score_percent'] as num?)?.toInt() ?? 50,
      maxAttempts: map['max_attempts'] as int?,
      status: QuizStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => QuizStatus.draft,
      ),
      metadata: (map['metadata'] as Map<String, dynamic>?) ?? {},
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'school_id': schoolId,
      'category_id': categoryId,
      'title': title,
      'description': description,
      'mode': mode.name,
      'visibility': visibility == QuizVisibility.class_
          ? 'class'
          : visibility.name,
      'target_class_id': targetClassId,
      'created_by': createdBy,
      'ai_prompt_key': aiPromptKey,
      'time_limit_seconds': timeLimitSeconds,
      'passing_score_percent': passingScorePercent,
      'max_attempts': maxAttempts,
      'status': status.name,
      'metadata': metadata,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

enum QuizQuestionType { multipleChoice, trueFalse, shortAnswer }

class QuizQuestion {
  final String id;
  final String quizId;
  final QuizQuestionType questionType;
  final String questionText;
  final List<String>? options;
  final String correctAnswer;
  final int points;
  final String? explanation;
  final int displayOrder;
  final DateTime createdAt;
  final DateTime updatedAt;

  QuizQuestion({
    required this.id,
    required this.quizId,
    required this.questionType,
    required this.questionText,
    this.options,
    required this.correctAnswer,
    required this.points,
    this.explanation,
    required this.displayOrder,
    required this.createdAt,
    required this.updatedAt,
  });

  factory QuizQuestion.fromMap(Map<String, dynamic> map) {
    final optionsData = map['options'];
    List<String>? optionsList;
    if (optionsData != null) {
      if (optionsData is List) {
        optionsList = optionsData.map((e) => e.toString()).toList();
      } else if (optionsData is Map) {
        optionsList = (optionsData['options'] as List?)
            ?.map((e) => e.toString())
            .toList();
      }
    }

    return QuizQuestion(
      id: map['id'] as String,
      quizId: map['quiz_id'] as String,
      questionType: QuizQuestionType.values.firstWhere(
        (e) =>
            e.name == map['question_type']?.toString().replaceAll('_', '') ||
            e.name == map['question_type'],
        orElse: () => QuizQuestionType.multipleChoice,
      ),
      questionText: map['question_text'] as String,
      options: optionsList,
      correctAnswer: map['correct_answer'] as String,
      points: (map['points'] as num?)?.toInt() ?? 1,
      explanation: map['explanation'] as String?,
      displayOrder: (map['display_order'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'quiz_id': quizId,
      'question_type': questionType.name
          .replaceAll(RegExp(r'(?<!^)(?=[A-Z])'), '_')
          .toLowerCase(),
      'question_text': questionText,
      'options': options,
      'correct_answer': correctAnswer,
      'points': points,
      'explanation': explanation,
      'display_order': displayOrder,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

enum QuizAttemptStatus { inProgress, completed, abandoned }

class QuizAttempt {
  final String id;
  final String quizId;
  final String studentId;
  final int score;
  final int totalPoints;
  final double percentage;
  final Map<String, String> answers;
  final DateTime startedAt;
  final DateTime? submittedAt;
  final int? timeTakenSeconds;
  final QuizAttemptStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  QuizAttempt({
    required this.id,
    required this.quizId,
    required this.studentId,
    required this.score,
    required this.totalPoints,
    required this.percentage,
    required this.answers,
    required this.startedAt,
    this.submittedAt,
    this.timeTakenSeconds,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory QuizAttempt.fromMap(Map<String, dynamic> map) {
    final answersData = map['answers'];
    Map<String, String> answersMap = {};
    if (answersData is Map) {
      answersMap = answersData.map(
        (key, value) => MapEntry(key.toString(), value.toString()),
      );
    }

    return QuizAttempt(
      id: map['id'] as String,
      quizId: map['quiz_id'] as String,
      studentId: map['student_id'] as String,
      score: (map['score'] as num?)?.toInt() ?? 0,
      totalPoints: (map['total_points'] as num?)?.toInt() ?? 0,
      percentage: (map['percentage'] as num?)?.toDouble() ?? 0.0,
      answers: answersMap,
      startedAt: DateTime.parse(map['started_at'] as String),
      submittedAt: map['submitted_at'] != null
          ? DateTime.parse(map['submitted_at'] as String)
          : null,
      timeTakenSeconds: map['time_taken_seconds'] as int?,
      status: QuizAttemptStatus.values.firstWhere(
        (e) =>
            e.name == map['status']?.toString().replaceAll('_', '') ||
            e.name == map['status'],
        orElse: () => QuizAttemptStatus.inProgress,
      ),
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'quiz_id': quizId,
      'student_id': studentId,
      'score': score,
      'total_points': totalPoints,
      'percentage': percentage,
      'answers': answers,
      'started_at': startedAt.toIso8601String(),
      'submitted_at': submittedAt?.toIso8601String(),
      'time_taken_seconds': timeTakenSeconds,
      'status': status.name
          .replaceAll(RegExp(r'(?<!^)(?=[A-Z])'), '_')
          .toLowerCase(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
