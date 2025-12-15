import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/enrichment_providers.dart';
import '../../domain/quiz.dart';

class QuizQuestionEditor extends ConsumerStatefulWidget {
  final String quizId;
  final QuizQuestion? question;
  final VoidCallback? onSaved;

  const QuizQuestionEditor({
    super.key,
    required this.quizId,
    this.question,
    this.onSaved,
  });

  @override
  ConsumerState<QuizQuestionEditor> createState() => _QuizQuestionEditorState();
}

class _QuizQuestionEditorState extends ConsumerState<QuizQuestionEditor> {
  final _formKey = GlobalKey<FormState>();
  final _questionTextController = TextEditingController();
  final _correctAnswerController = TextEditingController();
  final _explanationController = TextEditingController();
  final _pointsController = TextEditingController(text: '1');
  final _displayOrderController = TextEditingController(text: '0');

  final List<TextEditingController> _optionControllers = [];
  QuizQuestionType _questionType = QuizQuestionType.multipleChoice;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.question != null) {
      _questionTextController.text = widget.question!.questionText;
      _correctAnswerController.text = widget.question!.correctAnswer;
      _explanationController.text = widget.question!.explanation ?? '';
      _pointsController.text = widget.question!.points.toString();
      _displayOrderController.text = widget.question!.displayOrder.toString();
      _questionType = widget.question!.questionType;

      if (widget.question!.options != null) {
        for (final option in widget.question!.options!) {
          _optionControllers.add(TextEditingController(text: option));
        }
      }
    } else {
      // Default: 4 options for multiple choice
      for (int i = 0; i < 4; i++) {
        _optionControllers.add(TextEditingController());
      }
    }
  }

  @override
  void dispose() {
    _questionTextController.dispose();
    _correctAnswerController.dispose();
    _explanationController.dispose();
    _pointsController.dispose();
    _displayOrderController.dispose();
    for (final controller in _optionControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _addOption() {
    setState(() {
      _optionControllers.add(TextEditingController());
    });
  }

  void _removeOption(int index) {
    if (_optionControllers.length > 2) {
      setState(() {
        _optionControllers[index].dispose();
        _optionControllers.removeAt(index);
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final repo = ref.read(enrichmentRepositoryProvider);

      // Prepare options for multiple choice
      List<String>? options;
      if (_questionType == QuizQuestionType.multipleChoice) {
        options = _optionControllers
            .map((c) => c.text.trim())
            .where((text) => text.isNotEmpty)
            .toList();
        if (options.length < 2) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Please provide at least 2 options'),
                backgroundColor: Colors.red,
              ),
            );
          }
          setState(() {
            _isSubmitting = false;
          });
          return;
        }
      }

      final questionData = {
        'quiz_id': widget.quizId,
        'question_type': _questionType.name
            .replaceAll(RegExp(r'(?<!^)(?=[A-Z])'), '_')
            .toLowerCase(),
        'question_text': _questionTextController.text.trim(),
        'options': options,
        'correct_answer': _correctAnswerController.text.trim(),
        'points': int.tryParse(_pointsController.text.trim()) ?? 1,
        'explanation': _explanationController.text.trim().isEmpty
            ? null
            : _explanationController.text.trim(),
        'display_order': int.tryParse(_displayOrderController.text.trim()) ?? 0,
      };

      if (widget.question != null) {
        // Update existing question
        await repo.updateQuizQuestion(widget.question!.id, questionData);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Question updated successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        // Create new question
        await repo.createQuizQuestion(questionData);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Question added successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }

      // Refresh questions list
      ref.invalidate(quizQuestionsProvider(widget.quizId));

      if (widget.onSaved != null) {
        widget.onSaved!();
      }

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
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
      appBar: AppBar(
        title: Text(widget.question == null ? 'Add Question' : 'Edit Question'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _isSubmitting ? null : _save,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<QuizQuestionType>(
                value: _questionType,
                decoration: const InputDecoration(
                  labelText: 'Question Type *',
                  border: OutlineInputBorder(),
                ),
                items: QuizQuestionType.values.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(_getQuestionTypeLabel(type)),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _questionType = value;
                      if (value == QuizQuestionType.multipleChoice &&
                          _optionControllers.length < 2) {
                        while (_optionControllers.length < 4) {
                          _optionControllers.add(TextEditingController());
                        }
                      }
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _questionTextController,
                decoration: const InputDecoration(
                  labelText: 'Question Text *',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter question text';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              if (_questionType == QuizQuestionType.multipleChoice) ...[
                Text(
                  'Options *',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                ...List.generate(_optionControllers.length, (index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _optionControllers[index],
                            decoration: InputDecoration(
                              labelText: 'Option ${index + 1}',
                              border: const OutlineInputBorder(),
                              prefixText:
                                  '${String.fromCharCode(65 + index)}. ',
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Required';
                              }
                              return null;
                            },
                          ),
                        ),
                        if (_optionControllers.length > 2)
                          IconButton(
                            icon: const Icon(Icons.remove_circle),
                            onPressed: () => _removeOption(index),
                            color: Colors.red,
                          ),
                      ],
                    ),
                  );
                }),
                ElevatedButton.icon(
                  onPressed: _addOption,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Option'),
                ),
                const SizedBox(height: 16),
              ],
              if (_questionType == QuizQuestionType.trueFalse) ...[
                Text(
                  'Correct Answer *',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                RadioListTile<String>(
                  title: const Text('True'),
                  value: 'True',
                  groupValue: _correctAnswerController.text,
                  onChanged: (value) {
                    setState(() {
                      _correctAnswerController.text = value!;
                    });
                  },
                ),
                RadioListTile<String>(
                  title: const Text('False'),
                  value: 'False',
                  groupValue: _correctAnswerController.text,
                  onChanged: (value) {
                    setState(() {
                      _correctAnswerController.text = value!;
                    });
                  },
                ),
                const SizedBox(height: 16),
              ],
              if (_questionType == QuizQuestionType.shortAnswer)
                TextFormField(
                  controller: _correctAnswerController,
                  decoration: const InputDecoration(
                    labelText: 'Correct Answer *',
                    border: OutlineInputBorder(),
                    helperText: 'Expected answer (case-insensitive)',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter correct answer';
                    }
                    return null;
                  },
                ),
              if (_questionType != QuizQuestionType.trueFalse &&
                  _questionType != QuizQuestionType.shortAnswer) ...[
                const SizedBox(height: 16),
                TextFormField(
                  controller: _correctAnswerController,
                  decoration: InputDecoration(
                    labelText: 'Correct Answer *',
                    border: const OutlineInputBorder(),
                    helperText: _questionType == QuizQuestionType.multipleChoice
                        ? 'Enter the option letter (A, B, C, etc.) or the exact option text'
                        : null,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter correct answer';
                    }
                    if (_questionType == QuizQuestionType.multipleChoice) {
                      // Validate that the answer matches one of the options
                      final options = _optionControllers
                          .map((c) => c.text.trim())
                          .where((text) => text.isNotEmpty)
                          .toList();
                      final answer = value.trim();
                      final matchesOption =
                          options.contains(answer) ||
                          (answer.length == 1 &&
                              answer.codeUnitAt(0) >= 65 &&
                              answer.codeUnitAt(0) < 65 + options.length);
                      if (!matchesOption) {
                        return 'Answer must match one of the options';
                      }
                    }
                    return null;
                  },
                ),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _pointsController,
                      decoration: const InputDecoration(
                        labelText: 'Points *',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Required';
                        }
                        final points = int.tryParse(value.trim());
                        if (points == null || points < 1) {
                          return 'Must be at least 1';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _displayOrderController,
                      decoration: const InputDecoration(
                        labelText: 'Display Order',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _explanationController,
                decoration: const InputDecoration(
                  labelText: 'Explanation (shown after submission)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _save,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          widget.question == null
                              ? 'Add Question'
                              : 'Update Question',
                        ),
                ),
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
