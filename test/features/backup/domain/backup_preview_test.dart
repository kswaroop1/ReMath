import 'package:flutter_test/flutter_test.dart';
import 'package:remath/src/features/backup/domain/backup_payload.dart';
import 'package:remath/src/features/backup/domain/backup_preview.dart';
import 'package:remath/src/features/learning/domain/attempt_event.dart';
import 'package:remath/src/features/learning/domain/learning_session.dart';
import 'package:remath/src/features/numbers/domain/study_plan.dart';

void main() {
  group('backup import preview', () {
    test(
      'classifies immutable events and summarizes the validated payload',
      () {
        final duplicate = _attempt(
          eventId: 'duplicate',
          occurredAt: DateTime.utc(2026, 9, 18, 8),
          skillId: 'numbers.fractions',
        );
        final incoming = BackupPayload(
          attempts: [
            duplicate,
            _attempt(
              eventId: 'new',
              occurredAt: DateTime.utc(2026, 9, 20, 10),
              skillId: 'numbers.decimals',
            ),
          ],
          createdAt: DateTime.utc(2026, 9, 20, 11),
          studyState: StudyState(
            plan: StudyPlanner().plan(
              'number-fluency',
              const [],
              DateTime.utc(2026, 9, 20),
            ),
          ).encode(),
        );

        final preview = BackupPreview.create(
          payload: BackupPayload.decode(incoming.encode()),
          localAttempts: [duplicate],
        );

        expect(preview.createdAt, DateTime.utc(2026, 9, 20, 11));
        expect(preview.formatVersion, BackupPayload.formatVersion);
        expect(preview.attemptCount, 2);
        expect(preview.newAttemptCount, 1);
        expect(preview.duplicateAttemptCount, 1);
        expect(preview.conflictingAttemptCount, 0);
        expect(preview.skillIds, ['numbers.decimals', 'numbers.fractions']);
        expect(preview.earliestAttemptAt, DateTime.utc(2026, 9, 18, 8));
        expect(preview.latestAttemptAt, DateTime.utc(2026, 9, 20, 10));
        expect(preview.hasStudyState, isTrue);
        expect(preview.canApply, isTrue);
      },
    );

    test('same event ID with changed immutable content blocks apply', () {
      final local = _attempt(
        eventId: 'conflict',
        occurredAt: DateTime.utc(2026, 9, 20, 10),
        skillId: 'arithmetic.addition',
      );
      final changed = AttemptEvent(
        answer: '5',
        eventId: local.eventId,
        isCorrect: false,
        occurredAt: local.occurredAt,
        questionId: local.questionId,
        responseTime: local.responseTime,
        sessionId: local.sessionId,
        skillId: local.skillId,
      );

      final preview = BackupPreview.create(
        payload: BackupPayload(
          attempts: [changed],
          createdAt: DateTime.utc(2026, 9, 20, 11),
          studyState: null,
        ),
        localAttempts: [local],
      );

      expect(preview.newAttemptCount, 0);
      expect(preview.duplicateAttemptCount, 0);
      expect(preview.conflictingAttemptCount, 1);
      expect(preview.hasStudyState, isFalse);
      expect(preview.canApply, isFalse);
    });

    test('empty payload has an explicit empty time and skill range', () {
      final preview = BackupPreview.create(
        payload: BackupPayload(
          attempts: const [],
          createdAt: DateTime.utc(2026, 9, 20, 11),
          studyState: null,
        ),
        localAttempts: const [],
      );

      expect(preview.attemptCount, 0);
      expect(preview.skillIds, isEmpty);
      expect(preview.earliestAttemptAt, isNull);
      expect(preview.latestAttemptAt, isNull);
      expect(preview.canApply, isTrue);
    });

    test('completed study state is not presented as active', () {
      final preview = BackupPreview.create(
        payload: BackupPayload(
          attempts: const [],
          createdAt: DateTime.utc(2026, 9, 21, 20),
          studyState: const StudyState().encode(),
        ),
        localAttempts: const [],
      );

      expect(preview.hasStudyState, isFalse);
    });

    test('reports a resumable Home learning session separately', () {
      final preview = BackupPreview.create(
        payload: BackupPayload(
          attempts: const [],
          createdAt: DateTime.utc(2026, 9, 21, 20),
          session: LearningSession(
            currentQuestionIndex: 2,
            id: 'session-1',
            seed: 42,
            startedAt: DateTime.utc(2026, 9, 21, 19),
          ),
          studyState: null,
        ),
        localAttempts: const [],
      );

      expect(preview.hasLearningSession, isTrue);
      expect(preview.hasStudyState, isFalse);
    });
  });
}

AttemptEvent _attempt({
  required String eventId,
  required DateTime occurredAt,
  required String skillId,
}) {
  return AttemptEvent(
    answer: '4',
    eventId: eventId,
    isCorrect: true,
    occurredAt: occurredAt,
    questionId: 'question-$eventId',
    responseTime: const Duration(milliseconds: 500),
    sessionId: 'session-1',
    skillId: skillId,
  );
}
