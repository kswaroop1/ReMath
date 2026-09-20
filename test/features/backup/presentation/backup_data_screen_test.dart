import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:remath/src/features/backup/application/backup_coordinator.dart';
import 'package:remath/src/features/backup/application/backup_file_transfer.dart';
import 'package:remath/src/features/backup/data/password_backup_cipher.dart';
import 'package:remath/src/features/backup/presentation/backup_data_screen.dart';
import 'package:remath/src/features/learning/data/in_memory_progress_repository.dart';
import 'package:remath/src/features/learning/domain/attempt_event.dart';

void main() {
  group('backup data screen', () {
    testWidgets('requires password confirmation before encrypted export', (
      tester,
    ) async {
      final files = _MemoryBackupFiles();
      await tester.pumpWidget(
        MaterialApp(home: BackupDataScreen(transfer: _transfer(files: files))),
      );

      await tester.enterText(
        find.byKey(const ValueKey('backup-password')),
        'password',
      );
      await tester.enterText(
        find.byKey(const ValueKey('backup-confirm-password')),
        'different',
      );
      await tester.tap(find.text('Export encrypted backup'));
      await tester.pumpAndSettle();

      expect(find.text('Passwords do not match.'), findsOneWidget);
      expect(files.savedContents, isNull);

      await tester.enterText(
        find.byKey(const ValueKey('backup-confirm-password')),
        'password',
      );
      await tester.tap(find.text('Export encrypted backup'));
      await _pumpUntilFound(tester, find.text('Backup saved.'));

      expect(files.savedContents, contains('ciphertext'));
      expect(find.text('Backup saved.'), findsOneWidget);
    });

    testWidgets('shows a read-only preview before explicit recovery', (
      tester,
    ) async {
      final source = InMemoryProgressRepository();
      await source.recordAttempt(_attempt('event-1'));
      final encrypted = await _coordinator(
        repository: source,
      ).export(password: 'password');
      final files = _MemoryBackupFiles()..contentsToOpen = encrypted;
      final target = InMemoryProgressRepository();
      await tester.pumpWidget(
        MaterialApp(
          home: BackupDataScreen(
            transfer: _transfer(files: files, repository: target),
          ),
        ),
      );

      await tester.enterText(
        find.byKey(const ValueKey('backup-password')),
        'password',
      );
      await tester.tap(find.text('Preview backup'));
      await _pumpUntilFound(tester, find.text('1 new'));

      expect(find.text('1 new'), findsOneWidget);
      expect(find.text('0 duplicates'), findsOneWidget);
      expect(find.text('0 conflicts'), findsOneWidget);
      expect(await target.loadAttempts(), isEmpty);

      await tester.tap(find.text('Apply backup'));
      await tester.pumpAndSettle();

      expect((await target.loadAttempts()).single.eventId, 'event-1');
      expect(find.text('1 attempt restored.'), findsOneWidget);
    });
  });
}

Future<void> _pumpUntilFound(WidgetTester tester, Finder finder) async {
  for (var attempt = 0; attempt < 300 && finder.evaluate().isEmpty; attempt++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pump();
  }
  expect(finder, findsOneWidget);
}

BackupFileTransfer _transfer({
  required _MemoryBackupFiles files,
  InMemoryProgressRepository? repository,
}) {
  return BackupFileTransfer(
    coordinator: _coordinator(repository: repository),
    files: files,
  );
}

BackupCoordinator _coordinator({InMemoryProgressRepository? repository}) {
  return BackupCoordinator(
    cipher: PasswordBackupCipher(
      randomBytes: (length) => List<int>.generate(length, (index) => index),
    ),
    clock: () => DateTime.utc(2026, 9, 20, 12),
    repository: repository ?? InMemoryProgressRepository(),
  );
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

final class _MemoryBackupFiles implements BackupFileBoundary {
  String? contentsToOpen;
  String? savedContents;

  @override
  Future<String?> openText() async => contentsToOpen;

  @override
  Future<bool> saveText({
    required String contents,
    required String suggestedName,
  }) async {
    savedContents = contents;
    return true;
  }
}
