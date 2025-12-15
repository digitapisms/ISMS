import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/enrichment_providers.dart';
import '../../domain/quiz.dart';

class TakeQuizScreen extends ConsumerStatefulWidget {
  final String quizId;

  const TakeQuizScreen({super.key, required this.quizId});

  @override
  ConsumerState<TakeQuizScreen> createState() => _TakeQuizScreenState();
}

class _TakeQuizScreenState extends ConsumerState<TakeQuizScreen> {
  int _currentQuestionIndex = 0;
  Map<String, String> _answers = {};
  DateTime? _startTime;
  String? _attemptId;

  @override
  void initState() {
    super.initState();
    _startTime = DateTime.now();
    _initializeAttempt();
  }

  Future<void> _initializeAttempt() async {
    final repo = ref.read(enrichmentRepositoryProvider);
    // createQuizAttempt will automatically get current student if studentId is null
    _attemptId = await repo.createQuizAttempt(
      quizId: widget.quizId,
      studentId: null, // Will auto-detect from current user
    );
  }

  @override
  Widget build(BuildContext context) {
    final quizAsync = ref.watch(quizProvider(widget.quizId));
    final questionsAsync = ref.watch(quizQuestionsProvider(widget.quizId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Taking Quiz'),
        actions: [
          if (_startTime != null && quizAsync.value?.timeLimitSeconds != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: _TimerWidget(
                startTime: _startTime!,
                durationSeconds: quizAsync.value!.timeLimitSeconds!,
              ),
            ),
        ],
      ),
      body: quizAsync.when(
        data: (quiz) {
          if (quiz == null) {
            return const Center(child: Text('Quiz not found'));
          }

          return questionsAsync.when(
            data: (questions) {
              if (questions.isEmpty) {
                return const Center(child: Text('No questions available'));
              }

              if (_currentQuestionIndex >= questions.length) {
                return _buildResults(context, quiz, questions);
              }

              final question = questions[_currentQuestionIndex];
              return _buildQuestion(context, question, questions.length);
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(child: Text('Error: $error')),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
    );
  }

  Widget _buildQuestion(
    BuildContext context,
    QuizQuestion question,
    int totalQuestions,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LinearProgressIndicator(
            value: (_currentQuestionIndex + 1) / totalQuestions,
          ),
          const SizedBox(height: 16),
          Text(
            'Question ${_currentQuestionIndex + 1} of $totalQuestions',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 24),
          Text(
            question.questionText,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 24),
          if (question.questionType == QuizQuestionType.multipleChoice &&
              question.options != null)
            ...question.options!.map((option) {
              final isSelected = _answers[question.id] == option;
              return RadioListTile<String>(
                title: Text(option),
                value: option,
                groupValue: _answers[question.id],
                onChanged: (value) {
                  setState(() {
                    _answers[question.id] = value!;
                  });
                },
                selected: isSelected,
              );
            }),
          if (question.questionType == QuizQuestionType.trueFalse)
            ...['True', 'False'].map((option) {
              return RadioListTile<String>(
                title: Text(option),
                value: option,
                groupValue: _answers[question.id],
                onChanged: (value) {
                  setState(() {
                    _answers[question.id] = value!;
                  });
                },
              );
            }),
          if (question.questionType == QuizQuestionType.shortAnswer)
            TextField(
              decoration: const InputDecoration(
                labelText: 'Your answer',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  _answers[question.id] = value;
                });
              },
            ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (_currentQuestionIndex > 0)
                OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _currentQuestionIndex--;
                    });
                  },
                  child: const Text('Previous'),
                )
              else
                const SizedBox(),
              ElevatedButton(
                onPressed: _answers[question.id] != null
                    ? () {
                        if (_currentQuestionIndex < totalQuestions - 1) {
                          setState(() {
                            _currentQuestionIndex++;
                          });
                        } else {
                          _submitQuiz();
                        }
                      }
                    : null,
                child: Text(
                  _currentQuestionIndex < totalQuestions - 1
                      ? 'Next'
                      : 'Submit Quiz',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResults(
    BuildContext context,
    Quiz quiz,
    List<QuizQuestion> questions,
  ) {
    int score = 0;
    int totalPoints = 0;

    for (final question in questions) {
      totalPoints += question.points;
      if (_answers[question.id] == question.correctAnswer) {
        score += question.points;
      }
    }

    final percentage = totalPoints > 0 ? (score / totalPoints * 100) : 0.0;
    final passed = percentage >= quiz.passingScorePercent;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              passed ? Icons.check_circle : Icons.cancel,
              size: 80,
              color: passed ? Colors.green : Colors.red,
            ),
            const SizedBox(height: 24),
            Text(
              passed ? 'Congratulations!' : 'Try Again',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 16),
            Text(
              'Score: $score / $totalPoints',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            Text(
              '${percentage.toStringAsFixed(1)}%',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Done'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitQuiz() async {
    if (_attemptId == null) return;

    final questions = await ref.read(
      quizQuestionsProvider(widget.quizId).future,
    );
    int score = 0;
    int totalPoints = 0;

    for (final question in questions) {
      totalPoints += question.points;
      if (_answers[question.id] == question.correctAnswer) {
        score += question.points;
      }
    }

    final timeTaken = _startTime != null
        ? DateTime.now().difference(_startTime!).inSeconds
        : null;

    final repo = ref.read(enrichmentRepositoryProvider);
    await repo.submitQuizAttempt(
      attemptId: _attemptId!,
      answers: _answers,
      score: score,
      totalPoints: totalPoints,
      timeTakenSeconds: timeTaken,
    );

    setState(() {
      _currentQuestionIndex = questions.length; // Show results
    });
  }
}

class _TimerWidget extends StatefulWidget {
  final DateTime startTime;
  final int durationSeconds;

  const _TimerWidget({required this.startTime, required this.durationSeconds});

  @override
  State<_TimerWidget> createState() => _TimerWidgetState();
}

class _TimerWidgetState extends State<_TimerWidget> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DateTime>(
      stream: Stream.periodic(
        const Duration(seconds: 1),
        (_) => DateTime.now(),
      ),
      builder: (context, snapshot) {
        final elapsed = DateTime.now().difference(widget.startTime).inSeconds;
        final remaining = widget.durationSeconds - elapsed;
        final minutes = remaining ~/ 60;
        final seconds = remaining % 60;

        if (remaining <= 0) {
          return Text(
            'Time\'s Up!',
            style: TextStyle(
              color: Colors.red[700],
              fontWeight: FontWeight.bold,
            ),
          );
        }

        return Text(
          '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
          style: TextStyle(
            color: remaining < 60 ? Colors.red[700] : null,
            fontWeight: FontWeight.bold,
          ),
        );
      },
    );
  }
}
