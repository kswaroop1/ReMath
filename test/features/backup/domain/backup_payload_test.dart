import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:remath/src/features/backup/domain/backup_payload.dart';
import 'package:remath/src/features/learning/domain/attempt_event.dart';

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
        responseTime: const Duration(microseconds: 1250000),
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

      expect(jsonDecode(encoded)['formatVersion'], 1);
      expect(
        (jsonDecode(encoded)['attempts'] as List)
            .map((attempt) => attempt['eventId']),
        ['event-a', 'event-z'],
      );
      expect(decoded.createdAt, DateTime.utc(2026, 9, 20, 9, 45));
      expect(decoded.studyState, '{"phase":"question"}');
      expect(decoded.attempts, hasLength(2));
      expect(decoded.attempts.last.answer, 'π ≈ 3.14');
      expect(decoded.attempts.last.confidence, ConfidenceRating.low);
      expect(decoded.attempts.last.kind, AttemptKind.answer);
      expect(decoded.attempts.last.misconceptionId, 'decimal-place');
      expect(decoded.attempts.last.occurredAt, DateTime.utc(2026, 9, 20, 8, 30));
      expect(decoded.attempts.last.relatedEventId, 'event-a');
      expect(
        decoded.attempts.last.responseTime,
        const Duration(milliseconds: 1250),
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
          jsonEncode({...valid, 'attempts': [invalidAttempt]}),
        ),
        throwsFormatException,
      );
    });
  });
}
