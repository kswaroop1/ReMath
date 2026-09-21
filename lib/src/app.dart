import 'package:flutter/material.dart';
import 'package:remath/src/features/backup/application/backup_coordinator.dart';
import 'package:remath/src/features/backup/application/backup_file_transfer.dart';
import 'package:remath/src/features/backup/data/password_backup_cipher.dart';
import 'package:remath/src/features/home/presentation/home_screen.dart';
import 'package:remath/src/features/learning/domain/content_pack.dart';
import 'package:remath/src/features/learning/domain/progress_repository.dart';

class ReMathApp extends StatelessWidget {
  const ReMathApp({
    this.backupFiles,
    required this.contentPack,
    required this.repository,
    super.key,
  });

  final BackupFileBoundary? backupFiles;
  final ContentPack contentPack;
  final ProgressRepository repository;

  @override
  Widget build(BuildContext context) {
    final files = backupFiles;
    final backupTransfer = files == null
        ? null
        : BackupFileTransfer(
            coordinator: BackupCoordinator(
              cipher: PasswordBackupCipher(),
              clock: DateTime.now,
              repository: repository,
            ),
            files: files,
          );
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HomeScreen(
        backupTransfer: backupTransfer,
        contentPack: contentPack,
        repository: repository,
      ),
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff375a7f)),
        useMaterial3: true,
      ),
      title: 'ReMath',
    );
  }
}
