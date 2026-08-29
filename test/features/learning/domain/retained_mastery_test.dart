import 'package:flutter_test/flutter_test.dart';
import 'package:remath/src/features/learning/domain/arithmetic_question.dart';
import 'package:remath/src/features/learning/domain/attempt_event.dart';
import 'package:remath/src/features/learning/domain/retained_mastery.dart';

void main() {
  const calculator = RetainedMasteryCalculator();
  final start = DateTime.utc(2026, 8, 29, 8);

  AttemptEvent attempt({
    required String id,
    required DateTime at,
    required bool correct,
    String skillId = 'arithmetic.addition',
    AttemptKind kind = AttemptKind.answer,
  }) => AttemptEvent(
    answer: correct ? '5' : '4',
    eventId: id,
    isCorrect: correct,
    kind: kind,
    occurredAt: at,
    questionId: 'question-$id',
    responseTime: const Duration(seconds: 3),
    sessionId: 'session-$id',
    skillId: skillId,
  );

  test('immediate repetition cannot masquerade as retained mastery', () {
    final result = calculator.forSkill(
      ArithmeticOperation.addition.skillId,
      [
        attempt(id: 'first', at: start, correct: true),
        attempt(
          id: 'immediate-1',
          at: start.add(const Duration(minutes: 5)),
          correct: true,
        ),
        attempt(
          id: 'immediate-2',
          at: start.add(const Duration(minutes: 10)),
          correct: true,
        ),
      ],
      now: start.add(const Duration(minutes: 10)),
    );

    expect(result.successfulOccasions, 1);
    expect(result.state, RetainedMasteryState.learning);
    expect(result.nextReviewAt, start.add(const Duration(hours: 1)));
    expect(result.reason, contains('delayed'));
  });

  test('three successful delayed occasions confirm retained mastery', () {
    final second = start.add(const Duration(hours: 1));
    final third = second.add(const Duration(days: 1));
    final result = calculator.forSkill(
      ArithmeticOperation.addition.skillId,
      [
        attempt(id: 'first', at: start, correct: true),
        attempt(id: 'second', at: second, correct: true),
        attempt(id: 'third', at: third, correct: true),
      ],
      now: third,
    );

    expect(result.successfulOccasions, 3);
    expect(result.state, RetainedMasteryState.retained);
    expect(result.nextReviewAt, third.add(const Duration(days: 3)));
    expect(result.isDue, isFalse);
  });

  test('a later failure records a lapse and becomes immediately due', () {
    final second = start.add(const Duration(hours: 1));
    final third = second.add(const Duration(days: 1));
    final lapse = third.add(const Duration(days: 3));
    final result = calculator.forSkill(
      ArithmeticOperation.addition.skillId,
      [
        attempt(id: 'first', at: start, correct: true),
        attempt(id: 'second', at: second, correct: true),
        attempt(id: 'third', at: third, correct: true),
        attempt(id: 'lapse', at: lapse, correct: false),
      ],
      now: lapse,
    );

    expect(result.state, RetainedMasteryState.lapsed);
    expect(result.successfulOccasions, 0);
    expect(result.nextReviewAt, lapse);
    expect(result.isDue, isTrue);
    expect(result.reason, contains('lapse'));
  });

  test('coached corrections and hints never confirm independent retention', () {
    final due = start.add(const Duration(hours: 1));
    final result = calculator.forSkill(
      ArithmeticOperation.addition.skillId,
      [
        attempt(id: 'first', at: start, correct: true),
        attempt(
          id: 'hint',
          at: due,
          correct: false,
          kind: AttemptKind.hint,
        ),
        attempt(
          id: 'correction',
          at: due,
          correct: true,
          kind: AttemptKind.correction,
        ),
        attempt(
          id: 'retest',
          at: due,
          correct: true,
          kind: AttemptKind.retest,
        ),
      ],
      now: due,
    );

    expect(result.successfulOccasions, 2);
  });

  test('review queue prioritises overdue work before approaching review', () {
    final now = start.add(const Duration(days: 4));
    final recommendations = calculator.recommendReviews(
      [
        attempt(id: 'addition', at: start, correct: true),
        attempt(
          id: 'subtraction',
          skillId: ArithmeticOperation.subtraction.skillId,
          at: now.subtract(const Duration(minutes: 30)),
          correct: true,
        ),
      ],
      now: now,
    );

    expect(recommendations.map((item) => item.skillId), [
      ArithmeticOperation.addition.skillId,
      ArithmeticOperation.subtraction.skillId,
    ]);
    expect(recommendations.first.priority, ReviewPriority.overdue);
    expect(recommendations.last.priority, ReviewPriority.approaching);
    expect(recommendations.first.reason, contains('overdue'));
  });
}
