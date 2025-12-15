import 'package:equatable/equatable.dart';

class AiTask extends Equatable {
  const AiTask({
    required this.id,
    required this.schoolId,
    required this.promptKey,
    required this.status,
    required this.input,
    this.userId,
    this.output,
    this.errorMessage,
    this.tokensUsed,
    this.cost,
    this.createdAt,
    this.startedAt,
    this.completedAt,
  });

  final String id;
  final String schoolId;
  final String promptKey;
  final String status;
  final Map<String, dynamic> input;
  final String? userId;
  final Map<String, dynamic>? output;
  final String? errorMessage;
  final int? tokensUsed;
  final double? cost;
  final DateTime? createdAt;
  final DateTime? startedAt;
  final DateTime? completedAt;

  factory AiTask.fromMap(Map<String, dynamic> map) {
    return AiTask(
      id: map['id'] as String,
      schoolId: map['school_id'] as String,
      promptKey: map['prompt_key'] as String,
      status: map['status'] as String,
      input: Map<String, dynamic>.from(map['input'] as Map),
      userId: map['user_id'] as String?,
      output: map['output'] != null
          ? Map<String, dynamic>.from(map['output'] as Map)
          : null,
      errorMessage: map['error_message'] as String?,
      tokensUsed: map['tokens_used'] as int?,
      cost: map['cost'] != null ? (map['cost'] as num).toDouble() : null,
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'] as String)
          : null,
      startedAt: map['started_at'] != null
          ? DateTime.tryParse(map['started_at'] as String)
          : null,
      completedAt: map['completed_at'] != null
          ? DateTime.tryParse(map['completed_at'] as String)
          : null,
    );
  }

  bool get isFinal => status == 'completed' || status == 'failed';

  @override
  List<Object?> get props => [
    id,
    schoolId,
    promptKey,
    status,
    input,
    userId,
    output,
    errorMessage,
    tokensUsed,
    cost,
    createdAt,
    startedAt,
    completedAt,
  ];
}
