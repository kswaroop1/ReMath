import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:remath/src/features/applications/domain/application_curriculum.dart';
import 'package:remath/src/features/learning/domain/attempt_event.dart';
import 'package:remath/src/features/numbers/domain/study_plan.dart';
import 'package:remath/src/features/numbers/domain/study_scoring.dart';

void main() {
  test('application fluency replays the scoring-version time contract', () {
    final q = ApplicationCurriculum().question('application.mixed', 0, 7, 0);
    StudyProgress progress(int scoringVersion, int seconds) {
      final events = List.generate(
        3,
        (i) => AttemptEvent(
          answer: q.answer,
          eventId: '$scoringVersion-$seconds-$i',
          isCorrect: true,
          occurredAt: DateTime.utc(2026).add(Duration(hours: i)),
          questionId: q.id.replaceFirst('.score1.', '.score$scoringVersion.'),
          responseTime: Duration(seconds: seconds),
          sessionId: 's',
          skillId: q.skillId,
        ),
      );
      return StudyProgress.forSkill(
        q.skillId,
        events,
        DateTime.utc(2026, 1, 2),
      );
    }

    expect(progress(1, 20).level, 1);
    expect(progress(1, 21).level, 0);
    expect(progress(2, 90).level, 1);
    expect(progress(2, 91).level, 0);
    expect(progress(99, 1).unsupported, 3);
  });

  test(
    'technique evidence survives calculation slips and excludes assistance and duplicates',
    () {
      final q = ApplicationCurriculum().question('application.mixed', 0, 7, 0);
      AttemptEvent event(
        String id,
        String answer, {
        AttemptKind kind = AttemptKind.answer,
        String? questionId,
      }) => AttemptEvent(
        answer: answer,
        eventId: id,
        isCorrect: false,
        occurredAt: DateTime.utc(2026),
        questionId: questionId ?? q.id,
        responseTime: const Duration(seconds: 30),
        sessionId: 's',
        skillId: q.skillId,
        kind: kind,
      );
      final slip = jsonEncode({
        ...jsonDecode(q.answer) as Map<String, dynamic>,
        'value': '-1',
      });
      final good = event('one', slip);
      final wrong = event(
        'two',
        jsonEncode({
          ...jsonDecode(q.answer) as Map<String, dynamic>,
          'method': 'rate',
          'assumption': 'constant',
        }),
      );
      final summary = StudyScoring.techniqueSummary([
        good,
        good,
        wrong,
        event('assisted', q.answer, kind: AttemptKind.correction),
        event('hint', 'hint-1', kind: AttemptKind.hint),
        event('invalid', '[]'),
        event(
          'future',
          q.answer,
          questionId: q.id.replaceFirst('.score1.', '.score2.'),
        ),
      ]);
      expect(summary.$1, 3);
      expect(summary.$2, closeTo(2 / 3, 0.0001));
      expect(StudyScoring.techniqueSummary([]), (0, 0.0));
      expect(
        StudyScoring.supports(
          event(
            'future',
            q.answer,
            questionId: q.id.replaceFirst('.score1.', '.score2.'),
          ),
        ),
        isTrue,
      );
      expect(StudyScoring.applicationQuestion(good)!.answer, q.answer);
    },
  );

  test(
    'invalid application answers stay in history without mastery credit',
    () {
      final q = ApplicationCurriculum().question('application.mixed', 0, 7, 0);
      AttemptEvent invalid(String id, bool storedCorrect) => AttemptEvent(
        answer: '[]',
        eventId: id,
        isCorrect: storedCorrect,
        occurredAt: DateTime.utc(2026),
        questionId: q.id,
        responseTime: const Duration(seconds: 1),
        sessionId: 's',
        skillId: q.skillId,
      );

      final progress = StudyProgress.forSkill(q.skillId, [
        invalid('incorrect-flag', false),
        invalid('correct-flag', true),
      ], DateTime.utc(2026));

      expect(progress.independent, 0);
      expect(progress.correct, 0);
      expect(progress.level, 0);
      expect(progress.retention.successfulOccasions, 0);
      expect(progress.unsupported, 2);
    },
  );
}
