import 'backup_coordinator.dart';

abstract interface class BackupFileBoundary {
  Future<String?> openText();
  Future<bool> saveText({
    required String contents,
    required String suggestedName,
  });
}

final class BackupFileTransfer {
  const BackupFileTransfer({
    required BackupCoordinator coordinator,
    required BackupFileBoundary files,
  }) : _coordinator = coordinator,
       _files = files;

  static const suggestedFileName = 'remath-progress.remath-backup';

  final BackupCoordinator _coordinator;
  final BackupFileBoundary _files;

  Future<bool> export({required String password}) async {
    final encrypted = await _coordinator.export(password: password);
    return _files.saveText(
      contents: encrypted,
      suggestedName: suggestedFileName,
    );
  }

  Future<PendingBackupImport?> previewImport({required String password}) async {
    final encrypted = await _files.openText();
    if (encrypted == null) return null;
    return _coordinator.preview(encrypted, password: password);
  }
}
