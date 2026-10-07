import 'package:flutter_test/flutter_test.dart';
import 'package:remath/src/features/learning/data/in_memory_progress_repository.dart';
import 'package:remath/src/features/learning/data/sqlite_progress_repository.dart';
import 'package:remath/src/features/learning/domain/attempt_event.dart';
import 'package:remath/src/features/learning/domain/learning_session.dart';
import 'package:remath/src/features/learning/domain/progress_repository.dart';
import 'package:remath/src/features/numbers/domain/study_plan.dart';
import 'package:sqlite3/sqlite3.dart';

void main() {
  group('transactional progress recovery', () {
    test(
      'merges immutable attempts idempotently on every repository',
      () async {
        for (final fixture in _fixtures()) {
          final repository = fixture.repository;
          addTearDown(fixture.close);
          final attempts = [_attempt('first'), _attempt('second')];
          final activeStudyState = StudyState(
            plan: StudyPlanner().plan(
              'number-fluency',
              const [],
              DateTime.utc(2026, 9, 20),
            ),
            sessionId: 'recovered-study',
          ).encode();

          final first = await repository.mergeProgress(
            attempts: attempts,
            studyState: activeStudyState,
          );
          final retry = await repository.mergeProgress(
            attempts: attempts,
            studyState: activeStudyState,
          );

          expect(first.insertedAttemptCount, 2);
          expect(first.duplicateAttemptCount, 0);
          expect(first.importedStudyState, isTrue);
          expect(retry.insertedAttemptCount, 0);
          expect(retry.duplicateAttemptCount, 2);
          expect(retry.importedStudyState, isFalse);
          expect(await repository.loadAttempts(), hasLength(2));
          expect(await repository.loadStudyState(), activeStudyState);
        }
      },
    );

    test('a conflicting ID blocks the entire merge', () async {
      for (final fixture in _fixtures()) {
        final repository = fixture.repository;
        addTearDown(fixture.close);
        await repository.recordAttempt(_attempt('existing'));
        await repository.saveStudyState('local-state');
        final conflict = _attempt('existing', answer: 'different');

        await expectLater(
          repository.mergeProgress(
            attempts: [_attempt('would-be-new'), conflict],
            studyState: 'imported-state',
          ),
          throwsA(
            isA<ProgressConflictException>().having(
              (error) => error.toString(),
              'message',
              'Attempt event existing has conflicting content.',
            ),
          ),
        );

        expect(
          (await repository.loadAttempts()).map((event) => event.eventId),
          ['existing'],
        );
        expect(await repository.loadStudyState(), 'local-state');
      }
    });

    test('duplicate incoming IDs are rejected by every repository', () async {
      for (final fixture in _fixtures()) {
        final repository = fixture.repository;
        addTearDown(fixture.close);

        await expectLater(
          repository.mergeProgress(
            attempts: [_attempt('duplicate'), _attempt('duplicate')],
            studyState: null,
          ),
          throwsArgumentError,
        );
        expect(await repository.loadAttempts(), isEmpty);
      }
    });

    test('recovery preserves chronological attempt order', () async {
      for (final fixture in _fixtures()) {
        final repository = fixture.repository;
        addTearDown(fixture.close);
        await repository.recordAttempt(
          _attempt('newer', occurredAt: DateTime.utc(2026, 9, 20, 11)),
        );

        await repository.mergeProgress(
          attempts: [
            _attempt('older', occurredAt: DateTime.utc(2026, 9, 20, 9)),
          ],
          studyState: null,
        );

        expect(
          (await repository.loadAttempts()).map((event) => event.eventId),
          ['older', 'newer'],
        );
      }
    });

    test(
      'SQLite recovery preserves microseconds and retries idempotently',
      () async {
        final database = sqlite3.openInMemory();
        final repository = SqliteProgressRepository(database);
        addTearDown(repository.close);
        final precise = _attempt(
          'precise',
          responseTime: const Duration(microseconds: 500001),
        );

        final first = await repository.mergeProgress(
          attempts: [precise],
          studyState: null,
        );
        final retry = await repository.mergeProgress(
          attempts: [precise],
          studyState: null,
        );

        expect(first.insertedAttemptCount, 1);
        expect(retry.duplicateAttemptCount, 1);
        expect(
          (await repository.loadAttempts()).single.responseTime,
          precise.responseTime,
        );
      },
    );

    test('new attempts never overwrite a local active study state', () async {
      for (final fixture in _fixtures()) {
        final repository = fixture.repository;
        addTearDown(fixture.close);
        await repository.saveStudyState('local-state');

        final result = await repository.mergeProgress(
          attempts: [_attempt('new')],
          studyState: 'imported-state',
        );

        expect(result.insertedAttemptCount, 1);
        expect(result.importedStudyState, isFalse);
        expect(await repository.loadStudyState(), 'local-state');
      }
    });

    test(
      'an inactive local study row does not block active recovery',
      () async {
        final incoming = StudyState(
          plan: StudyPlanner().plan(
            'number-fluency',
            const [],
            DateTime.utc(2026, 9, 20),
          ),
          sessionId: 'recovered-study',
        ).encode();
        for (final fixture in _fixtures()) {
          final repository = fixture.repository;
          addTearDown(fixture.close);
          await repository.saveStudyState(const StudyState().encode());

          final result = await repository.mergeProgress(
            attempts: const [],
            studyState: incoming,
          );

          expect(result.importedStudyState, isTrue);
          expect(await repository.loadStudyState(), incoming);
        }
      },
    );

    test(
      'an inactive imported study row does not replace local choice',
      () async {
        final local = const StudyState(goalId: 'number-fluency').encode();
        final incoming = const StudyState(goalId: 'algebra').encode();
        for (final fixture in _fixtures()) {
          final repository = fixture.repository;
          addTearDown(fixture.close);
          await repository.saveStudyState(local);

          final result = await repository.mergeProgress(
            attempts: const [],
            studyState: incoming,
          );

          expect(result.importedStudyState, isFalse);
          expect(await repository.loadStudyState(), local);
        }
      },
    );

    test(
      'an advanced event stream blocks stale active study recovery',
      () async {
        final incoming = StudyState(
          plan: StudyPlanner().plan(
            'number-fluency',
            const [],
            DateTime.utc(2026, 9, 20),
          ),
          sessionId: 'recovered-study',
        ).encode();
        for (final fixture in _fixtures()) {
          final repository = fixture.repository;
          addTearDown(fixture.close);
          await repository.saveStudyState(const StudyState().encode());
          await repository.recordAttempt(_attempt('recovered-study.0'));

          final result = await repository.mergeProgress(
            attempts: const [],
            studyState: incoming,
          );

          expect(result.importedStudyState, isFalse);
          expect(
            await repository.loadStudyState(),
            const StudyState().encode(),
          );
        }
      },
    );

    test(
      'an advanced event stream blocks stale Home-session recovery',
      () async {
        for (final fixture in _fixtures()) {
          final repository = fixture.repository;
          addTearDown(fixture.close);
          await repository.recordAttempt(_attempt('local-session-progress'));

          final result = await repository.mergeProgress(
            attempts: const [],
            studyState: null,
            session: _session('session-1'),
          );

          expect(result.importedSession, isFalse);
          expect(await repository.loadSession(), isNull);
        }
      },
    );

    test('an imported event stream blocks its stale Home session', () async {
      for (final fixture in _fixtures()) {
        final repository = fixture.repository;
        addTearDown(fixture.close);

        final result = await repository.mergeProgress(
          attempts: [_attempt('imported-session-progress')],
          studyState: null,
          session: _session('session-1'),
        );

        expect(result.insertedAttemptCount, 1);
        expect(result.importedSession, isFalse);
        expect(await repository.loadSession(), isNull);
      }
    });

    test('earlier diagnostic answers preserve a legacy session', () async {
      for (final fixture in _fixtures()) {
        final repository = fixture.repository;
        addTearDown(fixture.close);
        final session = LearningSession(
          currentQuestionIndex: 2,
          id: 'diagnostic-session',
          seed: 42,
          startedAt: DateTime.utc(2026, 9, 20, 9),
        );

        final result = await repository.mergeProgress(
          attempts: [
            _attempt('diagnostic-0', sessionId: session.id),
            _attempt('diagnostic-1', sessionId: session.id),
          ],
          studyState: null,
          session: session,
        );

        expect(result.importedSession, isTrue);
        expect((await repository.loadSession())?.id, session.id);
      }
    });

    test('merged diagnostic answers block a stale legacy session', () async {
      for (final fixture in _fixtures()) {
        final repository = fixture.repository;
        addTearDown(fixture.close);
        final session = LearningSession(
          currentQuestionIndex: 2,
          id: 'diagnostic-session',
          seed: 42,
          startedAt: DateTime.utc(2026, 9, 20, 9),
        );
        final earlier = [
          _attempt('diagnostic-0', sessionId: session.id),
          _attempt('diagnostic-1', sessionId: session.id),
        ];
        await repository.recordAttempt(earlier.first);
        await repository.recordAttempt(
          _attempt('diagnostic-2', sessionId: session.id),
        );

        final result = await repository.mergeProgress(
          attempts: earlier,
          studyState: null,
          session: session,
        );

        expect(result.importedSession, isFalse);
        expect(await repository.loadSession(), isNull);
        expect(await repository.loadAttempts(), hasLength(3));
        expect(result.duplicateAttemptCount, 1);
      }
    });

    test('a later correction event blocks its stale session', () async {
      for (final fixture in _fixtures()) {
        final repository = fixture.repository;
        addTearDown(fixture.close);
        final session = _session('session-1').copyWith(
          correctionOfEventId: 'failed-answer',
          phase: LearningSessionPhase.correction,
        );

        final result = await repository.mergeProgress(
          attempts: [
            _attempt(
              'failed-answer',
              isCorrect: false,
              questionId: 'question-3',
            ),
            _attempt(
              'successful-correction',
              kind: AttemptKind.correction,
              questionId: 'question-3',
              relatedEventId: 'failed-answer',
            ),
          ],
          studyState: null,
          session: session,
        );

        expect(result.importedSession, isFalse);
        expect(await repository.loadSession(), isNull);
      }
    });

    test('learn snapshots cannot lag behind merged hint levels', () async {
      for (final fixture in _fixtures()) {
        final repository = fixture.repository;
        addTearDown(fixture.close);
        final session = _session(
          'session-1',
        ).copyWith(phase: LearningSessionPhase.learn, revealedHintCount: 0);
        await repository.recordAttempt(
          _attempt('local-hint', answer: 'concept', kind: AttemptKind.hint),
        );

        final stale = await repository.mergeProgress(
          attempts: [],
          studyState: null,
          session: session,
        );
        expect(stale.importedSession, isFalse);
        expect(await repository.loadSession(), isNull);

        final current = await repository.mergeProgress(
          attempts: [],
          studyState: null,
          session: session.copyWith(revealedHintCount: 1),
        );
        expect(current.importedSession, isTrue);
        expect((await repository.loadSession())?.revealedHintCount, 1);
      }
    });

    test('a later Study serial blocks a stale snapshot', () async {
      for (final fixture in _fixtures()) {
        final repository = fixture.repository;
        addTearDown(fixture.close);
        final state = StudyState(
          plan: StudyPlanner().plan(
            'number-fluency',
            const [],
            DateTime.utc(2026, 9, 20),
          ),
          sessionId: 'study-session',
        ).encode();

        final result = await repository.mergeProgress(
          attempts: [_attempt('study-session.1', sessionId: 'study-session')],
          studyState: state,
        );

        expect(result.importedStudyState, isFalse);
        expect(await repository.loadStudyState(), isNull);
      }
    });

    test(
      'a SQLite write interruption rolls back attempts and study state',
      () async {
        final database = sqlite3.openInMemory();
        final repository = SqliteProgressRepository(database);
        addTearDown(repository.close);
        database.execute('''
        CREATE TRIGGER interrupt_recovery
        BEFORE INSERT ON attempt_events
        WHEN NEW.event_id = 'interrupt'
        BEGIN
          SELECT RAISE(ABORT, 'simulated interruption');
        END
      ''');

        await expectLater(
          repository.mergeProgress(
            attempts: [_attempt('before-interrupt'), _attempt('interrupt')],
            studyState: StudyState(
              plan: StudyPlanner().plan(
                'number-fluency',
                const [],
                DateTime.utc(2026, 9, 20),
              ),
              sessionId: 'not-committed',
            ).encode(),
          ),
          throwsA(anything),
        );

        expect(await repository.loadAttempts(), isEmpty);
        expect(await repository.loadStudyState(), isNull);
      },
    );

    test('SQLite restores a session only when local work is absent', () async {
      final database = sqlite3.openInMemory();
      final repository = SqliteProgressRepository(database);
      addTearDown(repository.close);
      final imported = _session('imported');

      final restored = await repository.mergeProgress(
        attempts: const [],
        studyState: null,
        session: imported,
      );
      expect(restored.importedSession, isTrue);
      expect((await repository.loadSession())?.id, 'imported');

      final protected = await repository.mergeProgress(
        attempts: const [],
        studyState: null,
        session: _session('replacement'),
      );
      expect(protected.importedSession, isFalse);
      expect((await repository.loadSession())?.id, 'imported');
    });

    test('SQLite recovery cannot yield its open transaction', () async {
      final database = sqlite3.openInMemory();
      final repository = SqliteProgressRepository(database);
      addTearDown(repository.close);
      final transition = repository as LearningTransitionRepository;

      final merge = repository.mergeProgress(
        attempts: [_attempt('imported')],
        studyState: null,
        session: _session('imported-session'),
      );
      final commit = transition.commitLearningAttempt(
        _attempt('concurrent'),
        _session('concurrent-session'),
      );

      final results = await Future.wait([merge, commit]);

      expect((results.first as ProgressMergeResult).insertedAttemptCount, 1);
      expect(results.last, isTrue);
      expect(await repository.loadAttempts(), hasLength(2));
    });

    test('SQLite rolls back all writes when session import fails', () async {
      final database = sqlite3.openInMemory();
      final repository = SqliteProgressRepository(database);
      addTearDown(repository.close);
      database.execute('''
        CREATE TRIGGER interrupt_session_recovery
        BEFORE INSERT ON active_session
        BEGIN
          SELECT RAISE(ABORT, 'simulated session interruption');
        END
      ''');

      await expectLater(
        repository.mergeProgress(
          attempts: [_attempt('rolled-back')],
          studyState: const StudyState().encode(),
          session: _session('interrupted'),
        ),
        throwsA(anything),
      );

      expect(await repository.loadAttempts(), isEmpty);
      expect(await repository.loadStudyState(), isNull);
      expect(await repository.loadSession(), isNull);
    });
  });
}

LearningSession _session(String id) => LearningSession(
  answerDraft: '12',
  currentQuestionIndex: 3,
  focusSkillId: 'arithmetic.addition',
  id: id,
  seed: 42,
  startedAt: DateTime.utc(2026, 9, 20, 9),
);

List<({ProgressRepository repository, Future<void> Function() close})>
_fixtures() {
  final database = sqlite3.openInMemory();
  final sqliteRepository = SqliteProgressRepository(database);
  final memoryRepository = InMemoryProgressRepository();
  return [
    (repository: memoryRepository, close: memoryRepository.close),
    (repository: sqliteRepository, close: sqliteRepository.close),
  ];
}

AttemptEvent _attempt(
  String id, {
  String answer = '4',
  DateTime? occurredAt,
  Duration responseTime = const Duration(milliseconds: 500),
  bool isCorrect = true,
  AttemptKind kind = AttemptKind.answer,
  String? questionId,
  String? relatedEventId,
  String sessionId = 'session-1',
}) {
  return AttemptEvent(
    answer: answer,
    eventId: id,
    isCorrect: isCorrect,
    kind: kind,
    occurredAt: occurredAt ?? DateTime.utc(2026, 9, 20, 10),
    questionId: questionId ?? 'question-$id',
    relatedEventId: relatedEventId,
    responseTime: responseTime,
    sessionId: sessionId,
    skillId: 'arithmetic.addition',
  );
}
