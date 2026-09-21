import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:remath/src/features/backup/data/file_picker_backup_boundary.dart';

void main() {
  test(
    'file picker boundary transfers backup text without changing bytes',
    () async {
      final gateway = _MemoryFilePickerGateway()
        ..openedBytes = utf8.encode('encrypted progress ✓');
      final boundary = FilePickerBackupBoundary(gateway: gateway);

      expect(await boundary.openText(), 'encrypted progress ✓');
      expect(
        await boundary.saveText(
          contents: 'portable backup ✓',
          suggestedName: 'remath-progress.remath-backup',
        ),
        isTrue,
      );
      expect(utf8.decode(gateway.savedBytes!), 'portable backup ✓');
      expect(gateway.savedName, 'remath-progress.remath-backup');
    },
  );

  test('file picker boundary preserves safe cancellation', () async {
    final gateway = _MemoryFilePickerGateway()..saveAccepted = false;
    final boundary = FilePickerBackupBoundary(gateway: gateway);

    expect(await boundary.openText(), isNull);
    expect(
      await boundary.saveText(contents: 'backup', suggestedName: 'backup'),
      isFalse,
    );
  });
}

final class _MemoryFilePickerGateway implements BackupFilePickerGateway {
  List<int>? openedBytes;
  List<int>? savedBytes;
  String? savedName;
  bool saveAccepted = true;

  @override
  Future<List<int>?> openBackup() async => openedBytes;

  @override
  Future<bool> saveBackup({
    required List<int> bytes,
    required String suggestedName,
  }) async {
    savedBytes = bytes;
    savedName = suggestedName;
    return saveAccepted;
  }
}
