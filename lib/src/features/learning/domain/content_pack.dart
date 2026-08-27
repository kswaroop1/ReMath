import 'arithmetic_question.dart';

final class SkillDefinition {
  const SkillDefinition({required this.id, required this.title});

  final String id;
  final String title;
}

final class ArithmeticTemplate {
  const ArithmeticTemplate({
    required this.fluentTarget,
    required this.id,
    required this.maximumOperand,
    required this.minimumOperand,
    required this.operation,
    required this.skillId,
    required this.version,
  });

  final Duration fluentTarget;
  final String id;
  final int maximumOperand;
  final int minimumOperand;
  final ArithmeticOperation operation;
  final String skillId;
  final int version;
}

final class ContentPack {
  const ContentPack({
    required this.id,
    required this.license,
    required this.schemaVersion,
    required this.skills,
    required this.templates,
    required this.title,
    required this.version,
  });

  final String id;
  final String license;
  final int schemaVersion;
  final List<SkillDefinition> skills;
  final List<ArithmeticTemplate> templates;
  final String title;
  final String version;

  ArithmeticTemplate templateFor(ArithmeticOperation operation) =>
      templates.firstWhere((template) => template.operation == operation);
}

abstract interface class ContentPackRepository {
  Future<ContentPack> loadFoundationPack();
}
