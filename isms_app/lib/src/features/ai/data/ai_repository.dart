import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/network/supabase_client.dart';
import '../../school_registration/domain/school.dart';
import '../domain/ai_prompt.dart';
import '../domain/ai_task.dart';

class AiRepository {
  SupabaseClient get _client => SupabaseManager.client;

  Future<List<AiPrompt>> fetchPrompts() async {
    final response = await _client
        .from('ai_prompts')
        .select()
        .order('name', ascending: true);
    return (response as List)
        .map((row) => AiPrompt.fromMap(row as Map<String, dynamic>))
        .toList();
  }

  Future<AiTask> createTask({
    required School school,
    required String promptKey,
    required Map<String, dynamic> input,
    String? userId,
  }) async {
    final finalUserId = userId ?? await getCurrentUserId();

    final response = await _client
        .from('ai_tasks')
        .insert({
          'school_id': school.id,
          'user_id': finalUserId,
          'prompt_key': promptKey,
          'status': 'pending', // Explicitly set to pending for trigger
          'input': input,
        })
        .select()
        .maybeSingle();

    if (response == null) {
      throw Exception('Failed to create AI task');
    }

    return AiTask.fromMap(Map<String, dynamic>.from(response));
  }

  Future<List<AiTask>> fetchRecentTasks({
    required String schoolId,
    int limit = 20,
  }) async {
    final response = await _client
        .from('ai_tasks')
        .select()
        .eq('school_id', schoolId)
        .order('created_at', ascending: false)
        .limit(limit);

    return (response as List)
        .map((row) => AiTask.fromMap(row as Map<String, dynamic>))
        .toList();
  }

  Future<AiTask?> getTask(String taskId) async {
    final response = await _client
        .from('ai_tasks')
        .select()
        .eq('id', taskId)
        .maybeSingle();
    return response == null
        ? null
        : AiTask.fromMap(Map<String, dynamic>.from(response));
  }

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
}
