import 'package:flutter_test/flutter_test.dart';
import 'package:remath/src/features/backup/application/backup_coordinator.dart';
import 'package:remath/src/features/backup/application/backup_file_transfer.dart';
import 'package:remath/src/features/backup/data/password_backup_cipher.dart';
import 'package:remath/src/features/learning/data/in_memory_progress_repository.dart';

void main() {
  group('provider-neutral backup file transfer', () {
    test('writes encrypted export through the supplied file boundary', () async {
      final files = _MemoryBackupFiles();
      final transfer = BackupFileTransfer(
        coordinator: _coordinator(),
        files: files,
      );

      final saved = await transfer.export(password: 'password');

      expect(saved, isTrue);
      expect(files.savedName, 'remath-progress.remath-backup');
      expect(files.savedContents, contains('ciphertext'));
      expect(files.savedContents, isNot(contains('attempts')));
    });

    test('reads for preview without applying and treats cancellation safely', () async {
      final encrypted = await _coordinator().export(password: 'password');
      final files = _MemoryBackupFiles()..contentsToOpen = encrypted;
      final target = InMemoryProgressRepository();
      final transfer = BackupFileTransfer(
        coordinator: _coordinator(repository: target),
        files: files,
      );

      final pending = await transfer.previewImport(password: 'password');

      expect(pending, isNotNull);
      expect(await target.loadAttempts(), isEmpty);
      files.contentsToOpen = null;
      expect(await transfer.previewImport(password: 'password'), isNull);
    });
  });
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

final class _MemoryBackupFiles implements BackupFileBoundary {
  String? contentsToOpen;
  String? savedContents;
  String? savedName;

  @override
  Future<String?> openText() async => contentsToOpen;

  @override
  Future<bool> saveText({
    required String contents,
    required String suggestedName,
  }) async {
    savedContents = contents;
    savedName = suggestedName;
    return true;
  }
}
