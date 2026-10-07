import 'package:flutter_test/flutter_test.dart';
import 'package:remath/src/features/learning/data/sqlite_progress_repository.dart';
import 'package:remath/src/features/learning/domain/attempt_event.dart';
import 'package:remath/src/features/learning/domain/learning_session.dart';
import 'package:sqlite3/sqlite3.dart';

void main() {
  test('rejects progress created by an unsupported future app version', () {
    final database = sqlite3.openInMemory()
      ..execute('CREATE TABLE schema_version (version INTEGER NOT NULL) STRICT')
      ..execute('INSERT INTO schema_version VALUES (999)');

    expect(
      () => SqliteProgressRepository(database),
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'message',
          contains('Unsupported progress schema version 999'),
        ),
      ),
    );
    database.close();
  });

  test(
    'attempt history restores marking fields and chronological order',
    () async {
      final repository = SqliteProgressRepository(sqlite3.openInMemory());

      AttemptEvent attempt({
        required String id,
        required bool correct,
        required DateTime occurredAt,
      }) => AttemptEvent(
        answer: correct ? '4' : '5',
        eventId: id,
        isCorrect: correct,
        occurredAt: occurredAt,
        questionId: 'question-$id',
        responseTime: const Duration(milliseconds: 1250),
        sessionId: 'session',
        skillId: 'arithmetic.addition',
      );

      await repository.recordAttempt(
        attempt(id: 'later', correct: true, occurredAt: DateTime.utc(2026, 2)),
      );
      await repository.recordAttempt(
        attempt(
          id: 'earlier',
          correct: false,
          occurredAt: DateTime.utc(2026, 1),
        ),
      );

      final loaded = await repository.loadAttempts();
      expect(loaded.map((event) => event.eventId), ['earlier', 'later']);
      expect(loaded.first.answer, '5');
      expect(loaded.first.isCorrect, isFalse);
      expect(loaded.first.questionId, 'question-earlier');
      expect(loaded.first.sessionId, 'session');
      expect(loaded.first.responseTime, const Duration(milliseconds: 1250));
      expect(loaded.first.occurredAt, DateTime.utc(2026, 1));
      await repository.close();
    },
  );

  test('latest interrupted state replaces the previous checkpoint', () async {
    final repository = SqliteProgressRepository(sqlite3.openInMemory());
    await repository.saveSession(
      LearningSession(
        answerDraft: '1',
        currentQuestionIndex: 1,
        id: 'first',
        seed: 1,
        startedAt: DateTime.utc(2026, 8, 27, 8),
      ),
    );
    await repository.saveSession(
      LearningSession(
        answerDraft: '22',
        currentQuestionIndex: 7,
        focusSkillId: 'arithmetic.addition',
        id: 'second',
        phase: LearningSessionPhase.learn,
        revealedHintCount: 2,
        seed: 2,
        startedAt: DateTime.utc(2026, 8, 27, 9),
      ),
    );

    final restored = await repository.loadSession();
    expect(restored?.id, 'second');
    expect(restored?.seed, 2);
    expect(restored?.currentQuestionIndex, 7);
    expect(restored?.answerDraft, '22');
    expect(restored?.focusSkillId, 'arithmetic.addition');
    expect(restored?.phase, LearningSessionPhase.learn);
    expect(restored?.revealedHintCount, 2);
    expect(restored?.startedAt, DateTime.utc(2026, 8, 27, 9));
    await repository.close();
  });
}
