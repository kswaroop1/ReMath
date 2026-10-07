import 'package:flutter_test/flutter_test.dart';
import 'package:remath/src/features/learning/domain/arithmetic_misconceptions.dart';
import 'package:remath/src/features/learning/domain/arithmetic_question.dart';

void main() {
  ArithmeticQuestion question(
    ArithmeticOperation operation, {
    int left = 8,
    int right = 3,
  }) {
    return ArithmeticQuestion(
      index: 0,
      left: left,
      operation: operation,
      packId: 'org.remath.foundation',
      right: right,
      seed: 1,
      templateId: 'test',
      templateVersion: 1,
    );
  }

  const classifier = ArithmeticMisconceptionClassifier();

  test('operation-confusion distractors carry stable misconception IDs', () {
    expect(
      classifier
          .distractorsFor(question(ArithmeticOperation.addition))
          .map((distractor) => (distractor.id, distractor.answer)),
      [(MisconceptionId.usedSubtraction, 5)],
    );
    expect(
      classifier
          .distractorsFor(question(ArithmeticOperation.subtraction))
          .map((distractor) => (distractor.id, distractor.answer)),
      [
        (MisconceptionId.usedAddition, 11),
        (MisconceptionId.reversedSubtraction, -5),
      ],
    );
    expect(
      classifier
          .distractorsFor(question(ArithmeticOperation.multiplication))
          .map((distractor) => (distractor.id, distractor.answer)),
      [(MisconceptionId.usedAddition, 11)],
    );
  });

  test('a matching wrong answer is classified for corrective feedback', () {
    final result = classifier.classify(
      question(ArithmeticOperation.subtraction),
      11,
    );

    expect(result?.id, MisconceptionId.usedAddition);
    expect(result?.stableId, 'arithmetic.used-addition');
    expect(
      classifier
          .classify(question(ArithmeticOperation.subtraction), -5)
          ?.stableId,
      'arithmetic.reversed-subtraction',
    );
  });

  test('correct, unknown and degenerate alternatives are not classified', () {
    final addition = question(ArithmeticOperation.addition);

    expect(classifier.classify(addition, addition.answer), isNull);
    expect(classifier.classify(addition, 999), isNull);
    expect(
      classifier.distractorsFor(
        question(ArithmeticOperation.addition, right: 0),
      ),
      isEmpty,
    );
  });

  test('distractors never duplicate the answer or one another', () {
    for (final operation in ArithmeticOperation.values) {
      for (var left = 0; left <= 12; left++) {
        for (var right = 0; right <= 12; right++) {
          final current = question(operation, left: left, right: right);
          final distractors = classifier.distractorsFor(current);
          final answers = distractors.map((distractor) => distractor.answer);

          expect(answers, isNot(contains(current.answer)));
          expect(answers.toSet(), hasLength(answers.length));
        }
      }
    }
  });
}
