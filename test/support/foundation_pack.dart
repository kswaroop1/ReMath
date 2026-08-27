import 'package:remath/src/features/learning/domain/arithmetic_question.dart';
import 'package:remath/src/features/learning/domain/content_pack.dart';

ContentPack foundationPackForTest() => ContentPack(
  id: 'org.remath.foundation-arithmetic',
  license: 'CC-BY-SA-4.0',
  schemaVersion: 1,
  skills: ArithmeticOperation.values
      .map(
        (operation) => SkillDefinition(
          id: operation.skillId,
          title: operation.label,
        ),
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
