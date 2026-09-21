import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:remath/src/app.dart';
import 'package:remath/src/features/backup/application/backup_file_transfer.dart';
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

  testWidgets('home refreshes cached progress after returning from recovery', (
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

    expect(find.text('1 attempt • 100% accuracy'), findsOneWidget);
  });
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
