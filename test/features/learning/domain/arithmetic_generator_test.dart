import 'package:flutter_test/flutter_test.dart';
import 'package:remath/src/features/learning/domain/arithmetic_generator.dart';
import 'package:remath/src/features/learning/domain/arithmetic_question.dart';

import '../../../support/foundation_pack.dart';

void main() {
  const generator = ArithmeticGenerator();
  final pack = foundationPackForTest();

  test('same identity always generates the same question', () {
    final template = pack.templateFor(ArithmeticOperation.addition);
    final first = generator.generate(
      seed: 42,
      index: 7,
      packId: pack.id,
      template: template,
    );
    final second = generator.generate(
      seed: 42,
      index: 7,
      packId: pack.id,
      template: template,
    );

    expect(second.id, first.id);
    expect(second.prompt, first.prompt);
    expect(second.answer, first.answer);
  });

  test('generated subtraction never has a negative answer', () {
    for (var seed = 0; seed < 100; seed++) {
      for (var index = 0; index < 20; index++) {
        final question = generator.generate(
          seed: seed,
          index: index,
          packId: pack.id,
          template: pack.templateFor(ArithmeticOperation.subtraction),
        );
        expect(question.answer, isNonNegative);
      }
    }
  });

  test('honours the skill selected by the scheduler', () {
    final question = generator.generate(
      seed: 42,
      index: 2,
      packId: pack.id,
      template: pack.templateFor(ArithmeticOperation.multiplication),
    );

    expect(question.operation, ArithmeticOperation.multiplication);
    expect(question.skillId, 'arithmetic.multiplication');
    expect(question.id, contains('.multiplication-small.v1.'));
  });

  test('rejects a negative question index', () {
    expect(
      () => generator.generate(
        seed: 1,
        index: -1,
        packId: pack.id,
        template: pack.templateFor(ArithmeticOperation.addition),
      ),
      throwsArgumentError,
    );
  });
}
