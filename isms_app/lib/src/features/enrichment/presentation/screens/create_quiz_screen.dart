import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/enrichment_providers.dart';
import '../../domain/quiz.dart';

class CreateQuizScreen extends ConsumerStatefulWidget {
  const CreateQuizScreen({super.key});

  @override
  ConsumerState<CreateQuizScreen> createState() => _CreateQuizScreenState();
}

class _CreateQuizScreenState extends ConsumerState<CreateQuizScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _timeLimitController = TextEditingController();
  final _passingScoreController = TextEditingController(text: '50');
  final _maxAttemptsController = TextEditingController();

  QuizMode _mode = QuizMode.practice;
  QuizVisibility _visibility = QuizVisibility.public;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _timeLimitController.dispose();
    _passingScoreController.dispose();
    _maxAttemptsController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final repo = ref.read(enrichmentRepositoryProvider);
      await repo.createQuiz({
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        'mode': _mode.name,
        'visibility': _visibility == QuizVisibility.class_
            ? 'class'
            : _visibility.name,
        'time_limit_seconds': _timeLimitController.text.trim().isEmpty
            ? null
            : int.tryParse(_timeLimitController.text.trim()) != null
            ? int.parse(_timeLimitController.text.trim()) * 60
            : null,
        'passing_score_percent':
            int.tryParse(_passingScoreController.text.trim()) ?? 50,
        'max_attempts': _maxAttemptsController.text.trim().isEmpty
            ? null
            : int.tryParse(_maxAttemptsController.text.trim()),
        'status': 'draft',
      });

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Quiz created successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Quiz')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Quiz Title *',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<QuizMode>(
                initialValue: _mode,
                decoration: const InputDecoration(
                  labelText: 'Mode',
                  border: OutlineInputBorder(),
                ),
                items: QuizMode.values.map((mode) {
                  return DropdownMenuItem(
                    value: mode,
                    child: Text(mode.name.toUpperCase()),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _mode = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<QuizVisibility>(
                initialValue: _visibility,
                decoration: const InputDecoration(
                  labelText: 'Visibility',
                  border: OutlineInputBorder(),
                ),
                items: QuizVisibility.values.map((visibility) {
                  return DropdownMenuItem(
                    value: visibility,
                    child: Text(
                      visibility == QuizVisibility.class_
                          ? 'Class'
                          : visibility.name.toUpperCase(),
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _visibility = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _timeLimitController,
                decoration: const InputDecoration(
                  labelText: 'Time Limit (minutes)',
                  border: OutlineInputBorder(),
                  helperText: 'Leave empty for no time limit',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passingScoreController,
                decoration: const InputDecoration(
                  labelText: 'Passing Score (%) *',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a passing score';
                  }
                  final score = int.tryParse(value.trim());
                  if (score == null || score < 0 || score > 100) {
                    return 'Please enter a valid score (0-100)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _maxAttemptsController,
                decoration: const InputDecoration(
                  labelText: 'Max Attempts',
                  border: OutlineInputBorder(),
                  helperText: 'Leave empty for unlimited attempts',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Create Quiz'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
