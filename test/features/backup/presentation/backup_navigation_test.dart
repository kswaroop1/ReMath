import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:remath/src/app.dart';
import 'package:remath/src/features/backup/application/backup_coordinator.dart';
import 'package:remath/src/features/backup/application/backup_file_transfer.dart';
import 'package:remath/src/features/backup/data/password_backup_cipher.dart';
import 'package:remath/src/features/home/presentation/home_screen.dart';
import 'package:remath/src/features/learning/data/in_memory_progress_repository.dart';
import 'package:remath/src/features/learning/domain/attempt_event.dart';

import '../../../support/foundation_pack.dart';

void main() {
  testWidgets('home opens the portable backup and recovery journey', (
    tester,
  ) async {
    await tester.pumpWidget(
      ReMathApp(
        backupFiles: const _CancelledBackupFiles(),
        contentPack: foundationPackForTest(),
        repository: InMemoryProgressRepository(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Backup and recovery'));
    await tester.pumpAndSettle();

    expect(find.byType(TextField), findsNWidgets(2));
    expect(find.text('Export encrypted backup'), findsOneWidget);
    expect(find.text('Preview backup'), findsOneWidget);
  });

  testWidgets('home preserves cached session after leaving without recovery', (
    tester,
  ) async {
    final repository = InMemoryProgressRepository();
    await tester.pumpWidget(
      ReMathApp(
        backupFiles: const _CancelledBackupFiles(),
        contentPack: foundationPackForTest(),
        repository: repository,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('0 attempts • 0% accuracy'), findsOneWidget);

    await tester.tap(find.text('Backup and recovery'));
    await tester.pumpAndSettle();
    await repository.recordAttempt(
      AttemptEvent(
        answer: '4',
        eventId: 'recovered-attempt',
        isCorrect: true,
        occurredAt: DateTime.utc(2026, 9, 21),
        questionId: 'addition.level0.recovered',
        responseTime: const Duration(seconds: 2),
        sessionId: 'recovered-session',
        skillId: 'arithmetic.addition',
      ),
    );
    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(find.text('0 attempts • 0% accuracy'), findsOneWidget);
  });

  testWidgets('home refreshes cached progress after successful recovery', (
    tester,
  ) async {
    final source = InMemoryProgressRepository();
    await source.recordAttempt(
      AttemptEvent(
        answer: '4',
        eventId: 'imported-attempt',
        isCorrect: true,
        occurredAt: DateTime.utc(2026, 9, 21),
        questionId: 'addition.level0.imported',
        responseTime: const Duration(seconds: 2),
        sessionId: 'imported-session',
        skillId: 'arithmetic.addition',
      ),
    );
    final encrypted = await _coordinator(source).export(password: 'password');
    final target = InMemoryProgressRepository();
    final transfer = BackupFileTransfer(
      coordinator: _coordinator(target),
      files: _ImportBackupFiles(encrypted),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(
          backupTransfer: transfer,
          contentPack: foundationPackForTest(),
          repository: target,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Backup and recovery'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('backup-password')),
      'password',
    );
    await tester.tap(find.text('Preview backup'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Apply backup'));
    await tester.tap(find.text('Apply backup'));
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(find.text('1 attempts • 100% accuracy'), findsOneWidget);
  });
}

BackupCoordinator _coordinator(InMemoryProgressRepository repository) {
  return BackupCoordinator(
    cipher: const _TestBackupCipher(),
    clock: () => DateTime.utc(2026, 9, 27),
    repository: repository,
  );
}

final class _ImportBackupFiles implements BackupFileBoundary {
  const _ImportBackupFiles(this.contents);

  final String contents;

  @override
  Future<String?> openText() async => contents;

  @override
  Future<bool> saveText({
    required String contents,
    required String suggestedName,
  }) async => false;
}

final class _TestBackupCipher implements BackupCipher {
  const _TestBackupCipher();

  @override
  Future<String> decrypt(String source, {required String password}) async {
    return source.substring('ciphertext:'.length);
  }

  @override
  Future<String> encrypt({
    required String plaintext,
    required String password,
  }) async => 'ciphertext:$plaintext';
}

final class _CancelledBackupFiles implements BackupFileBoundary {
  const _CancelledBackupFiles();

  @override
  Future<String?> openText() async => null;

  @override
  Future<bool> saveText({
    required String contents,
    required String suggestedName,
  }) async => false;
}
