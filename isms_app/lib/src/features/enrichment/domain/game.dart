enum GameType { embeddedUrl, builtIn, external }

class Game {
  final String id;
  final String schoolId;
  final String title;
  final String? description;
  final GameType gameType;
  final String? gameUrl;
  final int? minAge;
  final int? maxAge;
  final List<String> subjectTags;
  final Map<String, dynamic> config;
  final bool isActive;
  final int displayOrder;
  final DateTime createdAt;
  final DateTime updatedAt;

  Game({
    required this.id,
    required this.schoolId,
    required this.title,
    this.description,
    required this.gameType,
    this.gameUrl,
    this.minAge,
    this.maxAge,
    required this.subjectTags,
    required this.config,
    required this.isActive,
    required this.displayOrder,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Game.fromMap(Map<String, dynamic> map) {
    final tagsData = map['subject_tags'];
    List<String> tags = [];
    if (tagsData is List) {
      tags = tagsData.map((e) => e.toString()).toList();
    }

    return Game(
      id: map['id'] as String,
      schoolId: map['school_id'] as String,
      title: map['title'] as String,
      description: map['description'] as String?,
      gameType: GameType.values.firstWhere(
        (e) =>
            e.name == map['game_type']?.toString().replaceAll('_', '') ||
            e.name == map['game_type'],
        orElse: () => GameType.embeddedUrl,
      ),
      gameUrl: map['game_url'] as String?,
      minAge: map['min_age'] as int?,
      maxAge: map['max_age'] as int?,
      subjectTags: tags,
      config: (map['config'] as Map<String, dynamic>?) ?? {},
      isActive: map['is_active'] as bool? ?? true,
      displayOrder: (map['display_order'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'school_id': schoolId,
      'title': title,
      'description': description,
      'game_type': gameType.name
          .replaceAll(RegExp(r'(?<!^)(?=[A-Z])'), '_')
          .toLowerCase(),
      'game_url': gameUrl,
      'min_age': minAge,
      'max_age': maxAge,
      'subject_tags': subjectTags,
      'config': config,
      'is_active': isActive,
      'display_order': displayOrder,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

class GameSession {
  final String id;
  final String gameId;
  final String studentId;
  final int? score;
  final int? durationSeconds;
  final Map<String, dynamic> metadata;
  final DateTime playedAt;
  final DateTime createdAt;

  GameSession({
    required this.id,
    required this.gameId,
    required this.studentId,
    this.score,
    this.durationSeconds,
    required this.metadata,
    required this.playedAt,
    required this.createdAt,
  });

  factory GameSession.fromMap(Map<String, dynamic> map) {
    return GameSession(
      id: map['id'] as String,
      gameId: map['game_id'] as String,
      studentId: map['student_id'] as String,
      score: map['score'] as int?,
      durationSeconds: map['duration_seconds'] as int?,
      metadata: (map['metadata'] as Map<String, dynamic>?) ?? {},
      playedAt: DateTime.parse(map['played_at'] as String),
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'game_id': gameId,
      'student_id': studentId,
      'score': score,
      'duration_seconds': durationSeconds,
      'metadata': metadata,
      'played_at': playedAt.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }
}
