import 'package:sqlite3/common.dart';

import '../application/content_pack_installer.dart';
import 'content_pack_archive_verifier.dart';
import 'content_pack_install_guard.dart';
import 'content_pack_install_store.dart';
import 'content_pack_payload_verifier.dart';
import 'sqlite_content_pack_installation_backend.dart';

final class ContentPackLifecycle {
  const ContentPackLifecycle({required this.backend, required this.installer});

  final SqliteContentPackInstallationBackend backend;
  final ContentPackInstaller installer;
}

ContentPackLifecycle composeSqliteContentPackLifecycle({
  required Future<int> Function() availableBytes,
  required String currentAppVersion,
  required CommonDatabase database,
  required ContentPackIdGenerator idGenerator,
  int maximumSchemaVersion = 3,
  required ContentPackSignatureVerifier signatureVerifier,
}) {
  final backend = SqliteContentPackInstallationBackend(
    availableBytes: availableBytes,
    database: database,
    idGenerator: idGenerator,
  );
  final environment = _SqliteContentPackInstallEnvironment(
    availableBytes: availableBytes,
    backend: backend,
    currentAppVersion: currentAppVersion,
    maximumSchemaVersion: maximumSchemaVersion,
  );
  return ContentPackLifecycle(
    backend: backend,
    installer: composeContentPackInstaller(
      backend: backend,
      environment: environment,
      signatureVerifier: signatureVerifier,
    ),
  );
}

/// Production composition for the complete stage-verify-activate path.
ContentPackInstaller composeContentPackInstaller({
  required ContentPackInstallationBackend backend,
  required ContentPackInstallEnvironment environment,
  required ContentPackSignatureVerifier signatureVerifier,
}) => ContentPackInstaller(
  guard: ValidatedContentPackInstallGuard(environment: environment),
  store: TransactionalContentPackInstallStore(backend: backend),
  verifier: ProductionContentPackVerifier(
    maximumSchemaVersion: environment.maximumSchemaVersion,
    signatureVerifier: signatureVerifier,
  ),
);

final class _SqliteContentPackInstallEnvironment
    implements ContentPackInstallEnvironment {
  const _SqliteContentPackInstallEnvironment({
    required Future<int> Function() availableBytes,
    required this.backend,
    required this.currentAppVersion,
    required this.maximumSchemaVersion,
  }) : _availableBytes = availableBytes;

  final Future<int> Function() _availableBytes;
  final SqliteContentPackInstallationBackend backend;

  @override
  final String currentAppVersion;

  @override
  final int maximumSchemaVersion;

  @override
  Future<int> availableBytes() => _availableBytes();

  @override
  Future<String?> installedVersion(String packId) =>
      backend.activeVersion(packId);
}
