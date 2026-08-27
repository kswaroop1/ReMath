import 'package:flutter_test/flutter_test.dart';
import 'package:remath/src/features/learning/domain/arithmetic_question.dart';
import 'package:remath/src/features/learning/domain/attempt_event.dart';
import 'package:remath/src/features/learning/domain/fluency.dart';

void main() {
  const calculator = FluencyCalculator();
  const scheduler = ArithmeticScheduler();
  final now = DateTime.utc(2026, 8, 27, 8);

  AttemptEvent attempt({
    required String id,
    required ArithmeticOperation operation,
    required bool correct,
    required Duration responseTime,
    DateTime? occurredAt,
  }) => AttemptEvent(
    answer: '1',
    eventId: id,
    isCorrect: correct,
    occurredAt: occurredAt ?? now,
    questionId: 'question-$id',
    responseTime: responseTime,
    sessionId: 'session',
    skillId: operation.skillId,
  );

  test('classifies incorrect, slow, and fluent attempts', () {
    expect(
      AttemptAssessment.fromEvent(
        attempt(
          id: 'incorrect',
          operation: ArithmeticOperation.addition,
          correct: false,
          responseTime: const Duration(seconds: 2),
        ),
      ).pace,
      AttemptPace.incorrect,
    );
    expect(
      AttemptAssessment.fromEvent(
        attempt(
          id: 'slow',
          operation: ArithmeticOperation.addition,
          correct: true,
          responseTime: const Duration(seconds: 7),
        ),
      ).pace,
      AttemptPace.slow,
    );
    expect(
      AttemptAssessment.fromEvent(
        attempt(
          id: 'fluent',
          operation: ArithmeticOperation.multiplication,
          correct: true,
          responseTime: const Duration(seconds: 8),
        ),
      ).pace,
      AttemptPace.fluent,
    );
  });

  test('recent evidence updates per-skill fluency', () {
    final fluency = calculator.calculate([
      attempt(
        id: 'wrong',
        operation: ArithmeticOperation.addition,
        correct: false,
        responseTime: const Duration(seconds: 3),
      ),
      attempt(
        id: 'right',
        operation: ArithmeticOperation.addition,
        correct: true,
        responseTime: const Duration(seconds: 3),
        occurredAt: now.add(const Duration(minutes: 1)),
      ),
    ]);
    final addition = fluency.singleWhere(
      (skill) => skill.operation == ArithmeticOperation.addition,
    );

    expect(addition.attempts, 2);
    expect(addition.fluentAttempts, 1);
    expect(addition.score, closeTo(0.3, 0.0001));
    expect(addition.nextReviewAt, now.add(const Duration(hours: 1, minutes: 1)));
  });

  test('scheduler introduces unattempted skills before weakest review', () {
    var fluency = calculator.calculate(const []);
    expect(
      scheduler.choose(fluency: fluency, now: now),
      ArithmeticOperation.addition,
    );

    fluency = calculator.calculate([
      attempt(
        id: 'addition',
        operation: ArithmeticOperation.addition,
        correct: true,
        responseTime: const Duration(seconds: 2),
      ),
    ]);
    expect(
      scheduler.choose(fluency: fluency, now: now),
      ArithmeticOperation.subtraction,
    );
  });
}
