import 'package:flutter_test/flutter_test.dart';
import 'package:remath/src/features/learning/domain/arithmetic_question.dart';

void main() {
  test('each arithmetic skill exposes the learner-facing meaning', () {
    expect(
      ArithmeticOperation.values.map(
        (operation) =>
            (operation.skillId, operation.label, operation.fluentTarget),
      ),
      [
        ('arithmetic.addition', 'Addition', const Duration(seconds: 6)),
        ('arithmetic.subtraction', 'Subtraction', const Duration(seconds: 6)),
        (
          'arithmetic.multiplication',
          'Multiplication',
          const Duration(seconds: 8),
        ),
      ],
    );
  });

  test('stored skill identifiers restore their arithmetic operation', () {
    for (final operation in ArithmeticOperation.values) {
      expect(
        ArithmeticOperationDefinition.fromSkillId(operation.skillId),
        operation,
      );
    }
    expect(
      ArithmeticOperationDefinition.fromSkillId('arithmetic.division'),
      isNull,
    );
  });

  test('questions present and mark every supported operation', () {
    ArithmeticQuestion question(ArithmeticOperation operation) =>
        ArithmeticQuestion(
          index: 4,
          left: 12,
          operation: operation,
          packId: 'org.remath.foundation',
          right: 3,
          seed: 91,
          templateId: 'foundation.${operation.name}',
          templateVersion: 2,
        );

    expect(question(ArithmeticOperation.addition).prompt, '12 + 3');
    expect(question(ArithmeticOperation.addition).answer, 15);
    expect(question(ArithmeticOperation.subtraction).prompt, '12 − 3');
    expect(question(ArithmeticOperation.subtraction).answer, 9);
    expect(question(ArithmeticOperation.multiplication).prompt, '12 × 3');
    expect(question(ArithmeticOperation.multiplication).answer, 36);
  });

  test('question identity includes all reproducibility coordinates', () {
    const question = ArithmeticQuestion(
      index: 4,
      left: 12,
      operation: ArithmeticOperation.addition,
      packId: 'org.remath.foundation',
      right: 3,
      seed: 91,
      templateId: 'foundation.addition',
      templateVersion: 2,
    );

    expect(question.id, 'org.remath.foundation.foundation.addition.v2.91.4');
    expect(question.skillId, 'arithmetic.addition');
  });
}
