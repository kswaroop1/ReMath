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
        correctionOfEventId: 'wrong-attempt',
        currentQuestionIndex: 4,
        focusSkillId: 'arithmetic.subtraction',
        id: 'session-1',
        phase: LearningSessionPhase.correction,
        seed: 91,
        startedAt: DateTime.utc(2026, 8, 27, 8),
      );

      await repository.saveSession(session);
      final restored = await repository.loadSession();

      expect(restored?.id, session.id);
      expect(restored?.seed, session.seed);
      expect(restored?.currentQuestionIndex, 4);
      expect(restored?.answerDraft, '17');
      expect(restored?.phase, LearningSessionPhase.correction);
      expect(restored?.focusSkillId, 'arithmetic.subtraction');
      expect(restored?.correctionOfEventId, 'wrong-attempt');
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
        kind: AttemptKind.correction,
        misconceptionId: 'arithmetic.used-addition',
        occurredAt: DateTime.utc(2026, 8, 27, 8, 1),
        questionId: 'question-1',
        responseTime: const Duration(seconds: 3),
        relatedEventId: 'wrong-attempt',
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
      expect(attempts.single.kind, AttemptKind.correction);
      expect(attempts.single.relatedEventId, 'wrong-attempt');
      expect(attempts.single.misconceptionId, 'arithmetic.used-addition');
    },
  );

  test('persists and restores an interrupted focused review chunk', () async {
    final session = LearningSession(
      answerDraft: '12',
      currentQuestionIndex: 2,
      focusSkillId: 'arithmetic.addition',
      id: 'review-session',
      phase: LearningSessionPhase.review,
      seed: 42,
      startedAt: DateTime.utc(2026, 8, 29, 10),
    );

    await repository.saveSession(session);
    final restored = await repository.loadSession();

    expect(restored?.phase, LearningSessionPhase.review);
    expect(restored?.focusSkillId, 'arithmetic.addition');
    expect(restored?.answerDraft, '12');
    expect(restored?.currentQuestionIndex, 2);
  });

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
    expect(attempts.single.kind, AttemptKind.answer);
    expect(attempts.single.relatedEventId, isNull);
    expect(attempts.single.misconceptionId, isNull);
    expect(
      database.select('SELECT version FROM schema_version').single['version'],
      5,
    );
    await migrated.close();
  });

  test('a failed migration rolls back without advancing the schema', () {
    final database = sqlite3.openInMemory()
      ..execute('CREATE TABLE schema_version (version INTEGER NOT NULL) STRICT')
      ..execute('INSERT INTO schema_version VALUES (1)')
      ..execute('CREATE TABLE attempt_events (skill_id TEXT) STRICT');

    expect(
      () => SqliteProgressRepository(database),
      throwsA(isA<SqliteException>()),
    );
    expect(
      database.select('SELECT version FROM schema_version').single['version'],
      1,
    );
    database.close();
  });

  test('a failed correction migration rolls back schema version two', () {
    final database = sqlite3.openInMemory()
      ..execute('CREATE TABLE schema_version (version INTEGER NOT NULL) STRICT')
      ..execute('INSERT INTO schema_version VALUES (2)')
      ..execute('''
        CREATE TABLE attempt_events (
          event_id TEXT PRIMARY KEY,
          event_kind TEXT
        ) STRICT
      ''')
      ..execute('''
        CREATE TABLE active_session (
          singleton INTEGER PRIMARY KEY,
          session_id TEXT NOT NULL,
          seed INTEGER NOT NULL,
          started_at TEXT NOT NULL,
          current_question_index INTEGER NOT NULL,
          answer_draft TEXT NOT NULL
        ) STRICT
      ''');

    expect(
      () => SqliteProgressRepository(database),
      throwsA(isA<SqliteException>()),
    );
    expect(
      database.select('SELECT version FROM schema_version').single['version'],
      2,
    );
    database.close();
  });

  test('a failed Learn-state migration rolls back schema version three', () {
    final database = sqlite3.openInMemory()
      ..execute('CREATE TABLE schema_version (version INTEGER NOT NULL) STRICT')
      ..execute('INSERT INTO schema_version VALUES (3)')
      ..execute('CREATE TABLE attempt_events (event_id TEXT) STRICT');

    expect(
      () => SqliteProgressRepository(database),
      throwsA(isA<SqliteException>()),
    );
    expect(
      database.select('SELECT version FROM schema_version').single['version'],
      3,
    );
    expect(
      database.select(
        "SELECT name FROM sqlite_master WHERE name = 'attempt_events'",
      ),
      isNotEmpty,
    );
    database.close();
  });

  test('migrates an interrupted schema-four session without losing it', () async {
    final database = _schemaFourDatabase()
      ..execute('''
        INSERT INTO active_session VALUES (
          1, 'legacy-session', 42, '2026-08-29T10:00:00.000Z', 3,
          '17', 'question', 'arithmetic.addition', NULL, 0
        )
      ''');

    final migrated = SqliteProgressRepository(database);
    final session = await migrated.loadSession();

    expect(session?.id, 'legacy-session');
    expect(session?.answerDraft, '17');
    expect(session?.focusSkillId, 'arithmetic.addition');
    expect(
      database.select('SELECT version FROM schema_version').single['version'],
      5,
    );
    await migrated.close();
  });

  test('a failed review migration restores the schema-four database', () {
    final database = sqlite3.openInMemory()
      ..execute('CREATE TABLE schema_version (version INTEGER NOT NULL) STRICT')
      ..execute('INSERT INTO schema_version VALUES (4)')
      ..execute('CREATE TABLE active_session (singleton INTEGER) STRICT');

    expect(
      () => SqliteProgressRepository(database),
      throwsA(isA<SqliteException>()),
    );
    expect(
      database.select('SELECT version FROM schema_version').single['version'],
      4,
    );
    expect(
      database.select(
        "SELECT name FROM sqlite_master WHERE name = 'active_session'",
      ),
      isNotEmpty,
    );
    database.close();
  });
}

Database _schemaFourDatabase() => sqlite3.openInMemory()
  ..execute('CREATE TABLE schema_version (version INTEGER NOT NULL) STRICT')
  ..execute('INSERT INTO schema_version VALUES (4)')
  ..execute('''
    CREATE TABLE attempt_events (
      event_id TEXT NOT NULL PRIMARY KEY,
      session_id TEXT NOT NULL,
      question_id TEXT NOT NULL,
      answer TEXT NOT NULL,
      is_correct INTEGER NOT NULL,
      response_ms INTEGER NOT NULL,
      occurred_at TEXT NOT NULL,
      skill_id TEXT NOT NULL,
      event_kind TEXT NOT NULL,
      related_event_id TEXT,
      misconception_id TEXT
    ) STRICT
  ''')
  ..execute('''
    CREATE TABLE active_session (
      singleton INTEGER NOT NULL PRIMARY KEY CHECK (singleton = 1),
      session_id TEXT NOT NULL,
      seed INTEGER NOT NULL,
      started_at TEXT NOT NULL,
      current_question_index INTEGER NOT NULL,
      answer_draft TEXT NOT NULL,
      phase TEXT NOT NULL CHECK (phase IN
        ('question', 'correction', 'retest', 'learn')),
      focus_skill_id TEXT,
      correction_of_event_id TEXT,
      revealed_hint_count INTEGER NOT NULL DEFAULT 0
    ) STRICT
  ''');
