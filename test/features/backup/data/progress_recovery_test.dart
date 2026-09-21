import 'package:flutter_test/flutter_test.dart';
import 'package:remath/src/features/learning/data/in_memory_progress_repository.dart';
import 'package:remath/src/features/learning/data/sqlite_progress_repository.dart';
import 'package:remath/src/features/learning/domain/attempt_event.dart';
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

          final first = await repository.mergeProgress(
            attempts: attempts,
            studyState: '{"phase":"question"}',
          );
          final retry = await repository.mergeProgress(
            attempts: attempts,
            studyState: '{"phase":"question"}',
          );

          expect(first.insertedAttemptCount, 2);
          expect(first.duplicateAttemptCount, 0);
          expect(first.importedStudyState, isTrue);
          expect(retry.insertedAttemptCount, 0);
          expect(retry.duplicateAttemptCount, 2);
          expect(retry.importedStudyState, isFalse);
          expect(await repository.loadAttempts(), hasLength(2));
          expect(await repository.loadStudyState(), '{"phase":"question"}');
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
          throwsA(isA<ProgressConflictException>()),
        );

        expect(
          (await repository.loadAttempts()).map((event) => event.eventId),
          ['existing'],
        );
        expect(await repository.loadStudyState(), 'local-state');
      }
    });

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
  });
}

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

AttemptEvent _attempt(String id, {String answer = '4'}) {
  return AttemptEvent(
    answer: answer,
    eventId: id,
    isCorrect: true,
    occurredAt: DateTime.utc(2026, 9, 20, 10),
    questionId: 'question-$id',
    responseTime: const Duration(milliseconds: 500),
    sessionId: 'session-1',
    skillId: 'arithmetic.addition',
  );
}
