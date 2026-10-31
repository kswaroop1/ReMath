import 'dart:convert';

import 'package:sqlite3/common.dart';

import '../application/content_pack_installer.dart';
import '../application/content_pack_rollback.dart';
import '../domain/content_pack.dart';
import '../domain/content_pack_release.dart';
import 'content_pack_archive_verifier.dart';
import 'content_pack_install_guard.dart';
import 'content_pack_install_store.dart';
import 'content_pack_parser.dart';
import 'content_pack_payload_verifier.dart';
import 'content_pack_validator.dart';
import 'ed25519_content_pack_signature_verifier.dart';
import 'sqlite_content_pack_installation_backend.dart';

final class ContentPackLifecycle {
  const ContentPackLifecycle({
    required this.backend,
    void Function()? closeDatabase,
    required this.installer,
  }) : _closeDatabase = closeDatabase;

  final SqliteContentPackInstallationBackend backend;
  final void Function()? _closeDatabase;
  final ContentPackInstaller installer;

  void close() => _closeDatabase?.call();

  Future<ContentPack> loadStartupPack(ContentPack fallback) async {
    final loader = _SqliteContentPackRuntimeLoader(backend);
    final coordinator = ContentPackRollbackCoordinator(
      loader: loader,
      store: backend,
    );
    for (final pendingPackId in await backend.pendingFirstLoadPackIds()) {
      await coordinator.recoverPendingFirstLoad(pendingPackId);
    }

    final packId = await backend.startupPackId();
    if (packId == null) return fallback;

    final activation = await backend.activation(packId);
    final version = activation.activeVersion;
    if (version == null) return fallback;

    final result = await coordinator.recoverPendingFirstLoad(packId);
    final activeVersion = result.activeVersion;
    if (activeVersion == null) return fallback;
    if (loader.loadedPack case final loaded?
        when loaded.id == packId && loaded.version == activeVersion) {
      return loaded;
    }
    return loader.loadPack(packId, activeVersion);
  }
}

final class ContentPackStartup {
  const ContentPackStartup({required this.lifecycle, required this.pack});

  final ContentPackLifecycle? lifecycle;
  final ContentPack pack;
}

Future<ContentPackStartup> loadContentPackForStartup({
  required ContentPack fallback,
  required Future<ContentPackLifecycle?> Function() openLifecycle,
}) async {
  ContentPackLifecycle? lifecycle;
  try {
    lifecycle = await openLifecycle();
    await lifecycle?.backend.retryPendingDiscards();
    return ContentPackStartup(
      lifecycle: lifecycle,
      pack: await lifecycle?.loadStartupPack(fallback) ?? fallback,
    );
  } on Object {
    lifecycle?.close();
    return ContentPackStartup(lifecycle: null, pack: fallback);
  }
}

ContentPackLifecycle composeSqliteContentPackLifecycle({
  void Function(ContentPackRelease release)? validateActivation,
  required Future<int> Function() availableBytes,
  void Function()? closeDatabase,
  required String currentAppVersion,
  required CommonDatabase database,
  required ContentPackIdGenerator idGenerator,
  int maximumSchemaVersion = 3,
  ContentPackIdGenerator? ownerIdGenerator,
  required ContentPackSignatureVerifier signatureVerifier,
}) {
  final backend = SqliteContentPackInstallationBackend(
    validateActivation: (release) {
      if (signatureVerifier is Ed25519ContentPackSignatureVerifier) {
        signatureVerifier.validateAuthorization(
          publisherKeyId: release.publisherKeyId,
          signedPayload: ContentPackArchiveVerifier.signedReleasePayload(release),
          signature: base64Decode(release.signature),
        );
      }
      validateActivation?.call(release);
    },
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
    closeDatabase: closeDatabase,
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
