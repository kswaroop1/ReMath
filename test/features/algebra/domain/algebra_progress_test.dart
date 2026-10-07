import 'package:flutter_test/flutter_test.dart';
import 'package:remath/src/features/learning/domain/attempt_event.dart';
import 'package:remath/src/features/numbers/domain/study_plan.dart';

void main() {
  final now = DateTime.utc(2026, 9, 8);
  AttemptEvent event(
    int i, {
    String version = '1',
    int seconds = 45,
    AttemptKind kind = AttemptKind.answer,
    bool choice = false,
  }) => AttemptEvent(
    answer: '3x',
    eventId: '$i',
    isCorrect: true,
    occurredAt: now.add(Duration(seconds: i)),
    questionId:
        'algebra.algebra.collect.level0.v1.mark1.score$version.7.$i${choice ? '.mcq' : ''}',
    responseTime: Duration(seconds: seconds),
    sessionId: 's',
    skillId: 'algebra.collect',
    kind: kind,
  );

  test(
    'algebra v1 fluency allows sixty seconds and replays deterministically',
    () {
      final events = [for (var i = 0; i < 3; i++) event(i, seconds: 60)];
      final first = StudyProgress.forSkill('algebra.collect', events, now);
      final replay = StudyProgress.forSkill(
        'algebra.collect',
        events.reversed,
        now,
      );
      expect(first.level, 1);
      expect(replay.level, first.level);
      expect(
        replay.retention.successfulOccasions,
        first.retention.successfulOccasions,
      );
      expect(
        StudyProgress.forSkill('algebra.collect', [
          for (var i = 0; i < 3; i++) event(i, seconds: 61),
        ], now).level,
        0,
      );
      expect(events.every((e) => e.questionId.contains('score1')), isTrue);
    },
  );

  test(
    'unknown scoring evidence is retained in history but does not establish mastery',
    () {
      final p = StudyProgress.forSkill('algebra.collect', [
        for (var i = 0; i < 3; i++) event(i, version: '99'),
      ], now);
      expect(p.level, 0);
      expect(p.independent, 0);
      expect(p.retention.successfulOccasions, 0);
      expect(p.explanation, contains('unsupported'));
    },
  );

  test('assistance and choices cannot establish symbolic fluency', () {
    final p = StudyProgress.forSkill('algebra.collect', [
      for (var i = 0; i < 3; i++) event(i, kind: AttemptKind.correction),
      for (var i = 3; i < 6; i++) event(i, choice: true),
    ], now);
    expect(p.level, 0);
    expect(p.assisted, 3);
    expect(p.retention.successfulOccasions, 0);
  });
}
