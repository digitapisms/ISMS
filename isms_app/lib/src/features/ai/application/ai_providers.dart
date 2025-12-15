import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../school_registration/application/school_providers.dart';
import '../data/ai_repository.dart';
import '../domain/ai_prompt.dart';
import '../domain/ai_task.dart';

final aiRepositoryProvider = Provider<AiRepository>((ref) {
  return AiRepository();
});

final aiPromptsProvider = FutureProvider<List<AiPrompt>>((ref) async {
  final repo = ref.read(aiRepositoryProvider);
  return repo.fetchPrompts();
});

final aiTasksProvider = FutureProvider.autoDispose<List<AiTask>>((ref) async {
  final school = ref.watch(currentSchoolProvider);
  if (school == null) return const [];
  final repo = ref.read(aiRepositoryProvider);
  ref.keepAlive();
  return repo.fetchRecentTasks(schoolId: school.id);
});

class AiTaskRequest {
  AiTaskRequest({required this.promptKey, required this.input});

  final String promptKey;
  final Map<String, dynamic> input;
}

final aiTaskCreateProvider = FutureProvider.family
    .autoDispose<AiTask, AiTaskRequest>((ref, request) async {
      final school = ref.watch(currentSchoolProvider);
      if (school == null) {
        throw Exception('No school context available.');
      }
      final repo = ref.read(aiRepositoryProvider);
      final task = await repo.createTask(
        school: school,
        promptKey: request.promptKey,
        input: request.input,
      );
      ref.invalidate(aiTasksProvider);
      return task;
    });

final aiTaskProvider = FutureProvider.family.autoDispose<AiTask?, String>((
  ref,
  taskId,
) async {
  final repo = ref.read(aiRepositoryProvider);
  return repo.getTask(taskId);
});

final currentUserIdProvider = FutureProvider<String?>((ref) async {
  final repo = ref.read(aiRepositoryProvider);
  return repo.getCurrentUserId();
});
