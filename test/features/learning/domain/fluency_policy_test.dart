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
    required String skillId,
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
    skillId: skillId,
  );

  test('unknown skills use the conservative eight-second fluency target', () {
    expect(
      AttemptAssessment.fromEvent(
        attempt(
          id: 'unknown',
          skillId: 'future.skill',
          correct: true,
          responseTime: const Duration(seconds: 8),
        ),
      ).pace,
      AttemptPace.fluent,
    );
    expect(
      AttemptAssessment.fromEvent(
        attempt(
          id: 'unknown-slow',
          skillId: 'future.skill',
          correct: true,
          responseTime: const Duration(milliseconds: 8001),
        ),
      ).pace,
      AttemptPace.slow,
    );
  });

  test(
    'incorrect work is immediately due and slow work returns in five minutes',
    () {
      final incorrect = calculator.calculate([
        attempt(
          id: 'wrong',
          skillId: ArithmeticOperation.addition.skillId,
          correct: false,
          responseTime: const Duration(seconds: 2),
        ),
      ]).first;
      expect(incorrect.score, 0);
      expect(incorrect.nextReviewAt, now);

      final slow = calculator.calculate([
        attempt(
          id: 'slow',
          skillId: ArithmeticOperation.addition.skillId,
          correct: true,
          responseTime: const Duration(seconds: 7),
        ),
      ]).first;
      expect(slow.score, 0.6);
      expect(slow.nextReviewAt, now.add(const Duration(minutes: 5)));
    },
  );

  test(
    'fluent recall expands review intervals through the retention ceiling',
    () {
      final events = List.generate(
        5,
        (index) => attempt(
          id: 'fluent-$index',
          skillId: ArithmeticOperation.addition.skillId,
          correct: true,
          responseTime: const Duration(seconds: 2),
          occurredAt: now.add(Duration(minutes: index)),
        ),
      );

      final expectedIntervals = [
        const Duration(hours: 1),
        const Duration(days: 1),
        const Duration(days: 3),
        const Duration(days: 7),
        const Duration(days: 7),
      ];
      for (var length = 1; length <= events.length; length++) {
        final addition = calculator.calculate(events.take(length)).first;
        expect(addition.fluentAttempts, length);
        expect(
          addition.nextReviewAt,
          events[length - 1].occurredAt.add(expectedIntervals[length - 1]),
        );
      }
    },
  );

  test('an error resets a fluent streak before relearning', () {
    final addition = calculator.calculate([
      attempt(
        id: 'fluent-1',
        skillId: ArithmeticOperation.addition.skillId,
        correct: true,
        responseTime: const Duration(seconds: 2),
      ),
      attempt(
        id: 'wrong',
        skillId: ArithmeticOperation.addition.skillId,
        correct: false,
        responseTime: const Duration(seconds: 2),
        occurredAt: now.add(const Duration(minutes: 1)),
      ),
      attempt(
        id: 'fluent-again',
        skillId: ArithmeticOperation.addition.skillId,
        correct: true,
        responseTime: const Duration(seconds: 2),
        occurredAt: now.add(const Duration(minutes: 2)),
      ),
    ]).first;

    expect(
      addition.nextReviewAt,
      now.add(const Duration(hours: 1, minutes: 2)),
    );
  });

  test(
    'scheduler chooses due weakest work and otherwise the weakest future work',
    () {
      SkillFluency skill(
        ArithmeticOperation operation, {
        required double score,
        required DateTime review,
      }) => SkillFluency(
        attempts: 1,
        fluentAttempts: 1,
        nextReviewAt: review,
        operation: operation,
        score: score,
      );

      final fluency = [
        skill(
          ArithmeticOperation.addition,
          score: 0.8,
          review: now.subtract(const Duration(minutes: 1)),
        ),
        skill(
          ArithmeticOperation.subtraction,
          score: 0.2,
          review: now.add(const Duration(hours: 1)),
        ),
        skill(ArithmeticOperation.multiplication, score: 0.5, review: now),
      ];
      expect(
        scheduler.choose(fluency: fluency, now: now),
        ArithmeticOperation.multiplication,
      );

      final future = fluency
          .map(
            (value) => SkillFluency(
              attempts: value.attempts,
              fluentAttempts: value.fluentAttempts,
              nextReviewAt: now.add(const Duration(days: 1)),
              operation: value.operation,
              score: value.score,
            ),
          )
          .toList();
      expect(
        scheduler.choose(fluency: future, now: now),
        ArithmeticOperation.subtraction,
      );
    },
  );

  test('equal scores retain deterministic curriculum order', () {
    final fluency = ArithmeticOperation.values
        .map(
          (operation) => SkillFluency(
            attempts: 1,
            fluentAttempts: 0,
            nextReviewAt: null,
            operation: operation,
            score: 0.5,
          ),
        )
        .toList();

    expect(
      scheduler.choose(fluency: fluency, now: now),
      ArithmeticOperation.addition,
    );
  });
}
