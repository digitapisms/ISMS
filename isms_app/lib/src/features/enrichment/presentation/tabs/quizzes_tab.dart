import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/enrichment_providers.dart';
import '../../domain/quiz.dart';
import '../screens/create_quiz_screen.dart';
import '../screens/quiz_detail_screen.dart';
import '../screens/take_quiz_screen.dart';

class QuizzesTab extends ConsumerWidget {
  const QuizzesTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quizzesAsync = ref.watch(
      quizzesProvider({'categoryId': null, 'status': 'published'}),
    );

    return quizzesAsync.when(
      data: (quizzes) {
        if (quizzes.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.quiz_outlined, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'No quizzes available',
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                Text(
                  'Check back later for new quizzes',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.grey[500]),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Available Quizzes',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const CreateQuizScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Create Quiz'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: quizzes.length,
                itemBuilder: (context, index) {
                  final quiz = quizzes[index];
                  return _QuizCard(quiz: quiz);
                },
              ),
            ),
          ],
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
              'Failed to load quizzes',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                ref.invalidate(
                  quizzesProvider({'categoryId': null, 'status': 'published'}),
                );
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuizCard extends ConsumerWidget {
  final Quiz quiz;

  const _QuizCard({required this.quiz});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => QuizDetailScreen(quizId: quiz.id),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      quiz.title,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  Chip(
                    label: Text(quiz.mode.name.toUpperCase()),
                    backgroundColor: quiz.mode == QuizMode.live
                        ? Colors.orange[100]
                        : Colors.blue[100],
                  ),
                ],
              ),
              if (quiz.description != null) ...[
                const SizedBox(height: 8),
                Text(
                  quiz.description!,
                  style: Theme.of(context).textTheme.bodyMedium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  if (quiz.timeLimitSeconds != null)
                    Row(
                      children: [
                        Icon(
                          Icons.timer_outlined,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${quiz.timeLimitSeconds! ~/ 60} min',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(width: 16),
                      ],
                    ),
                  Text(
                    'Passing: ${quiz.passingScorePercent}%',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => TakeQuizScreen(quizId: quiz.id),
                        ),
                      );
                    },
                    child: const Text('Take Quiz'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
