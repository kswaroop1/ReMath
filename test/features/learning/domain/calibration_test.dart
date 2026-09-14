import 'package:flutter_test/flutter_test.dart';
import 'package:remath/src/features/learning/domain/attempt_event.dart';
import 'package:remath/src/features/learning/domain/calibration.dart';

void main() {
  final at = DateTime.utc(2026, 9, 12);
  AttemptEvent event(
    String id, {
    required bool correct,
    ConfidenceRating? confidence,
    SurpriseRating? surprise,
    AttemptKind kind = AttemptKind.answer,
  }) => AttemptEvent(
    answer: '1',
    eventId: id,
    isCorrect: correct,
    occurredAt: at,
    questionId: 'q-$id',
    responseTime: const Duration(seconds: 1),
    sessionId: 's',
    skillId: 'arithmetic.addition',
    confidence: confidence,
    surprise: surprise,
    kind: kind,
  );

  test('calibration distinguishes agreement and confidence errors', () {
    final summary = CalibrationSummary.fromEvents([
      event(
        'calibrated-right',
        correct: true,
        confidence: ConfidenceRating.high,
      ),
      event(
        'calibrated-wrong',
        correct: false,
        confidence: ConfidenceRating.low,
      ),
      event('over', correct: false, confidence: ConfidenceRating.high),
      event('under', correct: true, confidence: ConfidenceRating.low),
      event('skipped', correct: true),
      event(
        'assisted',
        correct: true,
        confidence: ConfidenceRating.high,
        kind: AttemptKind.correction,
      ),
    ]);

    expect(summary.ratedAttempts, 4);
    expect(summary.calibrated, 2);
    expect(summary.overconfident, 1);
    expect(summary.underconfident, 1);
    expect(summary.score, closeTo(0.625, 0.001));
  });

  test('surprise is reported separately and remains optional', () {
    final summary = CalibrationSummary.fromEvents([
      event(
        'surprising',
        correct: false,
        confidence: ConfidenceRating.medium,
        surprise: SurpriseRating.surprising,
      ),
      event('not-rated', correct: true),
    ]);

    expect(summary.surprisingResults, 1);
    expect(summary.surpriseRatedAttempts, 1);
  });
}
