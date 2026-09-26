import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:remath/src/features/backup/domain/backup_payload.dart';
import 'package:remath/src/features/learning/domain/attempt_event.dart';
import 'package:remath/src/features/learning/domain/learning_session.dart';

void main() {
  group('portable backup payload', () {
    test('round-trips every immutable attempt field in canonical order', () {
      final later = AttemptEvent(
        answer: 'π ≈ 3.14',
        confidence: ConfidenceRating.low,
        eventId: 'event-z',
        isCorrect: false,
        kind: AttemptKind.answer,
        misconceptionId: 'decimal-place',
        occurredAt: DateTime.parse('2026-09-20T09:30:00+01:00'),
        questionId: 'question-2',
        relatedEventId: 'event-a',
        responseTime: const Duration(microseconds: 1250001),
        sessionId: 'session-1',
        skillId: 'numbers.decimals',
        surprise: SurpriseRating.surprising,
      );
      final earlier = AttemptEvent(
        answer: '½',
        eventId: 'event-a',
        isCorrect: true,
        kind: AttemptKind.retest,
        occurredAt: DateTime.utc(2026, 9, 20, 8),
        questionId: 'question-1',
        responseTime: const Duration(milliseconds: 875),
        sessionId: 'session-1',
        skillId: 'numbers.fractions',
      );

      final encoded = BackupPayload(
        attempts: [later, earlier],
        createdAt: DateTime.parse('2026-09-20T10:45:00+01:00'),
        studyState: '{"phase":"question"}',
      ).encode();
      final decoded = BackupPayload.decode(encoded);
      final encodedObject = (jsonDecode(encoded) as Map)
          .cast<String, Object?>();
      final encodedAttempts = encodedObject['attempts']! as List;

      expect(encodedObject['formatVersion'], 1);
      expect(
        encodedAttempts.map(
          (attempt) => (attempt as Map).cast<String, Object?>()['eventId'],
        ),
        ['event-a', 'event-z'],
      );
      expect(decoded.createdAt, DateTime.utc(2026, 9, 20, 9, 45));
      expect(decoded.studyState, '{"phase":"question"}');
      expect(decoded.attempts, hasLength(2));
      expect(decoded.attempts.last.answer, 'π ≈ 3.14');
      expect(decoded.attempts.last.confidence, ConfidenceRating.low);
      expect(decoded.attempts.last.kind, AttemptKind.answer);
      expect(decoded.attempts.last.misconceptionId, 'decimal-place');
      expect(
        decoded.attempts.last.occurredAt,
        DateTime.utc(2026, 9, 20, 8, 30),
      );
      expect(decoded.attempts.last.relatedEventId, 'event-a');
      expect(
        decoded.attempts.last.responseTime,
        const Duration(microseconds: 1250001),
      );
      expect(decoded.attempts.last.surprise, SurpriseRating.surprising);
      expect(decoded.encode(), encoded);
    });

    test('rejects unsupported versions and duplicate or invalid events', () {
      final valid = <String, Object?>{
        'formatVersion': 1,
        'createdAt': '2026-09-20T09:45:00.000Z',
        'attempts': [
          {
            'answer': '4',
            'eventId': 'same-id',
            'isCorrect': true,
            'kind': 'answer',
            'occurredAt': '2026-09-20T09:00:00.000Z',
            'questionId': 'q-1',
            'responseMilliseconds': 100,
            'sessionId': 's-1',
            'skillId': 'arithmetic.addition',
          },
        ],
        'studyState': null,
      };

      expect(
        () => BackupPayload.decode(jsonEncode({...valid, 'formatVersion': 2})),
        throwsFormatException,
      );
      expect(
        () => BackupPayload.decode(
          jsonEncode({
            ...valid,
            'attempts': [
              (valid['attempts']! as List).single,
              (valid['attempts']! as List).single,
            ],
          }),
        ),
        throwsFormatException,
      );
      final invalidAttempt = Map<String, Object?>.from(
        (valid['attempts']! as List).single as Map,
      )..['responseMilliseconds'] = -1;
      expect(
        () => BackupPayload.decode(
          jsonEncode({
            ...valid,
            'attempts': [invalidAttempt],
          }),
        ),
        throwsFormatException,
      );

      for (final source in <Object?>[
        const [],
        {...valid, 'createdAt': '2026-09-20T09:45:00'},
        {...valid, 'attempts': 'not-a-list'},
        {...valid, 'studyState': 42},
        {
          ...valid,
          'attempts': [
            {
              ...(valid['attempts']! as List).single as Map,
              'kind': 'retired',
            },
          ],
        },
        {
          ...valid,
          'attempts': [
            {
              ...(valid['attempts']! as List).single as Map,
              'isCorrect': 'yes',
            },
          ],
        },
      ]) {
        expect(
          () => BackupPayload.decode(jsonEncode(source)),
          throwsFormatException,
        );
      }

      expect(
        () => BackupPayload(
          attempts: [
            _attempt('duplicate'),
            _attempt('duplicate'),
          ],
          createdAt: DateTime.utc(2026, 9, 20),
          studyState: null,
        ),
        throwsArgumentError,
      );
    });

    test('rejects a learn session without a focus skill', () {
      final encoded = jsonEncode({
        'formatVersion': 1,
        'createdAt': '2026-09-21T18:00:00.000Z',
        'attempts': const [],
        'session': {
          'answerDraft': '',
          'correctionOfEventId': null,
          'currentQuestionIndex': 0,
          'focusSkillId': null,
          'id': 'session-1',
          'phase': 'learn',
          'revealedHintCount': 0,
          'seed': 42,
          'startedAt': '2026-09-21T17:55:00.000Z',
        },
        'studyState': null,
      });

      expect(() => BackupPayload.decode(encoded), throwsFormatException);
    });

    test('preserves the exact generated question identity', () {
      final payload = BackupPayload(
        attempts: const [],
        createdAt: DateTime.utc(2026, 9, 21, 22),
        session: LearningSession(
          answerDraft: '17',
          currentQuestionIndex: 4,
          id: 'session-1',
          questionId: 'core.addition.v2.42.4',
          questionSkillId: 'arithmetic.addition',
          seed: 42,
          startedAt: DateTime.utc(2026, 9, 21, 21),
        ),
        studyState: null,
      );

      final restored = BackupPayload.decode(payload.encode()).session!;

      expect(restored.questionId, 'core.addition.v2.42.4');
      expect(restored.questionSkillId, 'arithmetic.addition');
    });
  });
}

AttemptEvent _attempt(String eventId) => AttemptEvent(
  answer: '4',
  eventId: eventId,
  isCorrect: true,
  occurredAt: DateTime.utc(2026, 9, 20),
  questionId: 'q-1',
  responseTime: const Duration(milliseconds: 100),
  sessionId: 's-1',
  skillId: 'arithmetic.addition',
);
