import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/network/supabase_client.dart';
import '../domain/club.dart';
import '../domain/enrichment_category.dart';
import '../domain/game.dart';
import '../domain/quiz.dart';
import '../domain/reward.dart';

class EnrichmentRepository {
  SupabaseClient get _client => SupabaseManager.client;
  String? _schoolId;

  void setSchoolId(String? schoolId) {
    _schoolId = schoolId;
  }

  String? get schoolId => _schoolId;

  String _requireSchoolId() {
    final id = _schoolId;
    if (id == null) {
      throw Exception(
        'School context is required for this action. Please ensure you are signed in to a school tenant.',
      );
    }
    return id;
  }

  dynamic _filterBySchool(dynamic query, {String? override}) {
    final id = override ?? _schoolId;
    if (id == null) return query;
    return query.eq('school_id', id);
  }

  // ============================================================
  // ENRICHMENT CATEGORIES
  // ============================================================

  Future<List<EnrichmentCategory>> fetchCategories() async {
    var query = _client
        .from('enrichment_categories')
        .select()
        .eq('is_active', true)
        .order('display_order');
    query = _filterBySchool(query);
    final response = await query;
    final data = response as List<dynamic>;
    return data
        .map((row) => EnrichmentCategory.fromMap(row as Map<String, dynamic>))
        .toList();
  }

  Future<String> createCategory({
    required String name,
    String? description,
    String? icon,
    int displayOrder = 0,
  }) async {
    final schoolId = _requireSchoolId();
    final response = await _client
        .from('enrichment_categories')
        .insert({
          'school_id': schoolId,
          'name': name,
          'description': description,
          'icon': icon,
          'display_order': displayOrder,
          'is_active': true,
        })
        .select('id')
        .single();
    return response['id'] as String;
  }

  // ============================================================
  // QUIZZES
  // ============================================================

  Future<List<Quiz>> fetchQuizzes({String? categoryId, String? status}) async {
    dynamic query = _client.from('quizzes').select();
    query = _filterBySchool(query);
    if (categoryId != null) {
      query = query.eq('category_id', categoryId);
    }
    if (status != null) {
      query = query.eq('status', status);
    }
    query = query.order('created_at', ascending: false);
    final response = await query;
    final data = response as List<dynamic>;
    return data
        .map((row) => Quiz.fromMap(row as Map<String, dynamic>))
        .toList();
  }

  Future<Quiz?> fetchQuizById(String quizId) async {
    var query = _client.from('quizzes').select().eq('id', quizId);
    query = _filterBySchool(query);
    final response = await query.maybeSingle();
    if (response == null) return null;
    return Quiz.fromMap(Map<String, dynamic>.from(response));
  }

  Future<String> createQuiz(Map<String, dynamic> data) async {
    final schoolId = _requireSchoolId();
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    // Get user ID from users table
    final userRow = await _client
        .from('users')
        .select('id')
        .eq('auth_id', userId)
        .single();
    final createdBy = userRow['id'] as String;

    final quizData = {...data, 'school_id': schoolId, 'created_by': createdBy};
    final response = await _client
        .from('quizzes')
        .insert(quizData)
        .select('id')
        .single();
    return response['id'] as String;
  }

  Future<void> updateQuiz(String quizId, Map<String, dynamic> data) async {
    final schoolId = _requireSchoolId();
    await _client
        .from('quizzes')
        .update(data)
        .eq('id', quizId)
        .eq('school_id', schoolId);
  }

  Future<void> deleteQuiz(String quizId) async {
    final schoolId = _requireSchoolId();
    await _client
        .from('quizzes')
        .delete()
        .eq('id', quizId)
        .eq('school_id', schoolId);
  }

  // ============================================================
  // QUIZ QUESTIONS
  // ============================================================

  Future<List<QuizQuestion>> fetchQuizQuestions(String quizId) async {
    final response = await _client
        .from('quiz_questions')
        .select()
        .eq('quiz_id', quizId)
        .order('display_order');
    final data = response as List<dynamic>;
    return data
        .map((row) => QuizQuestion.fromMap(row as Map<String, dynamic>))
        .toList();
  }

  Future<String> createQuizQuestion(Map<String, dynamic> data) async {
    final response = await _client
        .from('quiz_questions')
        .insert(data)
        .select('id')
        .single();
    return response['id'] as String;
  }

  Future<void> updateQuizQuestion(
    String questionId,
    Map<String, dynamic> data,
  ) async {
    await _client.from('quiz_questions').update(data).eq('id', questionId);
  }

  Future<void> deleteQuizQuestion(String questionId) async {
    await _client.from('quiz_questions').delete().eq('id', questionId);
  }

  // ============================================================
  // QUIZ ATTEMPTS
  // ============================================================

  Future<List<QuizAttempt>> fetchQuizAttempts({
    String? quizId,
    String? studentId,
  }) async {
    dynamic query = _client.from('quiz_attempts').select();
    if (quizId != null) {
      query = query.eq('quiz_id', quizId);
    }
    if (studentId != null) {
      query = query.eq('student_id', studentId);
    }
    query = query.order('created_at', ascending: false);
    final response = await query;
    final data = response as List<dynamic>;
    return data
        .map((row) => QuizAttempt.fromMap(row as Map<String, dynamic>))
        .toList();
  }

  Future<QuizAttempt?> fetchQuizAttemptById(String attemptId) async {
    final response = await _client
        .from('quiz_attempts')
        .select()
        .eq('id', attemptId)
        .maybeSingle();
    if (response == null) return null;
    return QuizAttempt.fromMap(Map<String, dynamic>.from(response));
  }

  /// Get current user's database ID (from users table, not auth_id)
  Future<String?> getCurrentUserId() async {
    final authUser = _client.auth.currentUser;
    if (authUser == null) return null;

    // Get user record from users table
    final userRow = await _client
        .from('users')
        .select('id')
        .eq('auth_id', authUser.id)
        .maybeSingle();

    if (userRow == null) return null;
    return userRow['id'] as String;
  }

  /// Get current student ID from authenticated user
  Future<String?> getCurrentStudentId() async {
    final userId = await getCurrentUserId();
    if (userId == null) return null;

    // Find student linked to this user
    dynamic query = _client.from('students').select('id').eq('user_id', userId);
    query = _filterBySchool(query);
    final studentRow = await query.maybeSingle();

    if (studentRow == null) return null;
    return studentRow['id'] as String;
  }

  /// Get quiz leaderboard - top students by average quiz score
  Future<List<Map<String, dynamic>>> getQuizLeaderboard({
    int limit = 50,
  }) async {
    final schoolId = _requireSchoolId();

    // Get all quiz attempts with student info, grouped by student
    final response = await _client
        .rpc(
          'get_quiz_leaderboard',
          params: {'p_school_id': schoolId, 'p_limit': limit},
        )
        .catchError((_) {
          // Fallback if RPC doesn't exist - use direct query
          return _client
              .from('quiz_attempts')
              .select('''
            student_id,
            students!inner(id, full_name, admission_no),
            score,
            total_points,
            percentage
          ''')
              .eq('status', 'completed')
              .order('percentage', ascending: false)
              .limit(limit);
        });

    if (response is List) {
      // Process the response
      final Map<String, Map<String, dynamic>> studentScores = {};

      for (final row in response) {
        final data = row as Map<String, dynamic>;
        final studentId = data['student_id'] as String?;
        if (studentId == null) continue;

        final student = data['students'] as Map<String, dynamic>?;
        final percentage = (data['percentage'] as num?)?.toDouble() ?? 0.0;

        if (!studentScores.containsKey(studentId)) {
          studentScores[studentId] = {
            'student_id': studentId,
            'student': student,
            'total_attempts': 0,
            'total_score': 0.0,
            'average_percentage': 0.0,
          };
        }

        final entry = studentScores[studentId]!;
        entry['total_attempts'] = (entry['total_attempts'] as int) + 1;
        entry['total_score'] = (entry['total_score'] as double) + percentage;
        entry['average_percentage'] =
            (entry['total_score'] as double) / (entry['total_attempts'] as int);
      }

      final leaderboard = studentScores.values.toList()
        ..sort(
          (a, b) => (b['average_percentage'] as double).compareTo(
            a['average_percentage'] as double,
          ),
        );

      return leaderboard;
    }

    return [];
  }

  /// Get game leaderboard - top students by highest game scores
  Future<List<Map<String, dynamic>>> getGameLeaderboard({
    int limit = 50,
  }) async {
    _requireSchoolId(); // Ensure school context

    // Get all game sessions with student info, grouped by student
    final response = await _client
        .from('game_sessions')
        .select('''
          student_id,
          students!inner(id, full_name, admission_no),
          score,
          game_id,
          games!inner(name)
        ''')
        .not('score', 'is', null)
        .order('score', ascending: false)
        .limit(limit * 10); // Get more to aggregate

    final data = response as List<dynamic>;
    final Map<String, Map<String, dynamic>> studentScores = {};

    for (final row in data) {
      final item = row as Map<String, dynamic>;
      final studentId = item['student_id'] as String?;
      if (studentId == null) continue;

      final student = item['students'] as Map<String, dynamic>?;
      final score = (item['score'] as num?)?.toInt() ?? 0;

      if (!studentScores.containsKey(studentId)) {
        studentScores[studentId] = {
          'student_id': studentId,
          'student': student,
          'total_games': 0,
          'total_score': 0,
          'highest_score': 0,
        };
      }

      final entry = studentScores[studentId]!;
      entry['total_games'] = (entry['total_games'] as int) + 1;
      entry['total_score'] = (entry['total_score'] as int) + score;
      if (score > (entry['highest_score'] as int)) {
        entry['highest_score'] = score;
      }
    }

    final leaderboard = studentScores.values.toList()
      ..sort(
        (a, b) =>
            (b['highest_score'] as int).compareTo(a['highest_score'] as int),
      );

    return leaderboard.take(limit).toList();
  }

  Future<String> createQuizAttempt({
    required String quizId,
    String? studentId,
  }) async {
    // If studentId not provided, get current student
    final finalStudentId = studentId ?? await getCurrentStudentId();
    if (finalStudentId == null) {
      throw Exception('No student found for current user');
    }
    final response = await _client
        .from('quiz_attempts')
        .insert({
          'quiz_id': quizId,
          'student_id': finalStudentId,
          'score': 0,
          'total_points': 0,
          'percentage': 0.0,
          'answers': {},
          'status': 'in_progress',
        })
        .select('id')
        .single();
    return response['id'] as String;
  }

  Future<void> submitQuizAttempt({
    required String attemptId,
    required Map<String, String> answers,
    required int score,
    required int totalPoints,
    int? timeTakenSeconds,
  }) async {
    final percentage = totalPoints > 0 ? (score / totalPoints * 100) : 0.0;
    await _client
        .from('quiz_attempts')
        .update({
          'answers': answers,
          'score': score,
          'total_points': totalPoints,
          'percentage': percentage,
          'submitted_at': DateTime.now().toIso8601String(),
          'time_taken_seconds': timeTakenSeconds,
          'status': 'completed',
        })
        .eq('id', attemptId);
  }

  // ============================================================
  // GAMES
  // ============================================================

  Future<List<Game>> fetchGames() async {
    var query = _client
        .from('games')
        .select()
        .eq('is_active', true)
        .order('display_order');
    query = _filterBySchool(query);
    final response = await query;
    final data = response as List<dynamic>;
    return data
        .map((row) => Game.fromMap(row as Map<String, dynamic>))
        .toList();
  }

  Future<Game?> fetchGameById(String gameId) async {
    var query = _client.from('games').select().eq('id', gameId);
    query = _filterBySchool(query);
    final response = await query.maybeSingle();
    if (response == null) return null;
    return Game.fromMap(Map<String, dynamic>.from(response));
  }

  Future<String> createGame(Map<String, dynamic> data) async {
    final schoolId = _requireSchoolId();
    final gameData = {...data, 'school_id': schoolId};
    final response = await _client
        .from('games')
        .insert(gameData)
        .select('id')
        .single();
    return response['id'] as String;
  }

  Future<void> updateGame(String gameId, Map<String, dynamic> data) async {
    final schoolId = _requireSchoolId();
    await _client
        .from('games')
        .update(data)
        .eq('id', gameId)
        .eq('school_id', schoolId);
  }

  Future<void> deleteGame(String gameId) async {
    final schoolId = _requireSchoolId();
    await _client
        .from('games')
        .delete()
        .eq('id', gameId)
        .eq('school_id', schoolId);
  }

  // ============================================================
  // GAME SESSIONS
  // ============================================================

  Future<List<GameSession>> fetchGameSessions({
    String? gameId,
    String? studentId,
  }) async {
    dynamic query = _client.from('game_sessions').select();
    if (gameId != null) {
      query = query.eq('game_id', gameId);
    }
    if (studentId != null) {
      query = query.eq('student_id', studentId);
    }
    query = query.order('played_at', ascending: false);
    final response = await query;
    final data = response as List<dynamic>;
    return data
        .map((row) => GameSession.fromMap(row as Map<String, dynamic>))
        .toList();
  }

  Future<String> createGameSession({
    required String gameId,
    String? studentId,
    int? score,
    int? durationSeconds,
    Map<String, dynamic>? metadata,
  }) async {
    // If studentId not provided, get current student
    final finalStudentId = studentId ?? await getCurrentStudentId();
    if (finalStudentId == null) {
      throw Exception('No student found for current user');
    }
    final response = await _client
        .from('game_sessions')
        .insert({
          'game_id': gameId,
          'student_id': finalStudentId,
          'score': score,
          'duration_seconds': durationSeconds,
          'metadata': metadata ?? {},
        })
        .select('id')
        .single();
    return response['id'] as String;
  }

  // ============================================================
  // CLUBS
  // ============================================================

  Future<List<Club>> fetchClubs({String? status}) async {
    dynamic query = _client.from('clubs').select();
    query = _filterBySchool(query);
    if (status != null) {
      query = query.eq('status', status);
    }
    query = query.order('created_at', ascending: false);
    final response = await query;
    final data = response as List<dynamic>;
    return data
        .map((row) => Club.fromMap(row as Map<String, dynamic>))
        .toList();
  }

  Future<Club?> fetchClubById(String clubId) async {
    var query = _client.from('clubs').select().eq('id', clubId);
    query = _filterBySchool(query);
    final response = await query.maybeSingle();
    if (response == null) return null;
    return Club.fromMap(Map<String, dynamic>.from(response));
  }

  Future<String> createClub(Map<String, dynamic> data) async {
    final schoolId = _requireSchoolId();
    final clubData = {...data, 'school_id': schoolId};
    final response = await _client
        .from('clubs')
        .insert(clubData)
        .select('id')
        .single();
    return response['id'] as String;
  }

  Future<void> updateClub(String clubId, Map<String, dynamic> data) async {
    final schoolId = _requireSchoolId();
    await _client
        .from('clubs')
        .update(data)
        .eq('id', clubId)
        .eq('school_id', schoolId);
  }

  Future<void> deleteClub(String clubId) async {
    final schoolId = _requireSchoolId();
    await _client
        .from('clubs')
        .delete()
        .eq('id', clubId)
        .eq('school_id', schoolId);
  }

  // ============================================================
  // CLUB MEMBERS
  // ============================================================

  Future<List<ClubMember>> fetchClubMembers(String clubId) async {
    final response = await _client
        .from('club_members')
        .select()
        .eq('club_id', clubId)
        .order('created_at', ascending: false);
    final data = response as List<dynamic>;
    return data
        .map((row) => ClubMember.fromMap(row as Map<String, dynamic>))
        .toList();
  }

  Future<String> joinClub({required String clubId, String? userId}) async {
    // If userId not provided, get current user
    final finalUserId = userId ?? await getCurrentUserId();
    if (finalUserId == null) {
      throw Exception('User not authenticated or user record not found');
    }
    final response = await _client
        .from('club_members')
        .insert({
          'club_id': clubId,
          'user_id': finalUserId,
          'role': 'member',
          'status': 'pending',
        })
        .select('id')
        .single();
    return response['id'] as String;
  }

  Future<void> updateClubMemberStatus({
    required String memberId,
    required String status,
  }) async {
    final updateData = <String, dynamic>{'status': status};
    if (status == 'approved') {
      updateData['joined_at'] = DateTime.now().toIso8601String();
    } else if (status == 'left') {
      updateData['left_at'] = DateTime.now().toIso8601String();
    }
    await _client.from('club_members').update(updateData).eq('id', memberId);
  }

  Future<void> leaveClub({required String clubId, String? userId}) async {
    final finalUserId = userId ?? await getCurrentUserId();
    if (finalUserId == null) {
      throw Exception('User not authenticated or user record not found');
    }

    // Find the member record
    final memberQuery = await _client
        .from('club_members')
        .select('id')
        .eq('club_id', clubId)
        .eq('user_id', finalUserId)
        .maybeSingle();

    if (memberQuery == null) {
      throw Exception('You are not a member of this club');
    }

    final memberId = memberQuery['id'] as String;
    await updateClubMemberStatus(memberId: memberId, status: 'left');
  }

  // ============================================================
  // CLUB EVENTS
  // ============================================================

  Future<List<ClubEvent>> fetchClubEvents(String clubId) async {
    final response = await _client
        .from('club_events')
        .select()
        .eq('club_id', clubId)
        .order('start_time', ascending: true);
    final data = response as List<dynamic>;
    return data
        .map((row) => ClubEvent.fromMap(row as Map<String, dynamic>))
        .toList();
  }

  Future<String> createClubEvent(Map<String, dynamic> data) async {
    final response = await _client
        .from('club_events')
        .insert(data)
        .select('id')
        .single();
    return response['id'] as String;
  }

  Future<void> updateClubEvent(
    String eventId,
    Map<String, dynamic> data,
  ) async {
    await _client.from('club_events').update(data).eq('id', eventId);
  }

  Future<void> deleteClubEvent(String eventId) async {
    await _client.from('club_events').delete().eq('id', eventId);
  }

  // ============================================================
  // REWARDS
  // ============================================================

  Future<List<ActivityReward>> fetchActivityRewards() async {
    var query = _client
        .from('activity_rewards')
        .select()
        .eq('is_active', true)
        .order('points_required');
    query = _filterBySchool(query);
    final response = await query;
    final data = response as List<dynamic>;
    return data
        .map((row) => ActivityReward.fromMap(row as Map<String, dynamic>))
        .toList();
  }

  Future<String> createActivityReward(Map<String, dynamic> data) async {
    final schoolId = _requireSchoolId();
    final rewardData = {...data, 'school_id': schoolId};
    final response = await _client
        .from('activity_rewards')
        .insert(rewardData)
        .select('id')
        .single();
    return response['id'] as String;
  }

  Future<List<StudentReward>> fetchStudentRewards({String? studentId}) async {
    dynamic query = _client.from('student_rewards').select();
    if (studentId != null) {
      query = query.eq('student_id', studentId);
    }
    query = query.order('redeemed_at', ascending: false);
    final response = await query;
    final data = response as List<dynamic>;
    return data
        .map((row) => StudentReward.fromMap(row as Map<String, dynamic>))
        .toList();
  }

  Future<String> redeemReward({
    String? studentId,
    required String rewardId,
    required int pointsSpent,
  }) async {
    // If studentId not provided, get current student
    final finalStudentId = studentId ?? await getCurrentStudentId();
    if (finalStudentId == null) {
      throw Exception('No student found for current user');
    }
    final response = await _client
        .from('student_rewards')
        .insert({
          'student_id': finalStudentId,
          'reward_id': rewardId,
          'points_spent': pointsSpent,
          'status': 'pending',
        })
        .select('id')
        .single();
    return response['id'] as String;
  }

  // ============================================================
  // ENGAGEMENT STATS
  // ============================================================

  Future<List<StudentEngagementStats>> fetchStudentEngagementStats({
    required String studentId,
    String? period,
  }) async {
    dynamic query = _client
        .from('student_engagement_stats')
        .select()
        .eq('student_id', studentId);
    if (period != null) {
      query = query.eq('period', period);
    }
    query = query.order('last_updated', ascending: false);
    final response = await query;
    final data = response as List<dynamic>;
    return data
        .map(
          (row) => StudentEngagementStats.fromMap(row as Map<String, dynamic>),
        )
        .toList();
  }

  Future<double> getStudentPoints(String studentId) async {
    final stats = await fetchStudentEngagementStats(
      studentId: studentId,
      period: 'all_time',
    );
    final pointsStat = stats.firstWhere(
      (s) => s.metricKey == 'points_earned',
      orElse: () => StudentEngagementStats(
        id: '',
        studentId: studentId,
        schoolId: _requireSchoolId(),
        metricKey: 'points_earned',
        metricValue: 0.0,
        period: 'all_time',
        metadata: {},
        lastUpdated: DateTime.now(),
        createdAt: DateTime.now(),
      ),
    );
    return pointsStat.metricValue;
  }
}
