import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:remath/src/app.dart';
import 'package:remath/src/features/backup/application/backup_file_transfer.dart';
import 'package:remath/src/features/learning/data/in_memory_progress_repository.dart';

import '../../../support/foundation_content.dart';

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
