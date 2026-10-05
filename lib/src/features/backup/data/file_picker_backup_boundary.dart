import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

import '../application/backup_file_transfer.dart';

const maxPortableBackupBytes = 8 * 1024 * 1024;

abstract interface class BackupFileSelection {
  Future<int?> length();
  Future<List<int>> readAsBytes();
}

abstract interface class BackupFilePickerGateway {
  Future<BackupFileSelection?> selectBackup();
  Future<bool> saveBackup({
    required List<int> bytes,
    required String suggestedName,
  });
}

final class FilePickerBackupGateway implements BackupFilePickerGateway {
  const FilePickerBackupGateway();

  @override
  Future<BackupFileSelection?> selectBackup() async {
    final file = await FilePicker.pickFile(
      allowedExtensions: const ['remath-backup'],
      type: FileType.custom,
    );
    if (file == null) return null;
    return _FilePickerSelection(file.length, file.readAsBytes);
  }

  @override
  Future<bool> saveBackup({
    required List<int> bytes,
    required String suggestedName,
  }) async {
    final saved = await FilePicker.saveFile(
      bytes: Uint8List.fromList(bytes),
      fileName: suggestedName,
    );
    return saved != null;
  }
}

final class FilePickerBackupBoundary implements BackupFileBoundary {
  FilePickerBackupBoundary({BackupFilePickerGateway? gateway})
    : _gateway = gateway ?? const FilePickerBackupGateway();

  final BackupFilePickerGateway _gateway;

  @override
  Future<String?> openText() async {
    final selection = await _gateway.selectBackup();
    if (selection == null) return null;
    final reportedLength = await selection.length();
    if (reportedLength == null || reportedLength > maxPortableBackupBytes) {
      throw const FormatException('Backup file exceeds the size limit');
    }
    final bytes = await selection.readAsBytes();
    if (bytes.length > maxPortableBackupBytes) {
      throw const FormatException('Backup file exceeds the size limit');
    }
    return utf8.decode(bytes);
  }

  @override
  Future<bool> saveText({
    required String contents,
    required String suggestedName,
  }) async {
    final bytes = utf8.encode(contents);
    if (bytes.length > maxPortableBackupBytes) {
      throw const FormatException('Backup file exceeds the size limit');
    }
    return _gateway.saveBackup(
      bytes: bytes,
      suggestedName: suggestedName,
    );
  }
}

final class _FilePickerSelection implements BackupFileSelection {
  const _FilePickerSelection(this._length, this._readAsBytes);

  final Future<int?> Function() _length;
  final Future<List<int>> Function() _readAsBytes;

  @override
  Future<int?> length() => _length();

  @override
  Future<List<int>> readAsBytes() => _readAsBytes();
}
