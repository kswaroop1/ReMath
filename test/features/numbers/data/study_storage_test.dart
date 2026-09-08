import 'package:flutter_test/flutter_test.dart';
import 'package:remath/src/features/learning/data/in_memory_progress_repository.dart';
import 'package:remath/src/features/learning/data/sqlite_progress_repository.dart';
import 'package:remath/src/features/learning/domain/attempt_event.dart';
import 'package:remath/src/features/learning/domain/learning_session.dart';
import 'package:remath/src/features/learning/domain/progress_repository.dart';
import 'package:sqlite3/sqlite3.dart';

void main() {
  final now = DateTime.utc(2026, 9, 7);
  AttemptEvent event(String id) => AttemptEvent(
    answer: '3/4',
    eventId: id,
    isCorrect: true,
    occurredAt: now,
    questionId: 'fraction.v1.1.0',
    responseTime: const Duration(seconds: 4),
    sessionId: 'study-1',
    skillId: 'number.fractions',
  );

  for (final memory in [true, false]) {
    test(
      '${memory ? 'memory' : 'SQLite'} atomically stores attempt and advanced study state',
      () async {
        final ProgressRepository repository = memory
            ? InMemoryProgressRepository()
            : SqliteProgressRepository(sqlite3.openInMemory());
        addTearDown(repository.close);
        await repository.saveStudyState('before');
        expect(
          await repository.commitStudyAttempt(event('one'), 'after'),
          isTrue,
        );
        expect(await repository.loadStudyState(), 'after');
        expect(
          await repository.commitStudyAttempt(event('one'), 'stale'),
          isFalse,
        );
        expect(await repository.loadStudyState(), 'after');
        expect((await repository.loadAttempts()).single.answer, '3/4');
        await repository.saveSession(
          LearningSession(
            id: 'legacy',
            seed: 1,
            startedAt: now,
            currentQuestionIndex: 2,
            answerDraft: '17',
          ),
        );
        await repository.saveStudyState('goal-only');
        expect((await repository.loadSession())!.answerDraft, '17');
      },
    );
  }

  test(
    'failed schema six migration preserves version and legacy data for retry',
    () async {
      final database = sqlite3.openInMemory();
      final initial = SqliteProgressRepository(database);
      addTearDown(initial.close);
      await initial.recordAttempt(event('legacy'));
      database.execute('DROP TABLE study_state');
      database.execute('UPDATE schema_version SET version = 5');
      database.execute('CREATE VIEW study_state AS SELECT 1 AS singleton');
      expect(
        () => SqliteProgressRepository(database),
        throwsA(isA<SqliteException>()),
      );
      expect(
        database.select('SELECT version FROM schema_version').single['version'],
        5,
      );
      expect((await initial.loadAttempts()).single.eventId, 'legacy');
      database.execute('DROP VIEW study_state');
      final retried = SqliteProgressRepository(database);
      await retried.saveStudyState('recovered');
      expect(await retried.loadStudyState(), 'recovered');
      expect((await retried.loadAttempts()).single.eventId, 'legacy');
    },
  );

  test('failed state persistence rolls back the new attempt', () async {
    final database = sqlite3.openInMemory();
    final repository = SqliteProgressRepository(database);
    addTearDown(repository.close);
    await repository.saveStudyState('before');
    database.execute(
      "CREATE TRIGGER reject_study BEFORE UPDATE ON study_state BEGIN SELECT RAISE(ABORT, 'disk failure'); END",
    );
    await expectLater(
      repository.commitStudyAttempt(event('one'), 'after'),
      throwsA(isA<SqliteException>()),
    );
    expect(await repository.loadAttempts(), isEmpty);
    expect(await repository.loadStudyState(), 'before');
  });
  test(
    'schema five upgrades preserve legacy attempts and active drafts',
    () async {
      final database = sqlite3.openInMemory();
      final initial = SqliteProgressRepository(database);
      await initial.recordAttempt(event('legacy'));
      await initial.saveSession(
        LearningSession(
          id: 'legacy',
          seed: 4,
          startedAt: now,
          currentQuestionIndex: 3,
          answerDraft: '21',
        ),
      );
      database.execute('DROP TABLE study_state');
      database.execute('UPDATE schema_version SET version = 5');
      final migrated = SqliteProgressRepository(database);
      addTearDown(migrated.close);
      expect((await migrated.loadAttempts()).single.eventId, 'legacy');
      expect((await migrated.loadSession())!.answerDraft, '21');
      expect(await migrated.loadStudyState(), isNull);
      await migrated.saveStudyState('goal');
      expect(await migrated.loadStudyState(), 'goal');
    },
  );
}
