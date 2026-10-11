import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:remath/src/features/learning/application/content_pack_installer.dart';
import 'package:remath/src/features/learning/data/content_pack_archive_verifier.dart';
import 'package:remath/src/features/learning/data/content_pack_install_guard.dart';
import 'package:remath/src/features/learning/data/content_pack_install_store.dart';
import 'package:remath/src/features/learning/data/content_pack_lifecycle.dart';
import 'package:remath/src/features/learning/data/sqlite_content_pack_installation_backend.dart';
import 'package:remath/src/features/learning/domain/content_pack_release.dart';
import 'package:sqlite3/sqlite3.dart';

void main() {
  test(
    'production composition installs and atomically enforces retention',
    () async {
      final database = sqlite3.openInMemory();
      addTearDown(database.close);
      var nextId = 0;
      final backend = SqliteContentPackInstallationBackend(
        availableBytes: () async => 1024 * 1024,
        database: database,
        idGenerator: () => 'lifecycle-${nextId++}',
      );
      final installer = composeContentPackInstaller(
        backend: backend,
        environment: _Environment(backend),
        signatureVerifier: const _TrustedSignatureVerifier(),
      );
      final versionTwo = await _release('2.0.0');

      expect(
        await installer.install(
          versionTwo,
          _Source(utf8.encode(_pack('2.0.0'))),
        ),
        ContentPackInstallOutcome.activated,
      );
      expect(await backend.activeVersion(versionTwo.packId), '2.0.0');

      final versionOne = await _release('1.0.0');
      await expectLater(
        installer.install(versionOne, _Source(utf8.encode(_pack('1.0.0')))),
        throwsA(isA<ContentPackActivationException>()),
      );
      expect(await backend.activeVersion(versionTwo.packId), '2.0.0');

      expect(
        await installer.install(
          versionOne,
          _Source(utf8.encode(_pack('1.0.0'))),
          isExplicitVersionChoice: true,
        ),
        ContentPackInstallOutcome.activated,
      );
      await backend.pinActive(versionTwo.packId);
      final versionThree = await _release('3.0.0');
      await expectLater(
        installer.install(versionThree, _Source(utf8.encode(_pack('3.0.0')))),
        throwsA(isA<ContentPackActivationException>()),
      );
      expect(await backend.activeVersion(versionTwo.packId), '1.0.0');
    },
  );

  test(
    'confirmed sqlite activation cannot be rolled back by a stale load',
    () async {
      final database = sqlite3.openInMemory();
      addTearDown(database.close);
      var nextId = 0;
      final backend = SqliteContentPackInstallationBackend(
        availableBytes: () async => 1024 * 1024,
        database: database,
        idGenerator: () => 'activation-${nextId++}',
      );
      final installer = composeContentPackInstaller(
        backend: backend,
        environment: _Environment(backend),
        signatureVerifier: const _TrustedSignatureVerifier(),
      );
      final release = await _release('2.0.0');
      await installer.install(release, _Source(utf8.encode(_pack('2.0.0'))));
      final pending = await backend.activation(release.packId);

      final confirmed = await backend.confirmFirstLoad(
        expectedActivationId: pending.activationId,
        packId: release.packId,
      );
      final staleRollback = await backend.rollbackFailedActivation(
        expectedActivationId: pending.activationId,
        message: 'stale failure',
        packId: release.packId,
      );

      expect(confirmed.confirmed, isTrue);
      expect(staleRollback.restored, isFalse);
      expect(await backend.activeVersion(release.packId), '2.0.0');
    },
  );

  test('sqlite discard persists cleanup for retry before deletion', () async {
    final database = sqlite3.openInMemory();
    addTearDown(database.close);
    var interruptCleanup = true;
    final backend = SqliteContentPackInstallationBackend(
      availableBytes: () async => 1024 * 1024,
      beforeCleanupDelete: () async {
        if (interruptCleanup) {
          interruptCleanup = false;
          throw StateError('cleanup interrupted');
        }
      },
      database: database,
      idGenerator: () => 'cleanup-1',
    );
    final store = TransactionalContentPackInstallStore(backend: backend);
    final release = await _release('2.0.0');
    final staged = await store.stage(
      release,
      _Source(utf8.encode(_pack('2.0.0'))),
    );

    await expectLater(store.discardStaged(release, staged), throwsStateError);
    expect(await backend.pendingCleanupCount(), 1);
    await store.retryPendingDiscards();
    expect(await backend.pendingCleanupCount(), 0);
  });
}

final class _Environment implements ContentPackInstallEnvironment {
  const _Environment(this.backend);

  final SqliteContentPackInstallationBackend backend;

  @override
  Future<int> availableBytes() async => 1024 * 1024;

  @override
  String get currentAppVersion => '0.1.0';

  @override
  Future<String?> installedVersion(String packId) =>
      backend.activeVersion(packId);

  @override
  int get maximumSchemaVersion => 3;
}

final class _TrustedSignatureVerifier implements ContentPackSignatureVerifier {
  const _TrustedSignatureVerifier();

  @override
  Future<bool> verify({
    required String publisherKeyId,
    required List<int> signedPayload,
    required List<int> signature,
  }) async => true;
}

final class _Source implements ContentPackArchiveSource {
  const _Source(this.bytes);

  final List<int> bytes;

  @override
  Stream<List<int>> openRead() => Stream.value(bytes);
}

Future<ContentPackRelease> _release(String version) async {
  final bytes = utf8.encode(_pack(version));
  final digest = await Sha256().hash(bytes);
  return ContentPackRelease(
    compressedSizeBytes: bytes.length,
    dependencies: const [],
    description: 'Original pack.',
    installedSizeBytes: bytes.length,
    language: 'en-GB',
    license: 'CC-BY-SA-4.0',
    manifestVersion: 1,
    minimumAppVersion: '0.1.0',
    minimumSchemaVersion: 1,
    objectives: const ['Learn safely'],
    packId: 'org.remath.pack.one',
    publisherKeyId: 'org.remath.publisher.primary',
    sha256: digest.bytes
        .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
        .join(),
    signature: 'AQID',
    title: 'Pack',
    version: version,
  );
}

String _pack(String version) =>
    '''
{
  "schemaVersion": 1,
  "id": "org.remath.pack.one",
  "version": "$version",
  "title": "Pack",
  "license": "CC-BY-SA-4.0",
  "skills": [{"id":"arithmetic.addition","title":"Addition"}],
  "templates": [{
    "id":"arithmetic.addition.template",
    "version":1,
    "skillId":"arithmetic.addition",
    "operation":"addition",
    "minimumOperand":0,
    "maximumOperand":10,
    "fluentTargetSeconds":10
  }]
}
''';
