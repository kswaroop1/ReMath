import 'package:flutter_test/flutter_test.dart';
import 'package:remath/src/features/learning/domain/arithmetic_question.dart';
import 'package:remath/src/features/learning/domain/attempt_event.dart';
import 'package:remath/src/features/learning/domain/remediation_policy.dart';

void main() {
  const policy = RemediationPolicy(repeatedErrorThreshold: 2);

  test('one error does not prematurely prescribe remediation', () {
    expect(policy.recommend([_attempt('one')]), isNull);
  });

  test('repeated addition errors recommend focused addition rebuilding', () {
    final recommendation = policy.recommend([
      _attempt('one'),
      _attempt('two'),
    ]);

    expect(recommendation?.observedSkillId, 'arithmetic.addition');
    expect(recommendation?.recommendedSkillId, 'arithmetic.addition');
    expect(recommendation?.reason, contains('addition fundamentals'));
  });

  test('repeated subtraction errors identify addition as a prerequisite', () {
    final recommendation = policy.recommend([
      _attempt('one', operation: ArithmeticOperation.subtraction),
      _attempt('two', operation: ArithmeticOperation.subtraction),
    ]);

    expect(recommendation?.observedSkillId, 'arithmetic.subtraction');
    expect(recommendation?.recommendedSkillId, 'arithmetic.addition');
    expect(recommendation?.reason, contains('prerequisite'));
  });

  test('corrections and another operation do not create a recommendation', () {
    expect(
      policy.recommend([
        _attempt('addition-error'),
        _attempt('correction', kind: AttemptKind.correction),
        _attempt(
          'subtraction-error',
          operation: ArithmeticOperation.subtraction,
        ),
      ]),
      isNull,
    );
  });
}

AttemptEvent _attempt(
  String id, {
  AttemptKind kind = AttemptKind.answer,
  ArithmeticOperation operation = ArithmeticOperation.addition,
}) => AttemptEvent(
  answer: '999',
  eventId: id,
  isCorrect: false,
  kind: kind,
  occurredAt: DateTime.utc(2026, 8, 28),
  questionId: 'question-$id',
  responseTime: const Duration(seconds: 3),
  sessionId: 'session',
  skillId: operation.skillId,
);
