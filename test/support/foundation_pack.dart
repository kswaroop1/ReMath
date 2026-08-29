import 'package:remath/src/features/learning/domain/arithmetic_question.dart';
import 'package:remath/src/features/learning/domain/content_pack.dart';

ContentPack foundationPackForTest() => ContentPack(
  conceptCards: ArithmeticOperation.values
      .map(
        (operation) => ConceptCard(
          application: 'Use ${operation.label.toLowerCase()} in daily totals.',
          commonMistake: 'Use the operation shown.',
          formula: operation == ArithmeticOperation.addition
              ? 'a + b'
              : operation == ArithmeticOperation.subtraction
              ? 'a - b'
              : 'a × b',
          hints: HintLadder(
            conceptCue: 'Think about ${operation.label.toLowerCase()}.',
            methodCue: 'Choose a simple mental method.',
            nextStepCue: 'Work with one place value first.',
            workedSolution: 'Follow the worked ${operation.label} example.',
          ),
          id: 'card.arithmetic.${operation.name}.foundation',
          skillId: operation.skillId,
          summary: 'Build ${operation.label.toLowerCase()} fluency.',
          title: '${operation.label} foundations',
          workedExample: 'A short ${operation.label.toLowerCase()} example.',
        ),
      )
      .toList(growable: false),
  id: 'org.remath.foundation-arithmetic',
  license: 'CC-BY-SA-4.0',
  schemaVersion: 1,
  skills: ArithmeticOperation.values
      .map(
        (operation) =>
            SkillDefinition(id: operation.skillId, title: operation.label),
      )
      .toList(growable: false),
  templates: ArithmeticOperation.values
      .map(
        (operation) => ArithmeticTemplate(
          fluentTarget: operation.fluentTarget,
          id: 'foundation.arithmetic.${operation.name}-small',
          maximumOperand: 19,
          minimumOperand: 2,
          operation: operation,
          skillId: operation.skillId,
          version: 1,
        ),
      )
      .toList(growable: false),
  title: 'Foundation mental arithmetic',
  version: '1.0.0',
);
