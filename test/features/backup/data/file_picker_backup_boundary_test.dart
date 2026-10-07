import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:remath/src/features/backup/data/file_picker_backup_boundary.dart';

void main() {
  test(
    'file picker boundary transfers backup text without changing bytes',
    () async {
      final gateway = _MemoryFilePickerGateway()
        ..selection = _MemoryBackupSelection(
          utf8.encode('encrypted progress ✓'),
        );
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

  test(
    'file picker boundary rejects oversized backups before reading',
    () async {
      final selection = _MemoryBackupSelection(const [
        1,
      ], reportedLength: maxPortableBackupBytes + 1);
      final boundary = FilePickerBackupBoundary(
        gateway: _MemoryFilePickerGateway()..selection = selection,
      );

      await expectLater(boundary.openText(), throwsFormatException);
      expect(selection.readCount, 0);
    },
  );

  test('file picker boundary rejects unknown sizes before reading', () async {
    final selection = _MemoryBackupSelection(const [
      1,
    ], hasReportedLength: false);
    final boundary = FilePickerBackupBoundary(
      gateway: _MemoryFilePickerGateway()..selection = selection,
    );

    await expectLater(boundary.openText(), throwsFormatException);
    expect(selection.readCount, 0);
  });

  test(
    'file picker boundary rejects oversized exports before saving',
    () async {
      final gateway = _MemoryFilePickerGateway();
      final boundary = FilePickerBackupBoundary(gateway: gateway);

      await expectLater(
        boundary.saveText(
          contents: 'x' * (maxPortableBackupBytes + 1),
          suggestedName: 'oversized.remath-backup',
        ),
        throwsFormatException,
      );
      expect(gateway.saveCalls, 0);
    },
  );
}

final class _MemoryFilePickerGateway implements BackupFilePickerGateway {
  BackupFileSelection? selection;
  List<int>? savedBytes;
  String? savedName;
  bool saveAccepted = true;
  int saveCalls = 0;

  @override
  Future<BackupFileSelection?> selectBackup() async => selection;

  @override
  Future<bool> saveBackup({
    required List<int> bytes,
    required String suggestedName,
  }) async {
    saveCalls++;
    savedBytes = bytes;
    savedName = suggestedName;
    return saveAccepted;
  }
}

final class _MemoryBackupSelection implements BackupFileSelection {
  _MemoryBackupSelection(
    this.bytes, {
    bool hasReportedLength = true,
    int? reportedLength,
  }) : _reportedLength = hasReportedLength
           ? reportedLength ?? bytes.length
           : null;

  final List<int> bytes;
  final int? _reportedLength;
  int readCount = 0;

  @override
  Future<int?> length() async => _reportedLength;

  @override
  Future<List<int>> readAsBytes() async {
    readCount++;
    return bytes;
  }
}
