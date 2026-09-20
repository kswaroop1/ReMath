import 'package:flutter_test/flutter_test.dart';
import 'package:remath/src/features/backup/application/backup_coordinator.dart';
import 'package:remath/src/features/backup/data/password_backup_cipher.dart';
import 'package:remath/src/features/backup/domain/backup_payload.dart';
import 'package:remath/src/features/learning/data/in_memory_progress_repository.dart';
import 'package:remath/src/features/learning/domain/attempt_event.dart';

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
  });
}

AttemptEvent _attempt(String id) {
  return AttemptEvent(
    answer: '4',
    eventId: id,
    isCorrect: true,
    occurredAt: DateTime.utc(2026, 9, 20, 10),
    questionId: 'question-$id',
    responseTime: const Duration(milliseconds: 500),
    sessionId: 'session-1',
    skillId: 'arithmetic.addition',
  );
}
