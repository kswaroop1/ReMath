import 'package:flutter_test/flutter_test.dart';
import 'package:remath/src/features/learning/domain/arithmetic_generator.dart';
import 'package:remath/src/features/learning/domain/arithmetic_question.dart';
import 'package:remath/src/features/learning/domain/numeric_answer_contract.dart';

import '../../../support/foundation_pack.dart';

void main() {
  const generator = ArithmeticGenerator();
  final pack = foundationPackForTest();

  test('seeded arithmetic generation preserves every learner-facing invariant', () {
    final identities = <String>{};

    for (final operation in ArithmeticOperation.values) {
      final template = pack.templateFor(operation);
      for (var seed = 0; seed < 200; seed++) {
        for (var index = 0; index < 50; index++) {
          final question = generator.generate(
            seed: seed,
            index: index,
            packId: pack.id,
            template: template,
          );
          final replay = generator.generate(
            seed: seed,
            index: index,
            packId: pack.id,
            template: template,
          );

          expect(question.left, inInclusiveRange(0, template.maximumOperand));
          expect(question.right, inInclusiveRange(0, template.maximumOperand));
          expect(question.left, greaterThanOrEqualTo(template.minimumOperand));
          expect(question.right, greaterThanOrEqualTo(template.minimumOperand));
          expect(identities.add(question.id), isTrue, reason: question.id);
          expect(replay.prompt, question.prompt, reason: question.id);
          expect(replay.answer, question.answer, reason: question.id);

          final answer = ExactIntegerAnswer(question.answer);
          expect(
            answer.mark(question.answer.toString()).verdict,
            AnswerVerdict.correct,
            reason: question.id,
          );
          expect(
            answer.mark((question.answer + 1).toString()).verdict,
            AnswerVerdict.incorrect,
            reason: question.id,
          );

          if (operation == ArithmeticOperation.subtraction) {
            expect(question.answer, isNonNegative, reason: question.id);
          }
        }
      }
    }

    expect(identities, hasLength(30000));
  });
}
