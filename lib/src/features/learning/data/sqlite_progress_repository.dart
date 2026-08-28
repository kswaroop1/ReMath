import 'package:sqlite3/common.dart';

import '../domain/attempt_event.dart';
import '../domain/learning_session.dart';
import '../domain/progress_repository.dart';

final class SqliteProgressRepository implements ProgressRepository {
  SqliteProgressRepository(this._database) {
    _migrate();
  }

  final CommonDatabase _database;
  static const _currentSchemaVersion = 3;

  void _migrate() {
    _database.execute('PRAGMA foreign_keys = ON');
    _database.execute('''
      CREATE TABLE IF NOT EXISTS schema_version (
        version INTEGER NOT NULL
      ) STRICT
    ''');
    if (_database.select('SELECT version FROM schema_version').isEmpty) {
      _database.execute('INSERT INTO schema_version (version) VALUES (1)');
    }
    _database.execute('''
      CREATE TABLE IF NOT EXISTS attempt_events (
        event_id TEXT NOT NULL PRIMARY KEY,
        session_id TEXT NOT NULL,
        question_id TEXT NOT NULL,
        answer TEXT NOT NULL,
        is_correct INTEGER NOT NULL CHECK (is_correct IN (0, 1)),
        response_ms INTEGER NOT NULL CHECK (response_ms >= 0),
        occurred_at TEXT NOT NULL
      ) STRICT
    ''');
    final version =
        _database.select('SELECT version FROM schema_version').single['version']
            as int;
    if (version > _currentSchemaVersion) {
      throw StateError('Unsupported progress schema version $version');
    }
    if (version < 2) {
      _database.execute('BEGIN IMMEDIATE');
      try {
        _database.execute(
          'ALTER TABLE attempt_events ADD COLUMN skill_id TEXT NOT NULL '
          'DEFAULT \'arithmetic.mixed.legacy\'',
        );
        _database.execute('UPDATE schema_version SET version = 2');
        _database.execute('COMMIT');
      } catch (_) {
        _database.execute('ROLLBACK');
        rethrow;
      }
    }
    _database.execute('''
      CREATE TABLE IF NOT EXISTS active_session (
        singleton INTEGER NOT NULL PRIMARY KEY CHECK (singleton = 1),
        session_id TEXT NOT NULL,
        seed INTEGER NOT NULL,
        started_at TEXT NOT NULL,
        current_question_index INTEGER NOT NULL CHECK (current_question_index >= 0),
        answer_draft TEXT NOT NULL
      ) STRICT
    ''');
    if (version < 3) {
      _database.execute('BEGIN IMMEDIATE');
      try {
        _database
          ..execute(
            'ALTER TABLE attempt_events ADD COLUMN event_kind TEXT NOT NULL '
            'DEFAULT \'answer\' CHECK (event_kind IN '
            '(\'answer\', \'correction\', \'retest\'))',
          )
          ..execute(
            'ALTER TABLE attempt_events ADD COLUMN related_event_id TEXT',
          )
          ..execute(
            'ALTER TABLE attempt_events ADD COLUMN misconception_id TEXT',
          )
          ..execute(
            'ALTER TABLE active_session ADD COLUMN phase TEXT NOT NULL '
            'DEFAULT \'question\' CHECK (phase IN '
            '(\'question\', \'correction\', \'retest\'))',
          )
          ..execute(
            'ALTER TABLE active_session ADD COLUMN focus_skill_id TEXT',
          )
          ..execute(
            'ALTER TABLE active_session ADD COLUMN correction_of_event_id TEXT',
          )
          ..execute('UPDATE schema_version SET version = 3')
          ..execute('COMMIT');
      } catch (_) {
        _database.execute('ROLLBACK');
        rethrow;
      }
    }
  }

  @override
  Future<void> close() async => _database.close();

  @override
  Future<void> completeSession(String sessionId) async {
    _database.execute(
      'DELETE FROM active_session WHERE singleton = 1 AND session_id = ?',
      [sessionId],
    );
  }

  @override
  Future<List<AttemptEvent>> loadAttempts() async => _database
      .select('SELECT * FROM attempt_events ORDER BY occurred_at, event_id')
      .map(_attemptFromRow)
      .toList(growable: false);

  @override
  Future<LearningSession?> loadSession() async {
    final rows = _database.select(
      'SELECT * FROM active_session WHERE singleton = 1',
    );
    if (rows.isEmpty) {
      return null;
    }
    final row = rows.single;
    return LearningSession(
      answerDraft: row['answer_draft'] as String,
      correctionOfEventId: row['correction_of_event_id'] as String?,
      currentQuestionIndex: row['current_question_index'] as int,
      focusSkillId: row['focus_skill_id'] as String?,
      id: row['session_id'] as String,
      phase: LearningSessionPhase.values.byName(row['phase'] as String),
      seed: row['seed'] as int,
      startedAt: DateTime.parse(row['started_at'] as String).toUtc(),
    );
  }

  @override
  Future<bool> recordAttempt(AttemptEvent event) async {
    _database.execute(
      '''
      INSERT OR IGNORE INTO attempt_events (
        event_id, session_id, question_id, answer, is_correct,
        response_ms, occurred_at, skill_id, event_kind, related_event_id,
        misconception_id
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      ''',
      [
        event.eventId,
        event.sessionId,
        event.questionId,
        event.answer,
        event.isCorrect ? 1 : 0,
        event.responseTime.inMilliseconds,
        event.occurredAt.toUtc().toIso8601String(),
        event.skillId,
        event.kind.name,
        event.relatedEventId,
        event.misconceptionId,
      ],
    );
    return _database.updatedRows == 1;
  }

  @override
  Future<void> saveSession(LearningSession session) async {
    _database.execute(
      '''
      INSERT INTO active_session (
        singleton, session_id, seed, started_at, current_question_index,
        answer_draft, phase, focus_skill_id, correction_of_event_id
      ) VALUES (1, ?, ?, ?, ?, ?, ?, ?, ?)
      ON CONFLICT(singleton) DO UPDATE SET
        session_id = excluded.session_id,
        seed = excluded.seed,
        started_at = excluded.started_at,
        current_question_index = excluded.current_question_index,
        answer_draft = excluded.answer_draft,
        phase = excluded.phase,
        focus_skill_id = excluded.focus_skill_id,
        correction_of_event_id = excluded.correction_of_event_id
      ''',
      [
        session.id,
        session.seed,
        session.startedAt.toUtc().toIso8601String(),
        session.currentQuestionIndex,
        session.answerDraft,
        session.phase.name,
        session.focusSkillId,
        session.correctionOfEventId,
      ],
    );
  }

  AttemptEvent _attemptFromRow(Row row) => AttemptEvent(
    answer: row['answer'] as String,
    eventId: row['event_id'] as String,
    isCorrect: (row['is_correct'] as int) == 1,
    kind: AttemptKind.values.byName(row['event_kind'] as String),
    misconceptionId: row['misconception_id'] as String?,
    occurredAt: DateTime.parse(row['occurred_at'] as String).toUtc(),
    questionId: row['question_id'] as String,
    responseTime: Duration(milliseconds: row['response_ms'] as int),
    relatedEventId: row['related_event_id'] as String?,
    sessionId: row['session_id'] as String,
    skillId: row['skill_id'] as String,
  );
}
