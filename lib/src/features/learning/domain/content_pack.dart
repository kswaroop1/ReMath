import 'arithmetic_question.dart';

enum HintLevel { concept, method, nextStep, workedSolution }

final class RevealedHint {
  const RevealedHint({required this.level, required this.text});

  final HintLevel level;
  final String text;
}

final class HintLadder {
  const HintLadder({
    required this.conceptCue,
    required this.methodCue,
    required this.nextStepCue,
    required this.workedSolution,
  });

  final String conceptCue;
  final String methodCue;
  final String nextStepCue;
  final String workedSolution;

  RevealedHint reveal(HintLevel level) => RevealedHint(
    level: level,
    text: switch (level) {
      HintLevel.concept => conceptCue,
      HintLevel.method => methodCue,
      HintLevel.nextStep => nextStepCue,
      HintLevel.workedSolution => workedSolution,
    },
  );
}

final class ConceptCard {
  const ConceptCard({
    required this.application,
    required this.commonMistake,
    required this.formula,
    required this.hints,
    required this.id,
    required this.skillId,
    required this.summary,
    required this.title,
    required this.workedExample,
    this.externalLinks = const [],
  });

  final String application;
  final String commonMistake;
  final List<String> externalLinks;
  final String formula;
  final HintLadder hints;
  final String id;
  final String skillId;
  final String summary;
  final String title;
  final String workedExample;
}

final class SkillDefinition {
  const SkillDefinition({
    required this.id,
    required this.title,
    this.prerequisiteIds = const [],
  });

  final String id;
  final List<String> prerequisiteIds;
  final String title;
}

final class LearningGoal {
  const LearningGoal({
    required this.id,
    required this.skillIds,
    required this.title,
  });

  final String id;
  final List<String> skillIds;
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
    this.conceptCards = const [],
    this.goals = const [],
    required this.id,
    required this.license,
    required this.schemaVersion,
    required this.skills,
    required this.templates,
    required this.title,
    required this.version,
  });

  final List<ConceptCard> conceptCards;
  final List<LearningGoal> goals;
  final String id;
  final String license;
  final int schemaVersion;
  final List<SkillDefinition> skills;
  final List<ArithmeticTemplate> templates;
  final String title;
  final String version;

  ArithmeticTemplate templateFor(ArithmeticOperation operation) =>
      templates.firstWhere((template) => template.operation == operation);

  ConceptCard conceptCardFor(String skillId) =>
      conceptCards.firstWhere((card) => card.skillId == skillId);
}

abstract interface class ContentPackRepository {
  Future<ContentPack> loadFoundationPack();
}
