import 'package:equatable/equatable.dart';

class AiPrompt extends Equatable {
  const AiPrompt({
    required this.id,
    required this.promptKey,
    required this.name,
    required this.promptYaml,
    this.description,
    this.version = 1,
  });

  final String id;
  final String promptKey;
  final String name;
  final String? description;
  final String promptYaml;
  final int version;

  factory AiPrompt.fromMap(Map<String, dynamic> map) {
    return AiPrompt(
      id: map['id'] as String,
      promptKey: map['prompt_key'] as String,
      name: map['name'] as String,
      description: map['description'] as String?,
      promptYaml: map['prompt_yaml'] as String,
      version: map['version'] as int? ?? 1,
    );
  }

  @override
  List<Object?> get props => [
    id,
    promptKey,
    name,
    description,
    promptYaml,
    version,
  ];
}
