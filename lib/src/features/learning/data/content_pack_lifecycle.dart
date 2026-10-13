import 'dart:convert';

import 'package:sqlite3/common.dart';

import '../application/content_pack_installer.dart';
import '../application/content_pack_rollback.dart';
import '../domain/content_pack.dart';
import 'content_pack_archive_verifier.dart';
import 'content_pack_install_guard.dart';
import 'content_pack_install_store.dart';
import 'content_pack_parser.dart';
import 'content_pack_payload_verifier.dart';
import 'content_pack_validator.dart';
import 'sqlite_content_pack_installation_backend.dart';

final class ContentPackLifecycle {
  const ContentPackLifecycle({required this.backend, required this.installer});

  final SqliteContentPackInstallationBackend backend;
  final ContentPackInstaller installer;

  Future<ContentPack> loadStartupPack(ContentPack fallback) async {
    final loader = _SqliteContentPackRuntimeLoader(backend);
    final coordinator = ContentPackRollbackCoordinator(
      loader: loader,
      store: backend,
    );
    for (final pendingPackId in await backend.pendingFirstLoadPackIds()) {
      final pending = await backend.activation(pendingPackId);
      final pendingVersion = pending.activeVersion;
      if (pendingVersion != null) {
        await coordinator.verifyFirstLoad(pendingPackId, pendingVersion);
      }
    }

    final packId = await backend.startupPackId();
    if (packId == null) return fallback;

    final activation = await backend.activation(packId);
    final version = activation.activeVersion;
    if (version == null) return fallback;

    final result = await coordinator.verifyFirstLoad(packId, version);
    final activeVersion = result.activeVersion;
    if (activeVersion == null) return fallback;
    if (loader.loadedPack case final loaded?
        when loaded.id == packId && loaded.version == activeVersion) {
      return loaded;
    }
    return loader.loadPack(packId, activeVersion);
  }
}

ContentPackLifecycle composeSqliteContentPackLifecycle({
  required Future<int> Function() availableBytes,
  required String currentAppVersion,
  required CommonDatabase database,
  required ContentPackIdGenerator idGenerator,
  int maximumSchemaVersion = 3,
  ContentPackIdGenerator? ownerIdGenerator,
  required ContentPackSignatureVerifier signatureVerifier,
}) {
  final backend = SqliteContentPackInstallationBackend(
    availableBytes: availableBytes,
    database: database,
    idGenerator: idGenerator,
    ownerIdGenerator: ownerIdGenerator,
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

final class _SqliteContentPackRuntimeLoader
    implements ContentPackRuntimeLoader {
  _SqliteContentPackRuntimeLoader(this.backend);

  final SqliteContentPackInstallationBackend backend;
  ContentPack? loadedPack;

  @override
  Future<void> load(String packId, String version) async {
    loadedPack = await loadPack(packId, version);
  }

  Future<ContentPack> loadPack(String packId, String version) async {
    final bytes = await backend
        .activeArchive(packId, version)
        .expand((chunk) => chunk)
        .toList();
    final pack = const ContentPackParser().parse(utf8.decode(bytes));
    const ContentPackValidator().validateOrThrow(pack);
    if (pack.id != packId || pack.version != version) {
      throw const FormatException(
        'The active content pack does not match its durable pointer.',
      );
    }
    return pack;
  }
}
