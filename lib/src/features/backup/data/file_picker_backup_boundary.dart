import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

import '../application/backup_file_transfer.dart';

abstract interface class BackupFilePickerGateway {
  Future<List<int>?> openBackup();
  Future<bool> saveBackup({
    required List<int> bytes,
    required String suggestedName,
  });
}

final class FilePickerBackupGateway implements BackupFilePickerGateway {
  const FilePickerBackupGateway();

  @override
  Future<List<int>?> openBackup() async {
    final file = await FilePicker.pickFile(
      allowedExtensions: const ['remath-backup'],
      type: FileType.custom,
    );
    return file?.readAsBytes();
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
    final bytes = await _gateway.openBackup();
    return bytes == null ? null : utf8.decode(bytes);
  }

  @override
  Future<bool> saveText({
    required String contents,
    required String suggestedName,
  }) {
    return _gateway.saveBackup(
      bytes: utf8.encode(contents),
      suggestedName: suggestedName,
    );
  }
}
