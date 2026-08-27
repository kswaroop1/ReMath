import 'package:flutter_test/flutter_test.dart';
import 'package:remath/src/features/learning/domain/numeric_answer_contract.dart';

void main() {
  const answer = ExactFractionAnswer(numerator: 1, denominator: 2);

  test('equivalent fractions are marked correct and reduced canonically', () {
    for (final input in ['1/2', '2/4', '-3/-6', ' 4 / 8 ']) {
      final result = answer.mark(input);
      expect(result.verdict, AnswerVerdict.correct, reason: input);
      expect(result.normalizedInput, '1/2', reason: input);
    }
  });

  test('a valid non-equivalent fraction is marked incorrect', () {
    final result = answer.mark('6/8');

    expect(result.verdict, AnswerVerdict.incorrect);
    expect(result.normalizedInput, '3/4');
  });

  test('undefined or non-fraction input is invalid rather than incorrect', () {
    for (final input in ['', '0/0', '1/0', '0.5', '1 1/2', 'half']) {
      expect(answer.mark(input).verdict, AnswerVerdict.invalid, reason: input);
    }
  });

  test('expected fractions normalize sign and reject a zero denominator', () {
    const negative = ExactFractionAnswer(numerator: 1, denominator: -2);

    expect(negative.canonicalAnswer, '-1/2');
    expect(
      () => ExactFractionAnswer(numerator: 1, denominator: 0),
      throwsArgumentError,
    );
  });
}
