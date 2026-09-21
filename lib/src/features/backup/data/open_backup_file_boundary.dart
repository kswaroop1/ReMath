import '../application/backup_file_transfer.dart';
import 'open_backup_file_boundary_stub.dart'
    if (dart.library.io) 'open_backup_file_boundary_io.dart' as platform;

BackupFileBoundary? openBackupFileBoundary() => platform.openBackupFileBoundary();
