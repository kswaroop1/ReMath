import 'package:cryptography/cryptography.dart';

import '../application/content_pack_installer.dart';
import '../domain/content_pack_release.dart';

final class ContentPackStagingException implements Exception {
  const ContentPackStagingException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Persistence boundary for a reservation-backed staging transaction.
///
/// [reserve] must atomically reserve capacity across all packs. After [seal]
/// succeeds the returned object must be immutable and addressable by [sealId].
abstract interface class ContentPackInstallationBackend {
  Future<String?> activeVersion(String packId);

  Future<ContentPackStagingSink> reserve({
    required String packId,
    required int requiredBytes,
    required String version,
  });

  /// In one transaction, confirms every dependency in [release] is still at
  /// its minimum version, confirms [sealed] is unchanged, and moves the active
  /// pointer. No pointer may move when either comparison fails.
  Future<void> activateAtomically({
    required ContentPackRelease release,
    required ContentPackSealedObject sealed,
  });

  Future<void> discard(ContentPackSealedObject sealed);
}

abstract interface class ContentPackStagingSink {
  Future<void> add(List<int> chunk);

  Future<ContentPackSealedObject> seal({
    required int lengthBytes,
    required String sha256,
  });

  Future<void> abort();
}

abstract interface class ContentPackSealedObject {
  int get reservedBytes;

  String get sealId;

  Stream<List<int>> openRead();
}

final class TransactionalContentPackInstallStore
    implements ContentPackInstallStore {
  const TransactionalContentPackInstallStore({required this.backend});

  final ContentPackInstallationBackend backend;

  @override
  Future<String?> activeVersion(String packId) => backend.activeVersion(packId);

  @override
  Future<ContentPackStagedArchive> stage(
    ContentPackRelease release,
    ContentPackArchiveSource archive,
  ) async {
    final reservation = await backend.reserve(
      packId: release.packId,
      requiredBytes: release.compressedSizeBytes + release.installedSizeBytes,
      version: release.version,
    );
    final hashSink = Sha256().newHashSink();
    var length = 0;
    try {
      await for (final chunk in archive.openRead()) {
        final nextLength = length + chunk.length;
        if (nextLength > release.compressedSizeBytes) {
          throw ContentPackStagingException(
            'The archive exceeds its declared ${release.compressedSizeBytes} '
            'byte limit.',
          );
        }
        await reservation.add(List.unmodifiable(chunk));
        hashSink.add(chunk);
        length = nextLength;
      }
      hashSink.close();
      final hash = await hashSink.hash();
      final sha256 = hash.bytes
          .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
          .join();
      final sealed = await reservation.seal(
        lengthBytes: length,
        sha256: sha256,
      );
      return _SealedStagedArchive(
        lengthBytes: length,
        sealed: sealed,
        sha256: sha256,
      );
    } on Object {
      await reservation.abort();
      rethrow;
    }
  }

  @override
  Future<void> activateStaged(
    ContentPackRelease release,
    ContentPackStagedArchive archive,
  ) {
    final sealed = _sealedObject(archive);
    return backend.activateAtomically(release: release, sealed: sealed);
  }

  @override
  Future<void> discardStaged(
    ContentPackRelease release,
    ContentPackStagedArchive archive,
  ) => backend.discard(_sealedObject(archive));

  ContentPackSealedObject _sealedObject(ContentPackStagedArchive archive) {
    if (archive is! _SealedStagedArchive) {
      throw const ContentPackStagingException(
        'Only an archive sealed by this install store can be committed.',
      );
    }
    return archive.sealed;
  }
}

final class _SealedStagedArchive implements ContentPackStagedArchive {
  const _SealedStagedArchive({
    required this.lengthBytes,
    required this.sealed,
    required this.sha256,
  });

  @override
  final int lengthBytes;

  final ContentPackSealedObject sealed;

  @override
  String get sealId => sealed.sealId;

  @override
  final String sha256;

  @override
  Stream<List<int>> openRead() => sealed.openRead();
}
