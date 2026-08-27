import 'package:flutter_test/flutter_test.dart';
import 'package:remath/src/features/learning/domain/arithmetic_generator.dart';
import 'package:remath/src/features/learning/domain/arithmetic_question.dart';

void main() {
  const generator = ArithmeticGenerator();

  test('same identity always generates the same question', () {
    final first = generator.generate(seed: 42, index: 7);
    final second = generator.generate(seed: 42, index: 7);

    expect(second.id, first.id);
    expect(second.prompt, first.prompt);
    expect(second.answer, first.answer);
  });

  test('generated subtraction never has a negative answer', () {
    for (var seed = 0; seed < 100; seed++) {
      for (var index = 0; index < 20; index++) {
        final question = generator.generate(seed: seed, index: index);
        if (question.operation == ArithmeticOperation.subtraction) {
          expect(question.answer, isNonNegative);
        }
      }
    }
  });

  test('honours the skill selected by the scheduler', () {
    final question = generator.generate(
      seed: 42,
      index: 2,
      operation: ArithmeticOperation.multiplication,
    );

    expect(question.operation, ArithmeticOperation.multiplication);
    expect(question.skillId, 'arithmetic.multiplication');
    expect(question.id, contains('.v2.multiplication.'));
  });

  test('rejects a negative question index', () {
    expect(() => generator.generate(seed: 1, index: -1), throwsArgumentError);
  });
}
