import 'package:flutter_test/flutter_test.dart';
import 'package:remath/src/features/learning/domain/numeric_answer_contract.dart';

void main() {
  final answer = ExactDecimalAnswer('1.25');

  test('equivalent decimal notation is marked correct', () {
    for (final input in ['1.25', '1.250', '+1.25', '0.125e1', ' 125e-2 ']) {
      final result = answer.mark(input);

      expect(result.verdict, AnswerVerdict.correct, reason: input);
      expect(result.normalizedInput, '1.25', reason: input);
    }
  });

  test('a different valid decimal is incorrect rather than invalid', () {
    final result = answer.mark('1.24');

    expect(result.verdict, AnswerVerdict.incorrect);
    expect(result.normalizedInput, '1.24');
  });

  test('zero and negative decimal answers normalize canonically', () {
    final zero = ExactDecimalAnswer('-0.000');
    final negative = ExactDecimalAnswer('-0.50');

    expect(zero.canonicalAnswer, '0');
    expect(zero.mark('0e20').verdict, AnswerVerdict.correct);
    expect(negative.canonicalAnswer, '-0.5');
    expect(negative.mark('-.5').verdict, AnswerVerdict.correct);
  });

  test('ambiguous or non-decimal learner input is invalid', () {
    for (final input in ['', '.', '1/4', '1.2.3', 'NaN', 'Infinity', '1.25 metres']) {
      expect(answer.mark(input).verdict, AnswerVerdict.invalid, reason: input);
    }
  });

  test('an invalid expected decimal is rejected when content is loaded', () {
    for (final expected in ['', '1/4', 'NaN', 'Infinity']) {
      expect(() => ExactDecimalAnswer(expected), throwsArgumentError);
    }
  });
}
