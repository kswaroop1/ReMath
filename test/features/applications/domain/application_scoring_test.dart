import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:remath/src/features/applications/domain/application_curriculum.dart';
import 'package:remath/src/features/learning/domain/attempt_event.dart';
import 'package:remath/src/features/numbers/domain/study_scoring.dart';

void main() {
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
      expect(summary.$1, 2);
      expect(summary.$2, 0.5);
      expect(StudyScoring.techniqueSummary([]), (0, 0.0));
      expect(
        StudyScoring.supports(
          event(
            'future',
            q.answer,
            questionId: q.id.replaceFirst('.score1.', '.score2.'),
          ),
        ),
        isFalse,
      );
      expect(StudyScoring.applicationQuestion(good)!.answer, q.answer);
    },
  );
}
