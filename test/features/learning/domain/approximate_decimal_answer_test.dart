import 'package:flutter_test/flutter_test.dart';
import 'package:remath/src/features/learning/domain/numeric_answer_contract.dart';

void main() {
  final answer = ApproximateDecimalAnswer(
    expectedValue: '10',
    absoluteTolerance: '0.05',
  );

  test('answers within the stated absolute tolerance are correct', () {
    for (final input in ['10', '9.95', '10.05', '1.004e1']) {
      expect(answer.mark(input).verdict, AnswerVerdict.correct, reason: input);
    }
  });

  test('correction feedback exposes the expected value and tolerance', () {
    expect(answer.canonicalAnswer, '10');
    expect(answer.absoluteTolerance, '0.05');
  });

  test('an answer outside the tolerance is incorrect rather than invalid', () {
    final result = answer.mark('10.051');

    expect(result.verdict, AnswerVerdict.incorrect);
    expect(result.normalizedInput, '10.051');
  });

  test('a zero tolerance requires exact equality', () {
    final exact = ApproximateDecimalAnswer(
      expectedValue: '0.3',
      absoluteTolerance: '0',
    );

    expect(exact.mark('0.300').verdict, AnswerVerdict.correct);
    expect(exact.mark('0.3001').verdict, AnswerVerdict.incorrect);
  });

  test('non-decimal learner input remains invalid', () {
    for (final input in ['', '1/2', 'NaN', '10 units']) {
      expect(answer.mark(input).verdict, AnswerVerdict.invalid, reason: input);
    }
  });

  test('content must provide valid values and a non-negative tolerance', () {
    expect(
      () => ApproximateDecimalAnswer(
        expectedValue: 'ten',
        absoluteTolerance: '0.1',
      ),
      throwsArgumentError,
    );
    expect(
      () => ApproximateDecimalAnswer(
        expectedValue: '10',
        absoluteTolerance: '-0.1',
      ),
      throwsArgumentError,
    );
    expect(
      () => ApproximateDecimalAnswer(
        expectedValue: '10',
        absoluteTolerance: 'small',
      ),
      throwsArgumentError,
    );
  });
}
