import 'package:flutter_test/flutter_test.dart';
import 'package:remath/src/features/learning/data/sqlite_progress_repository.dart';
import 'package:remath/src/features/learning/domain/attempt_event.dart';
import 'package:remath/src/features/learning/domain/learning_session.dart';
import 'package:sqlite3/sqlite3.dart';

void main() {
  late SqliteProgressRepository repository;

  setUp(() {
    repository = SqliteProgressRepository(sqlite3.openInMemory());
  });

  tearDown(() => repository.close());

  test(
    'persists and restores an interrupted session including draft',
    () async {
      final session = LearningSession(
        answerDraft: '17',
        currentQuestionIndex: 4,
        id: 'session-1',
        seed: 91,
        startedAt: DateTime.utc(2026, 8, 27, 8),
      );

      await repository.saveSession(session);
      final restored = await repository.loadSession();

      expect(restored?.id, session.id);
      expect(restored?.seed, session.seed);
      expect(restored?.currentQuestionIndex, 4);
      expect(restored?.answerDraft, '17');
      expect(restored?.startedAt, session.startedAt);
    },
  );

  test(
    'attempt events are immutable and duplicate delivery is idempotent',
    () async {
      final event = AttemptEvent(
        answer: '12',
        eventId: 'event-1',
        isCorrect: true,
        occurredAt: DateTime.utc(2026, 8, 27, 8, 1),
        questionId: 'question-1',
        responseTime: const Duration(seconds: 3),
        sessionId: 'session-1',
        skillId: 'arithmetic.addition',
      );

      expect(await repository.recordAttempt(event), isTrue);
      expect(await repository.recordAttempt(event), isFalse);

      final attempts = await repository.loadAttempts();
      expect(attempts, hasLength(1));
      expect(attempts.single.eventId, event.eventId);
      expect(attempts.single.responseTime, const Duration(seconds: 3));
      expect(attempts.single.skillId, 'arithmetic.addition');
    },
  );

  test(
    'completing another session does not remove the active session',
    () async {
      await repository.saveSession(
        LearningSession(
          currentQuestionIndex: 0,
          id: 'active',
          seed: 1,
          startedAt: DateTime.utc(2026),
        ),
      );

      await repository.completeSession('other');
      expect((await repository.loadSession())?.id, 'active');

      await repository.completeSession('active');
      expect(await repository.loadSession(), isNull);
    },
  );

  test('migrates version-one attempts without losing history', () async {
    final database = sqlite3.openInMemory();
    database
      ..execute('CREATE TABLE schema_version (version INTEGER NOT NULL) STRICT')
      ..execute('INSERT INTO schema_version (version) VALUES (1)')
      ..execute('''
        CREATE TABLE attempt_events (
          event_id TEXT NOT NULL PRIMARY KEY,
          session_id TEXT NOT NULL,
          question_id TEXT NOT NULL,
          answer TEXT NOT NULL,
          is_correct INTEGER NOT NULL,
          response_ms INTEGER NOT NULL,
          occurred_at TEXT NOT NULL
        ) STRICT
      ''')
      ..execute('''
        INSERT INTO attempt_events VALUES (
          'legacy-event', 'legacy-session', 'legacy-question', '4', 1, 3000,
          '2026-08-27T08:00:00.000Z'
        )
      ''');

    final migrated = SqliteProgressRepository(database);
    final attempts = await migrated.loadAttempts();

    expect(attempts.single.eventId, 'legacy-event');
    expect(attempts.single.skillId, 'arithmetic.mixed.legacy');
    expect(database.select('SELECT version FROM schema_version').single['version'], 2);
    await migrated.close();
  });
}
