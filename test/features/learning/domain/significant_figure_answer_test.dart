import 'package:flutter_test/flutter_test.dart';
import 'package:remath/src/features/learning/domain/numeric_answer_contract.dart';

void main() {
  final answer = SignificantFigureAnswer(
    expectedValue: '1234',
    significantFigures: 3,
  );

  test('equivalent answers expressed to the requested precision are correct', () {
    for (final input in ['1230', '1.23e3', '+1230']) {
      final result = answer.mark(input);

      expect(result.verdict, AnswerVerdict.correct, reason: input);
      expect(result.normalizedInput, '1230', reason: input);
    }
  });

  test('a numerically close answer with the wrong precision is incorrect', () {
    for (final input in ['1234', '1.230e3', '1.2e3']) {
      expect(answer.mark(input).verdict, AnswerVerdict.incorrect, reason: input);
    }
  });

  test('a correctly formatted but numerically wrong answer is incorrect', () {
    final result = answer.mark('1240');

    expect(result.verdict, AnswerVerdict.incorrect);
    expect(result.normalizedInput, '1240');
  });

  test('leading zeros do not count as significant figures', () {
    final small = SignificantFigureAnswer(
      expectedValue: '0.01234',
      significantFigures: 3,
    );

    expect(small.canonicalAnswer, '0.0123');
    expect(small.mark('0.0123').verdict, AnswerVerdict.correct);
    expect(small.mark('0.01230').verdict, AnswerVerdict.incorrect);
  });

  test('zero can be expressed to an explicit requested precision', () {
    final zero = SignificantFigureAnswer(
      expectedValue: '0',
      significantFigures: 3,
    );

    expect(zero.canonicalAnswer, '0.00');
    expect(zero.mark('0.00').verdict, AnswerVerdict.correct);
    expect(zero.mark('0').verdict, AnswerVerdict.incorrect);
  });

  test('invalid learner input remains invalid', () {
    for (final input in ['', '1/3', 'NaN', 'about 1230']) {
      expect(answer.mark(input).verdict, AnswerVerdict.invalid, reason: input);
    }
  });

  test('content requires a finite expected value and positive precision', () {
    expect(
      () => SignificantFigureAnswer(
        expectedValue: 'many',
        significantFigures: 3,
      ),
      throwsArgumentError,
    );
    expect(
      () => SignificantFigureAnswer(
        expectedValue: '1',
        significantFigures: 0,
      ),
      throwsArgumentError,
    );
  });
}
