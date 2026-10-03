import 'package:flutter_test/flutter_test.dart';
import 'package:remath/src/features/backup/application/backup_coordinator.dart';
import 'package:remath/src/features/backup/data/password_backup_cipher.dart';
import 'package:remath/src/features/backup/domain/backup_payload.dart';
import 'package:remath/src/features/learning/data/in_memory_progress_repository.dart';
import 'package:remath/src/features/learning/domain/attempt_event.dart';
import 'package:remath/src/features/learning/domain/learning_session.dart';
import 'package:remath/src/features/learning/domain/progress_repository.dart';
import 'package:remath/src/features/numbers/domain/study_curriculum.dart';
import 'package:remath/src/features/numbers/domain/study_plan.dart';

void main() {
  group('backup coordinator', () {
    const password = 'portable backup password';
    final cipher = PasswordBackupCipher(
      randomBytes: (length) => List<int>.generate(length, (index) => index),
    );

    test('exports, previews without writes, then applies explicitly', () async {
      final source = InMemoryProgressRepository();
      await source.recordAttempt(
        _attempt('event-1', isCorrect: false, sessionId: 'portable-session'),
      );
      final exporter = BackupCoordinator(
        cipher: cipher,
        clock: () => DateTime.utc(2026, 9, 20, 12),
        repository: source,
      );

      final encrypted = await exporter.export(password: password);
      final target = InMemoryProgressRepository();
      final importer = BackupCoordinator(
        cipher: cipher,
        clock: () => DateTime.utc(2026, 9, 20, 13),
        repository: target,
      );
      final pending = await importer.preview(encrypted, password: password);

      expect(pending.preview.createdAt, DateTime.utc(2026, 9, 20, 12));
      expect(pending.preview.newAttemptCount, 1);
      expect(await target.loadAttempts(), isEmpty);

      final result = await importer.apply(pending);

      expect(result.insertedAttemptCount, 1);
      expect((await target.loadAttempts()).single.eventId, 'event-1');
    });

    test('export snapshots attempts and active state atomically', () async {
      final repository = _ChangingExportRepository();
      final encrypted = await BackupCoordinator(
        cipher: cipher,
        clock: () => DateTime.utc(2026, 9, 20, 12),
        repository: repository,
      ).export(password: password);

      final payload = BackupPayload.decode(
        await cipher.decrypt(encrypted, password: password),
      );

      expect(payload.attempts.single.eventId, 'event-1');
      expect(payload.session?.correctionOfEventId, 'event-1');
    });

    test('preview rejects an unsafe active-study snapshot', () async {
      final payload = BackupPayload(
        attempts: const [],
        createdAt: DateTime.utc(2026, 9, 20, 12),
        studyState: '{"formatVersion":999}',
      );
      final encrypted = await cipher.encrypt(
        plaintext: payload.encode(),
        password: password,
      );
      final coordinator = BackupCoordinator(
        cipher: cipher,
        clock: DateTime.now,
        repository: InMemoryProgressRepository(),
      );

      await expectLater(
        coordinator.preview(encrypted, password: password),
        throwsFormatException,
      );
    });

    test('preview rejects active study without a session identity', () async {
      final payload = BackupPayload(
        attempts: const [],
        createdAt: DateTime.utc(2026, 9, 20, 12),
        studyState: StudyState(
          plan: StudyPlanner().plan(
            'number-fluency',
            const [],
            DateTime.utc(2026, 9, 20),
          ),
        ).encode(),
      );
      final encrypted = await cipher.encrypt(
        plaintext: payload.encode(),
        password: password,
      );
      final coordinator = BackupCoordinator(
        cipher: cipher,
        clock: DateTime.now,
        repository: InMemoryProgressRepository(),
      );

      await expectLater(
        coordinator.preview(encrypted, password: password),
        throwsFormatException,
      );
    });

    test('cannot apply a preview containing immutable conflicts', () async {
      final source = InMemoryProgressRepository();
      await source.recordAttempt(_attempt('conflict'));
      final encrypted = await BackupCoordinator(
        cipher: cipher,
        clock: () => DateTime.utc(2026, 9, 20, 12),
        repository: source,
      ).export(password: password);
      final target = InMemoryProgressRepository();
      await target.recordAttempt(_attempt('conflict', answer: 'different'));
      final importer = BackupCoordinator(
        cipher: cipher,
        clock: DateTime.now,
        repository: target,
      );
      final pending = await importer.preview(encrypted, password: password);

      expect(pending.preview.canApply, isFalse);
      expect(() => importer.apply(pending), throwsStateError);
    });

    test('portable backup restores an active learning session', () async {
      final source = InMemoryProgressRepository();
      await source.recordAttempt(
        _attempt('event-1', isCorrect: false, sessionId: 'portable-session'),
      );
      await source.saveSession(_session('portable-session'));
      final exporter = BackupCoordinator(
        cipher: cipher,
        clock: () => DateTime.utc(2026, 9, 20, 12),
        repository: source,
      );
      final encrypted = await exporter.export(password: password);
      final target = InMemoryProgressRepository();
      final importer = BackupCoordinator(
        cipher: cipher,
        clock: DateTime.now,
        repository: target,
      );

      final pending = await importer.preview(encrypted, password: password);
      final result = await importer.apply(pending);

      expect(result.importedSession, isTrue);
      final restored = await target.loadSession();
      expect(restored?.id, 'portable-session');
      expect(restored?.answerDraft, '12');
      expect(restored?.currentQuestionIndex, 3);
      expect(restored?.correctionOfEventId, 'event-1');
      expect(restored?.focusSkillId, 'arithmetic.addition');
      expect(restored?.phase, LearningSessionPhase.correction);
      expect(restored?.revealedHintCount, 2);
      expect(restored?.seed, 42);
      expect(restored?.startedAt, DateTime.utc(2026, 9, 20, 10));
    });

    test('portable backup never replaces a local active session', () async {
      final source = InMemoryProgressRepository();
      await source.recordAttempt(
        _attempt('event-1', isCorrect: false, sessionId: 'imported-session'),
      );
      await source.saveSession(_session('imported-session'));
      final exporter = BackupCoordinator(
        cipher: cipher,
        clock: () => DateTime.utc(2026, 9, 20, 12),
        repository: source,
      );
      final encrypted = await exporter.export(password: password);
      final target = InMemoryProgressRepository();
      await target.saveSession(_session('local-session'));
      final importer = BackupCoordinator(
        cipher: cipher,
        clock: DateTime.now,
        repository: target,
      );

      final pending = await importer.preview(encrypted, password: password);
      final result = await importer.apply(pending);

      expect(result.importedSession, isFalse);
      expect((await target.loadSession())?.id, 'local-session');
    });

    test(
      'preview rejects an incompatible generated question identity',
      () async {
        final source = InMemoryProgressRepository();
        await source.saveSession(
          _session('incompatible').copyWith(
            questionId: 'retired-pack.addition.v9.42.3',
            questionSkillId: 'arithmetic.addition',
          ),
        );
        final exporter = BackupCoordinator(
          cipher: cipher,
          clock: () => DateTime.utc(2026, 9, 20, 12),
          repository: source,
        );
        final encrypted = await exporter.export(password: password);
        final importer = BackupCoordinator(
          cipher: cipher,
          clock: DateTime.now,
          repository: InMemoryProgressRepository(),
          sessionValidator: (_) => false,
        );

        await expectLater(
          importer.preview(encrypted, password: password),
          throwsFormatException,
        );
      },
    );

    test(
      'preview rejects remediation without an originating attempt',
      () async {
        for (final correctionOfEventId in <String?>[null, 'missing-event']) {
          final payload = BackupPayload(
            attempts: const [],
            createdAt: DateTime.utc(2026, 9, 20, 12),
            session: LearningSession(
              correctionOfEventId: correctionOfEventId,
              currentQuestionIndex: 3,
              focusSkillId: 'arithmetic.addition',
              id: 'orphaned-remediation',
              phase: LearningSessionPhase.correction,
              seed: 42,
              startedAt: DateTime.utc(2026, 9, 20, 10),
            ),
            studyState: null,
          );
          final encrypted = await cipher.encrypt(
            plaintext: payload.encode(),
            password: password,
          );
          final coordinator = BackupCoordinator(
            cipher: cipher,
            clock: DateTime.now,
            repository: InMemoryProgressRepository(),
          );

          await expectLater(
            coordinator.preview(encrypted, password: password),
            throwsFormatException,
          );
        }
      },
    );

    test('preview rejects orphaned active-study remediation', () async {
      for (final relatedEventId in <String?>[null, 'missing-event']) {
        final payload = BackupPayload(
          attempts: const [],
          createdAt: DateTime.utc(2026, 9, 20, 12),
          studyState: StudyState(
            phase: StudyPhase.correction,
            plan: StudyPlanner().plan(
              'number-fluency',
              const [],
              DateTime.utc(2026, 9, 20),
            ),
            relatedEventId: relatedEventId,
            sessionId: 'orphaned-study',
          ).encode(),
        );
        final encrypted = await cipher.encrypt(
          plaintext: payload.encode(),
          password: password,
        );

        await expectLater(
          BackupCoordinator(
            cipher: cipher,
            clock: DateTime.now,
            repository: InMemoryProgressRepository(),
          ).preview(encrypted, password: password),
          throwsFormatException,
        );
      }
    });

    test(
      'preview rejects remediation linked to an unrelated attempt',
      () async {
        for (final attempt in [
          _attempt('event-1', sessionId: 'different-session'),
          _attempt('event-1', skillId: 'arithmetic.multiplication'),
        ]) {
          final payload = BackupPayload(
            attempts: [attempt],
            createdAt: DateTime.utc(2026, 9, 20, 12),
            session: _session('session-1'),
            studyState: null,
          );
          final encrypted = await cipher.encrypt(
            plaintext: payload.encode(),
            password: password,
          );

          await expectLater(
            BackupCoordinator(
              cipher: cipher,
              clock: DateTime.now,
              repository: InMemoryProgressRepository(),
            ).preview(encrypted, password: password),
            throwsFormatException,
          );
        }
      },
    );

    test(
      'preview rejects remediation linked to a successful attempt',
      () async {
        final payload = BackupPayload(
          attempts: [_attempt('event-1')],
          createdAt: DateTime.utc(2026, 9, 20, 12),
          session: _session('session-1'),
          studyState: null,
        );
        final encrypted = await cipher.encrypt(
          plaintext: payload.encode(),
          password: password,
        );

        await expectLater(
          BackupCoordinator(
            cipher: cipher,
            clock: DateTime.now,
            repository: InMemoryProgressRepository(),
          ).preview(encrypted, password: password),
          throwsFormatException,
        );
      },
    );

    test('preview rejects correction linked to another question', () async {
      final payload = BackupPayload(
        attempts: [
          _attempt('event-1', isCorrect: false, questionId: 'question-earlier'),
        ],
        createdAt: DateTime.utc(2026, 9, 20, 12),
        session: _session('session-1').copyWith(
          questionId: 'question-current',
          questionSkillId: 'arithmetic.addition',
        ),
        studyState: null,
      );
      final encrypted = await cipher.encrypt(
        plaintext: payload.encode(),
        password: password,
      );

      await expectLater(
        BackupCoordinator(
          cipher: cipher,
          clock: DateTime.now,
          repository: InMemoryProgressRepository(),
        ).preview(encrypted, password: password),
        throwsFormatException,
      );
    });

    test(
      'preview resolves legacy correction identity before validation',
      () async {
        final payload = BackupPayload(
          attempts: [
            _attempt(
              'event-1',
              isCorrect: false,
              questionId: 'question-earlier',
            ),
          ],
          createdAt: DateTime.utc(2026, 9, 20, 12),
          session: LearningSession(
            answerDraft: '12',
            correctionOfEventId: 'event-1',
            currentQuestionIndex: 3,
            focusSkillId: 'arithmetic.addition',
            id: 'session-1',
            phase: LearningSessionPhase.correction,
            revealedHintCount: 2,
            seed: 42,
            startedAt: DateTime.utc(2026, 9, 20, 10),
          ),
          studyState: null,
        );
        final encrypted = await cipher.encrypt(
          plaintext: payload.encode(),
          password: password,
        );

        await expectLater(
          BackupCoordinator(
            cipher: cipher,
            clock: DateTime.now,
            repository: InMemoryProgressRepository(),
            sessionQuestionIdResolver: (_) => 'question-current',
          ).preview(encrypted, password: password),
          throwsFormatException,
        );
      },
    );

    test(
      'preview accepts failed Home remediation attempts as origins',
      () async {
        for (final kind in [AttemptKind.correction, AttemptKind.retest]) {
          final payload = BackupPayload(
            attempts: [
              _attempt(
                'event-1',
                isCorrect: false,
                kind: kind,
                sessionId: 'session-1',
              ),
            ],
            createdAt: DateTime.utc(2026, 9, 20, 12),
            session: _session('session-1'),
            studyState: null,
          );
          final encrypted = await cipher.encrypt(
            plaintext: payload.encode(),
            password: password,
          );

          final pending = await BackupCoordinator(
            cipher: cipher,
            clock: DateTime.now,
            repository: InMemoryProgressRepository(),
          ).preview(encrypted, password: password);

          expect(pending.preview.hasLearningSession, isTrue);
        }
      },
    );

    test('preview rejects a failed correction as a Home origin', () async {
      final payload = BackupPayload(
        attempts: [
          _attempt(
            'event-1',
            isCorrect: false,
            kind: AttemptKind.correction,
            sessionId: 'session-1',
          ),
        ],
        createdAt: DateTime.utc(2026, 9, 20, 12),
        session: _session('session-1'),
        studyState: null,
      );
      final encrypted = await cipher.encrypt(
        plaintext: payload.encode(),
        password: password,
      );

      await expectLater(
        BackupCoordinator(
          cipher: cipher,
          clock: DateTime.now,
          repository: InMemoryProgressRepository(),
        ).preview(encrypted, password: password),
        throwsFormatException,
      );
    });

    test('preview accepts consistently linked study remediation', () async {
      final state = StudyState(
        phase: StudyPhase.correction,
        plan: StudyPlanner().plan(
          'number-fluency',
          const [],
          DateTime.utc(2026, 9, 20),
        ),
        relatedEventId: 'event-1',
        sessionId: 'study-session',
      );
      final payload = BackupPayload(
        attempts: [
          _attempt(
            'event-1',
            isCorrect: false,
            questionId: _questionIdForState(state),
            sessionId: 'study-session',
          ),
        ],
        createdAt: DateTime.utc(2026, 9, 20, 12),
        studyState: state.encode(),
      );
      final encrypted = await cipher.encrypt(
        plaintext: payload.encode(),
        password: password,
      );

      final pending = await BackupCoordinator(
        cipher: cipher,
        clock: DateTime.now,
        repository: InMemoryProgressRepository(),
      ).preview(encrypted, password: password);

      expect(pending.preview.hasStudyState, isTrue);
    });

    test(
      'preview rejects study correction linked to another question',
      () async {
        final payload = BackupPayload(
          attempts: [
            _attempt(
              'event-1',
              isCorrect: false,
              questionId: 'question-earlier',
              sessionId: 'study-session',
            ),
          ],
          createdAt: DateTime.utc(2026, 9, 20, 12),
          studyState: StudyState(
            phase: StudyPhase.correction,
            plan: StudyPlan(
              steps: const [
                StudyStep(StudyStepKind.practice, 'arithmetic.addition', 1),
              ],
              reason: 'Focused practice',
            ),
            relatedEventId: 'event-1',
            sessionId: 'study-session',
          ).encode(),
        );
        final encrypted = await cipher.encrypt(
          plaintext: payload.encode(),
          password: password,
        );

        await expectLater(
          BackupCoordinator(
            cipher: cipher,
            clock: DateTime.now,
            repository: InMemoryProgressRepository(),
          ).preview(encrypted, password: password),
          throwsFormatException,
        );
      },
    );

    test(
      'preview accepts failed study remediation attempts as origins',
      () async {
        for (final kind in [AttemptKind.correction, AttemptKind.retest]) {
          final state = StudyState(
            phase: StudyPhase.correction,
            plan: StudyPlan(
              steps: const [
                StudyStep(StudyStepKind.practice, 'arithmetic.addition', 1),
              ],
              reason: 'Focused practice',
            ),
            relatedEventId: 'event-1',
            sessionId: 'study-session',
          );
          final payload = BackupPayload(
            attempts: [
              _attempt(
                'event-1',
                isCorrect: false,
                kind: kind,
                questionId: _questionIdForState(state),
                sessionId: 'study-session',
              ),
            ],
            createdAt: DateTime.utc(2026, 9, 20, 12),
            studyState: state.encode(),
          );
          final encrypted = await cipher.encrypt(
            plaintext: payload.encode(),
            password: password,
          );

          final pending = await BackupCoordinator(
            cipher: cipher,
            clock: DateTime.now,
            repository: InMemoryProgressRepository(),
          ).preview(encrypted, password: password);

          expect(pending.preview.hasStudyState, isTrue);
        }
      },
    );

    test('preview accepts repeated multiple-choice remediation', () async {
      final state = StudyState(
        phase: StudyPhase.correction,
        plan: StudyPlan(
          steps: const [
            StudyStep(
              StudyStepKind.practice,
              'arithmetic.addition',
              1,
              multipleChoice: true,
            ),
          ],
          reason: 'Focused practice',
        ),
        relatedEventId: 'event-1',
        sessionId: 'study-session',
      );
      final payload = BackupPayload(
        attempts: [
          _attempt(
            'event-1',
            isCorrect: false,
            kind: AttemptKind.correction,
            questionId: _questionIdForState(state).replaceFirst('.mcq', ''),
            sessionId: 'study-session',
          ),
        ],
        createdAt: DateTime.utc(2026, 9, 20, 12),
        studyState: state.encode(),
      );
      final encrypted = await cipher.encrypt(
        plaintext: payload.encode(),
        password: password,
      );

      final pending = await BackupCoordinator(
        cipher: cipher,
        clock: DateTime.now,
        repository: InMemoryProgressRepository(),
      ).preview(encrypted, password: password);

      expect(pending.preview.hasStudyState, isTrue);
    });

    test(
      'preview accepts a successful hinted answer as retest origin',
      () async {
        final retest = StudyState(
          phase: StudyPhase.retest,
          plan: StudyPlan(
            steps: const [
              StudyStep(StudyStepKind.practice, 'arithmetic.addition', 1),
            ],
            reason: 'Focused practice',
          ),
          questionIndex: 4,
          relatedEventId: 'assisted-answer',
          sessionId: 'study-session',
        );
        final origin = retest.copyWith(questionIndex: 3);
        final encrypted = await cipher.encrypt(
          plaintext: BackupPayload(
            attempts: [
              _attempt(
                'assisted-answer',
                kind: AttemptKind.correction,
                questionId: _questionIdForState(origin),
                sessionId: 'study-session',
              ),
            ],
            createdAt: DateTime.utc(2026, 9, 20, 12),
            studyState: retest.encode(),
          ).encode(),
          password: password,
        );

        final pending = await BackupCoordinator(
          cipher: cipher,
          clock: DateTime.now,
          repository: InMemoryProgressRepository(),
        ).preview(encrypted, password: password);

        expect(pending.preview.hasStudyState, isTrue);
      },
    );

    test('preview binds Home retest to the preceding question', () async {
      final session = _session(
        'session-1',
      ).copyWith(currentQuestionIndex: 4, phase: LearningSessionPhase.retest);
      final encrypted = await cipher.encrypt(
        plaintext: BackupPayload(
          attempts: [
            _attempt('event-1', isCorrect: false, questionId: 'question-0'),
          ],
          createdAt: DateTime.utc(2026, 9, 20, 12),
          session: session,
          studyState: null,
        ).encode(),
        password: password,
      );

      await expectLater(
        BackupCoordinator(
          cipher: cipher,
          clock: DateTime.now,
          repository: InMemoryProgressRepository(),
          sessionQuestionIdResolver: (candidate) =>
              'question-${candidate.currentQuestionIndex}',
        ).preview(encrypted, password: password),
        throwsFormatException,
      );
    });

    test('preview binds study retest to the preceding question', () async {
      final retest = StudyState(
        phase: StudyPhase.retest,
        plan: StudyPlan(
          steps: const [
            StudyStep(
              StudyStepKind.practice,
              'arithmetic.addition',
              1,
              multipleChoice: true,
            ),
          ],
          reason: 'Focused practice',
        ),
        questionIndex: 4,
        relatedEventId: 'old-answer',
        sessionId: 'study-session',
      );
      final encrypted = await cipher.encrypt(
        plaintext: BackupPayload(
          attempts: [
            _attempt(
              'old-answer',
              isCorrect: false,
              questionId: _questionIdForState(
                retest.copyWith(questionIndex: 0),
              ),
              sessionId: 'study-session',
            ),
          ],
          createdAt: DateTime.utc(2026, 9, 20, 12),
          studyState: retest.encode(),
        ).encode(),
        password: password,
      );

      await expectLater(
        BackupCoordinator(
          cipher: cipher,
          clock: DateTime.now,
          repository: InMemoryProgressRepository(),
        ).preview(encrypted, password: password),
        throwsFormatException,
      );
    });

    test('preview rejects confidence retained by assisted study', () async {
      for (final state in [
        StudyState(
          confidence: ConfidenceRating.high,
          hintCount: 1,
          plan: StudyPlanner().plan(
            'number-fluency',
            const [],
            DateTime.utc(2026, 9, 20),
          ),
          sessionId: 'study-session',
        ),
        StudyState(
          confidence: ConfidenceRating.high,
          phase: StudyPhase.correction,
          plan: StudyPlanner().plan(
            'number-fluency',
            const [],
            DateTime.utc(2026, 9, 20),
          ),
          relatedEventId: 'event-1',
          sessionId: 'study-session',
        ),
      ]) {
        final encrypted = await cipher.encrypt(
          plaintext: BackupPayload(
            attempts: [
              _attempt(
                'event-1',
                isCorrect: false,
                questionId: _questionIdForState(state),
                sessionId: 'study-session',
              ),
            ],
            createdAt: DateTime.utc(2026, 9, 20, 12),
            studyState: state.encode(),
          ).encode(),
          password: password,
        );
        await expectLater(
          BackupCoordinator(
            cipher: cipher,
            clock: DateTime.now,
            repository: InMemoryProgressRepository(),
          ).preview(encrypted, password: password),
          throwsFormatException,
        );
      }
    });

    test('preview preserves unresolved legacy study correction', () async {
      final state = StudyState(
        generator: null,
        phase: StudyPhase.correction,
        plan: StudyPlan(
          steps: const [
            StudyStep(StudyStepKind.practice, 'number.fractions', 1),
          ],
          reason: 'Legacy practice',
        ),
        relatedEventId: 'event-1',
        sessionId: 'study-session',
      );
      final payload = BackupPayload(
        attempts: [
          _attempt(
            'event-1',
            isCorrect: false,
            questionId: _questionIdForState(state).split('.origin-').first,
            sessionId: 'study-session',
            skillId: 'number.fractions',
          ),
        ],
        createdAt: DateTime.utc(2026, 9, 20, 12),
        studyState: state.encode(),
      );
      final encrypted = await cipher.encrypt(
        plaintext: payload.encode(),
        password: password,
      );

      final pending = await BackupCoordinator(
        cipher: cipher,
        clock: DateTime.now,
        repository: InMemoryProgressRepository(),
      ).preview(encrypted, password: password);

      expect(pending.preview.hasStudyState, isTrue);
    });

    test(
      'preview rejects related events in question-phase study state',
      () async {
        final payload = BackupPayload(
          attempts: const [],
          createdAt: DateTime.utc(2026, 9, 20, 12),
          studyState: StudyState(
            plan: StudyPlanner().plan(
              'number-fluency',
              const [],
              DateTime.utc(2026, 9, 20),
            ),
            relatedEventId: 'dangling-event',
            sessionId: 'study-session',
          ).encode(),
        );
        final encrypted = await cipher.encrypt(
          plaintext: payload.encode(),
          password: password,
        );

        await expectLater(
          BackupCoordinator(
            cipher: cipher,
            clock: DateTime.now,
            repository: InMemoryProgressRepository(),
          ).preview(encrypted, password: password),
          throwsFormatException,
        );
      },
    );

    test('preview reports local conflicts before blocking apply', () async {
      final incoming = _attempt(
        'event-1',
        isCorrect: false,
        sessionId: 'session-1',
      );
      final payload = BackupPayload(
        attempts: [incoming],
        createdAt: DateTime.utc(2026, 9, 20, 12),
        session: _session('session-1'),
        studyState: null,
      );
      final encrypted = await cipher.encrypt(
        plaintext: payload.encode(),
        password: password,
      );
      final local = InMemoryProgressRepository();
      await local.recordAttempt(_attempt('event-1'));

      final pending = await BackupCoordinator(
        cipher: cipher,
        clock: DateTime.now,
        repository: local,
      ).preview(encrypted, password: password);

      expect(pending.preview.conflictingAttemptCount, 1);
      expect(pending.preview.canApply, isFalse);
    });

    test('preview rejects remediation in a diagnostic study', () async {
      final payload = BackupPayload(
        attempts: [_attempt('event-1', sessionId: 'diagnostic-study')],
        createdAt: DateTime.utc(2026, 9, 20, 12),
        studyState: StudyState(
          phase: StudyPhase.correction,
          plan: StudyPlanner().diagnostic('number-fluency'),
          relatedEventId: 'event-1',
          sessionId: 'diagnostic-study',
        ).encode(),
      );
      final encrypted = await cipher.encrypt(
        plaintext: payload.encode(),
        password: password,
      );

      await expectLater(
        BackupCoordinator(
          cipher: cipher,
          clock: DateTime.now,
          repository: InMemoryProgressRepository(),
        ).preview(encrypted, password: password),
        throwsFormatException,
      );
    });

    test('preview rejects hinted diagnostic study state', () async {
      final payload = BackupPayload(
        attempts: const [],
        createdAt: DateTime.utc(2026, 9, 20, 12),
        studyState: StudyState(
          hintCount: 1,
          plan: StudyPlanner().diagnostic('number-fluency'),
          sessionId: 'diagnostic-study',
        ).encode(),
      );
      final encrypted = await cipher.encrypt(
        plaintext: payload.encode(),
        password: password,
      );

      await expectLater(
        BackupCoordinator(
          cipher: cipher,
          clock: DateTime.now,
          repository: InMemoryProgressRepository(),
        ).preview(encrypted, password: password),
        throwsFormatException,
      );
    });

    test('preview rejects remediation on a non-question study step', () async {
      final payload = BackupPayload(
        attempts: [
          _attempt('event-1', isCorrect: false, sessionId: 'study-session'),
        ],
        createdAt: DateTime.utc(2026, 9, 20, 12),
        studyState: StudyState(
          phase: StudyPhase.correction,
          plan: StudyPlan(
            steps: const [
              StudyStep(StudyStepKind.learn, 'arithmetic.addition', 0),
            ],
            reason: 'Focused lesson',
          ),
          relatedEventId: 'event-1',
          sessionId: 'study-session',
        ).encode(),
      );
      final encrypted = await cipher.encrypt(
        plaintext: payload.encode(),
        password: password,
      );

      await expectLater(
        BackupCoordinator(
          cipher: cipher,
          clock: DateTime.now,
          repository: InMemoryProgressRepository(),
        ).preview(encrypted, password: password),
        throwsFormatException,
      );
    });
  });
}

LearningSession _session(String id) {
  return LearningSession(
    answerDraft: '12',
    correctionOfEventId: 'event-1',
    currentQuestionIndex: 3,
    focusSkillId: 'arithmetic.addition',
    id: id,
    phase: LearningSessionPhase.correction,
    questionId: 'question-event-1',
    questionSkillId: 'arithmetic.addition',
    revealedHintCount: 2,
    seed: 42,
    startedAt: DateTime.utc(2026, 9, 20, 10),
  );
}

AttemptEvent _attempt(
  String id, {
  String answer = '4',
  bool isCorrect = true,
  AttemptKind kind = AttemptKind.answer,
  String? questionId,
  String sessionId = 'session-1',
  String skillId = 'arithmetic.addition',
}) {
  return AttemptEvent(
    answer: answer,
    eventId: id,
    isCorrect: isCorrect,
    kind: kind,
    occurredAt: DateTime.utc(2026, 9, 20, 10),
    questionId: questionId ?? 'question-$id',
    responseTime: const Duration(milliseconds: 500),
    sessionId: sessionId,
    skillId: skillId,
  );
}

final class _ChangingExportRepository implements ProgressSnapshotRepository {
  final _delegate = InMemoryProgressRepository();
  var _attemptReads = 0;

  @override
  Future<ProgressSnapshot> loadSnapshot() async {
    await _delegate.recordAttempt(
      _attempt('event-1', isCorrect: false, sessionId: 'session-1'),
    );
    await _delegate.saveSession(_session('session-1'));
    return _delegate.loadSnapshot();
  }

  @override
  Future<List<AttemptEvent>> loadAttempts() async {
    _attemptReads++;
    if (_attemptReads == 1) {
      await _delegate.recordAttempt(
        _attempt('event-1', isCorrect: false, sessionId: 'session-1'),
      );
    }
    return _delegate.loadAttempts();
  }

  @override
  Future<LearningSession?> loadSession() async {
    final session = await _delegate.loadSession();
    await _delegate.saveSession(_session('session-1'));
    return session;
  }

  @override
  Future<String?> loadStudyState() => _delegate.loadStudyState();

  @override
  Future<bool> commitStudyAttempt(AttemptEvent event, String state) =>
      _delegate.commitStudyAttempt(event, state);
  @override
  Future<void> saveStudyState(String state) => _delegate.saveStudyState(state);
  @override
  Future<void> close() => _delegate.close();
  @override
  Future<void> completeSession(String sessionId) =>
      _delegate.completeSession(sessionId);
  @override
  Future<ProgressMergeResult> mergeProgress({
    required List<AttemptEvent> attempts,
    required String? studyState,
    LearningSession? session,
  }) => _delegate.mergeProgress(
    attempts: attempts,
    session: session,
    studyState: studyState,
  );
  @override
  Future<bool> recordAttempt(AttemptEvent event) =>
      _delegate.recordAttempt(event);
  @override
  Future<void> saveSession(LearningSession session) =>
      _delegate.saveSession(session);
}

String _questionIdForState(StudyState state) {
  final step = state.step!;
  final question = StudyCurriculum().question(
    step.skillId,
    step.level,
    state.seed,
    state.questionIndex,
    templateVersion: step.templateVersion,
    legacyBrowser: state.generator == 'legacy-browser',
    markingVersion: step.markingVersion,
    scoringVersion: step.scoringVersion,
  );
  var identity = question.id;
  if (step.templateVersion == 1 &&
      StudyCurriculum.currentTemplateVersion(question.skillId) == 2) {
    identity =
        '$identity.origin-${state.generator == 'legacy-browser' ? 'browser' : 'portable'}';
  }
  return step.multipleChoice ? '$identity.mcq' : identity;
}
