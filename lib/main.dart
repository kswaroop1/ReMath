import 'package:flutter/material.dart';
import 'package:remath/src/app.dart';
import 'package:remath/src/features/backup/data/open_backup_file_boundary.dart';
import 'package:remath/src/features/learning/data/asset_content_pack_repository.dart';
import 'package:remath/src/features/learning/data/open_content_pack_lifecycle.dart';
import 'package:remath/src/features/learning/data/open_progress_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final contentPack = await AssetContentPackRepository().loadFoundationPack();
  final contentPackLifecycle = await openContentPackLifecycle();
  await contentPackLifecycle?.backend.retryPendingDiscards();
  final repository = await openProgressRepository();
  runApp(
    ReMathApp(
      backupFiles: openBackupFileBoundary(),
      contentPack: contentPack,
      contentPackLifecycle: contentPackLifecycle,
      repository: repository,
    ),
  );
}
