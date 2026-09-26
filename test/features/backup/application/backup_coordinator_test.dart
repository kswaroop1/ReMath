import 'package:flutter_test/flutter_test.dart';
import 'package:remath/src/features/backup/application/backup_coordinator.dart';
import 'package:remath/src/features/backup/data/password_backup_cipher.dart';
import 'package:remath/src/features/backup/domain/backup_payload.dart';
import 'package:remath/src/features/learning/data/in_memory_progress_repository.dart';
import 'package:remath/src/features/learning/domain/attempt_event.dart';
import 'package:remath/src/features/learning/domain/learning_session.dart';

void main() {
  group('backup coordinator', () {
    const password = 'portable backup password';
    final cipher = PasswordBackupCipher(
      randomBytes: (length) => List<int>.generate(length, (index) => index),
    );

    test('exports, previews without writes, then applies explicitly', () async {
      final source = InMemoryProgressRepository();
      await source.recordAttempt(_attempt('event-1'));
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
      await expectLater(importer.apply(pending), throwsStateError);
    });

    test('portable backup restores an active learning session', () async {
      final source = InMemoryProgressRepository();
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
    revealedHintCount: 2,
    seed: 42,
    startedAt: DateTime.utc(2026, 9, 20, 10),
  );
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
