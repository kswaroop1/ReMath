import 'package:flutter_test/flutter_test.dart';
import 'package:remath/src/features/learning/domain/arithmetic_question.dart';
import 'package:remath/src/features/learning/domain/attempt_event.dart';
import 'package:remath/src/features/learning/domain/progress_dashboard.dart';
import 'package:remath/src/features/learning/domain/retained_mastery.dart';

void main() {
  const calculator = ProgressDashboardCalculator();
  final start = DateTime.utc(2026, 8, 29, 8);

  AttemptEvent attempt({
    required String id,
    required DateTime at,
    required bool correct,
    AttemptKind kind = AttemptKind.answer,
    Duration responseTime = const Duration(seconds: 3),
    String skillId = 'arithmetic.addition',
  }) => AttemptEvent(
    answer: correct ? '5' : '4',
    eventId: id,
    isCorrect: correct,
    kind: kind,
    occurredAt: at,
    questionId: 'question-$id',
    responseTime: responseTime,
    sessionId: 'session-$id',
    skillId: skillId,
  );

  test('empty progress is honest about having no mastery evidence', () {
    final dashboard = calculator.calculate(const [], now: start);
    final addition = dashboard.skills.singleWhere(
      (skill) => skill.skillId == ArithmeticOperation.addition.skillId,
    );

    expect(dashboard.totalTime, Duration.zero);
    expect(dashboard.independentAttempts, 0);
    expect(dashboard.assistedEvents, 0);
    expect(addition.independentAccuracy, isNull);
    expect(addition.knowledgeMastery, isNull);
    expect(addition.performanceMastery, isNull);
    expect(addition.forgettingRisk, isNull);
    expect(addition.retentionState, RetainedMasteryState.unattempted);
    expect(addition.history, isEmpty);
  });

  test('assistance remains visible without inflating independent mastery', () {
    final events = [
      attempt(id: 'wrong', at: start, correct: false),
      attempt(
        id: 'hint',
        at: start.add(const Duration(seconds: 10)),
        correct: false,
        kind: AttemptKind.hint,
      ),
      attempt(
        id: 'correction',
        at: start.add(const Duration(seconds: 20)),
        correct: true,
        kind: AttemptKind.correction,
      ),
    ];

    final dashboard = calculator.calculate(events, now: events.last.occurredAt);
    final addition = dashboard.skills.first;

    expect(dashboard.independentAttempts, 1);
    expect(dashboard.assistedEvents, 2);
    expect(addition.independentAccuracy, 0);
    expect(addition.knowledgeMastery, 0);
    expect(addition.performanceMastery, 0);
    expect(addition.history.map((entry) => entry.eventId), [
      'correction',
      'hint',
      'wrong',
    ]);
    expect(addition.history.first.impact, ProgressImpact.assisted);
    expect(addition.history.first.explanation, contains('does not raise'));
    expect(addition.history.last.impact, ProgressImpact.reduced);
  });

  test('delayed accurate fluent work builds both forms of mastery', () {
    final second = start.add(const Duration(hours: 1));
    final third = second.add(const Duration(days: 1));
    final events = [
      attempt(id: 'first', at: start, correct: true),
      attempt(id: 'second', at: second, correct: true),
      attempt(id: 'third', at: third, correct: true),
    ];

    final addition = calculator.calculate(events, now: third).skills.first;

    expect(addition.independentAttempts, 3);
    expect(addition.independentAccuracy, 1);
    expect(addition.knowledgeMastery, 1);
    expect(addition.performanceMastery, 1);
    expect(addition.retentionState, RetainedMasteryState.retained);
    expect(addition.successfulOccasions, 3);
    expect(addition.history.first.title, 'Fluent retest');
    expect(addition.history.first.explanation, contains('retention'));
  });

  test('slow correct work shows knowledge separately from performance', () {
    final addition = calculator
        .calculate([
          attempt(
            id: 'slow',
            at: start,
            correct: true,
            responseTime: const Duration(seconds: 12),
          ),
        ], now: start)
        .skills
        .first;

    expect(addition.knowledgeMastery, closeTo(0.7667, 0.001));
    expect(addition.performanceMastery, 0.6);
    expect(addition.history.single.title, 'Correct but still building speed');
  });

  test('forgetting risk rises toward review and caps when overdue', () {
    final event = attempt(id: 'first', at: start, correct: true);

    final early = calculator
        .calculate([event], now: start.add(const Duration(minutes: 15)))
        .skills
        .first;
    final late = calculator
        .calculate([event], now: start.add(const Duration(minutes: 45)))
        .skills
        .first;
    final overdue = calculator
        .calculate([event], now: start.add(const Duration(hours: 2)))
        .skills
        .first;

    expect(early.forgettingRisk, 0.25);
    expect(late.forgettingRisk, 0.75);
    expect(overdue.forgettingRisk, 1);
    expect(overdue.reviewExplanation, contains('overdue'));
  });

  test('a lapse is shown as the latest reason mastery fell', () {
    final second = start.add(const Duration(hours: 1));
    final lapse = second.add(const Duration(days: 1));
    final events = [
      attempt(id: 'first', at: start, correct: true),
      attempt(id: 'second', at: second, correct: true),
      attempt(id: 'lapse', at: lapse, correct: false),
    ];

    final addition = calculator.calculate(events, now: lapse).skills.first;

    expect(addition.retentionState, RetainedMasteryState.lapsed);
    expect(addition.forgettingRisk, 1);
    expect(addition.history.first.title, 'Independent answer needs review');
    expect(addition.history.first.explanation, contains('lowered'));
    expect(addition.history.first.impact, ProgressImpact.reduced);
  });

  test('history ordering is deterministic when event times match', () {
    final dashboard = calculator.calculate([
      attempt(id: 'b', at: start, correct: true),
      attempt(id: 'a', at: start, correct: true, kind: AttemptKind.retest),
    ], now: start);

    expect(dashboard.skills.first.history.map((entry) => entry.eventId), [
      'b',
      'a',
    ]);
  });
}
