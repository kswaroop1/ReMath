import 'package:flutter_test/flutter_test.dart';
import 'package:remath/src/features/learning/domain/numeric_answer_contract.dart';

void main() {
  const answer = ExactIntegerAnswer(12);

  test(
    'a learner is marked correct for the exact integer despite spacing',
    () {
      expect(answer.mark('12').verdict, AnswerVerdict.correct);
      expect(answer.mark('  12  ').verdict, AnswerVerdict.correct);
      expect(answer.mark('+12').verdict, AnswerVerdict.correct);
    },
  );

  test(
    'a different valid integer is marked incorrect rather than invalid',
    () {
      final result = answer.mark('-12');

      expect(result.verdict, AnswerVerdict.incorrect);
      expect(result.normalizedInput, '-12');
    },
  );

  test(
    'ambiguous or non-integer input is not treated as a wrong answer',
    () {
      for (final input in ['', '   ', '12.0', '1.2e1', '12 apples', '3/2']) {
        expect(
          answer.mark(input).verdict,
          AnswerVerdict.invalid,
          reason: input,
        );
      }
    },
  );

  test('the expected value remains available for correction feedback', () {
    expect(answer.expectedValue, 12);
    expect(answer.canonicalAnswer, '12');
  });
}
