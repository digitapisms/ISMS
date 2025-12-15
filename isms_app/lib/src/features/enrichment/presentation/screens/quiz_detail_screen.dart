import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/enrichment_providers.dart';
import '../../domain/quiz.dart';
import '../widgets/quiz_question_editor.dart';
import 'take_quiz_screen.dart';

class QuizDetailScreen extends ConsumerWidget {
  final String quizId;

  const QuizDetailScreen({super.key, required this.quizId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quizAsync = ref.watch(quizProvider(quizId));
    final questionsAsync = ref.watch(quizQuestionsProvider(quizId));

    return Scaffold(
      appBar: AppBar(title: const Text('Quiz Details')),
      body: quizAsync.when(
        data: (quiz) {
          if (quiz == null) {
            return const Center(child: Text('Quiz not found'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  quiz.title,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                if (quiz.description != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    quiz.description!,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
                const SizedBox(height: 24),
                _InfoRow(
                  icon: Icons.timer_outlined,
                  label: 'Time Limit',
                  value: quiz.timeLimitSeconds != null
                      ? '${quiz.timeLimitSeconds! ~/ 60} minutes'
                      : 'No limit',
                ),
                _InfoRow(
                  icon: Icons.check_circle_outline,
                  label: 'Passing Score',
                  value: '${quiz.passingScorePercent}%',
                ),
                if (quiz.maxAttempts != null)
                  _InfoRow(
                    icon: Icons.repeat,
                    label: 'Max Attempts',
                    value: quiz.maxAttempts.toString(),
                  ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Questions',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => QuizQuestionEditor(
                              quizId: quizId,
                              onSaved: () {
                                ref.invalidate(quizQuestionsProvider(quizId));
                              },
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Add Question'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                questionsAsync.when(
                  data: (questions) {
                    if (questions.isEmpty) {
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(
                                  Icons.quiz_outlined,
                                  size: 48,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No questions yet',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Add questions to make this quiz complete',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }
                    return Column(
                      children: questions.map((q) {
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: CircleAvatar(
                              child: Text('${questions.indexOf(q) + 1}'),
                            ),
                            title: Text(
                              q.questionText,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${q.points} point${q.points != 1 ? 's' : ''} • ${_getQuestionTypeLabel(q.questionType)}',
                                ),
                                if (q.options != null && q.options!.isNotEmpty)
                                  Text(
                                    'Options: ${q.options!.length}',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall,
                                  ),
                              ],
                            ),
                            trailing: PopupMenuButton(
                              itemBuilder: (context) => [
                                PopupMenuItem(
                                  child: const Row(
                                    children: [
                                      Icon(Icons.edit, size: 20),
                                      SizedBox(width: 8),
                                      Text('Edit'),
                                    ],
                                  ),
                                  onTap: () {
                                    Future.delayed(
                                      Duration.zero,
                                      () => Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              QuizQuestionEditor(
                                                quizId: quizId,
                                                question: q,
                                                onSaved: () {
                                                  ref.invalidate(
                                                    quizQuestionsProvider(
                                                      quizId,
                                                    ),
                                                  );
                                                },
                                              ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                PopupMenuItem(
                                  child: const Row(
                                    children: [
                                      Icon(
                                        Icons.delete,
                                        size: 20,
                                        color: Colors.red,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        'Delete',
                                        style: TextStyle(color: Colors.red),
                                      ),
                                    ],
                                  ),
                                  onTap: () async {
                                    final confirmed = await showDialog<bool>(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: const Text('Delete Question'),
                                        content: const Text(
                                          'Are you sure you want to delete this question?',
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context, false),
                                            child: const Text('Cancel'),
                                          ),
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context, true),
                                            style: TextButton.styleFrom(
                                              foregroundColor: Colors.red,
                                            ),
                                            child: const Text('Delete'),
                                          ),
                                        ],
                                      ),
                                    );
                                    if (confirmed == true && context.mounted) {
                                      try {
                                        final repo = ref.read(
                                          enrichmentRepositoryProvider,
                                        );
                                        await repo.deleteQuizQuestion(q.id);
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text('Question deleted'),
                                              backgroundColor: Colors.green,
                                            ),
                                          );
                                          ref.invalidate(
                                            quizQuestionsProvider(quizId),
                                          );
                                        }
                                      } catch (e) {
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text('Error: $e'),
                                              backgroundColor: Colors.red,
                                            ),
                                          );
                                        }
                                      }
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, stack) => Text('Error: $error'),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => TakeQuizScreen(quizId: quiz.id),
                        ),
                      );
                    },
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Start Quiz'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
              const SizedBox(height: 16),
              Text(
                'Failed to load quiz',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getQuestionTypeLabel(QuizQuestionType type) {
    switch (type) {
      case QuizQuestionType.multipleChoice:
        return 'Multiple Choice';
      case QuizQuestionType.trueFalse:
        return 'True/False';
      case QuizQuestionType.shortAnswer:
        return 'Short Answer';
    }
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text('$label: ', style: Theme.of(context).textTheme.bodyMedium),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
