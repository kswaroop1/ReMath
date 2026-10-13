import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:remath/src/features/learning/application/content_pack_installer.dart';
import 'package:remath/src/features/learning/data/content_pack_archive_verifier.dart';
import 'package:remath/src/features/learning/data/content_pack_lifecycle.dart';
import 'package:remath/src/features/learning/data/content_pack_parser.dart';
import 'package:remath/src/features/learning/domain/content_pack_release.dart';
import 'package:sqlite3/sqlite3.dart';

void main() {
  test('native composition exposes the production lifecycle backend', () async {
    final database = sqlite3.openInMemory();
    addTearDown(database.close);
    var nextId = 0;

    final lifecycle = composeSqliteContentPackLifecycle(
      availableBytes: () async => 1024 * 1024,
      currentAppVersion: '0.1.0',
      database: database,
      idGenerator: () => 'composition-${nextId++}',
      signatureVerifier: const _TrustedSignatureVerifier(),
    );
    final bytes = utf8.encode(_pack);
    final digest = await Sha256().hash(bytes);
    final release = ContentPackRelease(
      compressedSizeBytes: bytes.length,
      dependencies: const [],
      description: 'Production-composed pack.',
      installedSizeBytes: bytes.length,
      language: 'en-GB',
      license: 'CC-BY-SA-4.0',
      manifestVersion: 1,
      minimumAppVersion: '0.1.0',
      minimumSchemaVersion: 1,
      objectives: const ['Compose safely'],
      packId: 'org.remath.composed',
      publisherKeyId: 'org.remath.publisher.primary',
      sha256: digest.bytes
          .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
          .join(),
      signature: 'AQID',
      title: 'Composed',
      version: '1.0.0',
    );

    expect(
      await lifecycle.installer.install(release, _Source(bytes)),
      ContentPackInstallOutcome.activated,
    );
    expect(await lifecycle.backend.activeVersion(release.packId), '1.0.0');
  });

  test('startup loads and confirms the durable active pack', () async {
    final database = sqlite3.openInMemory();
    addTearDown(database.close);
    var nextId = 0;
    final lifecycle = composeSqliteContentPackLifecycle(
      availableBytes: () async => 1024 * 1024,
      currentAppVersion: '0.1.0',
      database: database,
      idGenerator: () => 'startup-${nextId++}',
      signatureVerifier: const _TrustedSignatureVerifier(),
    );
    final bytes = utf8.encode(_pack);
    final digest = await Sha256().hash(bytes);
    final release = ContentPackRelease(
      compressedSizeBytes: bytes.length,
      dependencies: const [],
      description: 'Production-composed pack.',
      installedSizeBytes: bytes.length,
      language: 'en-GB',
      license: 'CC-BY-SA-4.0',
      manifestVersion: 1,
      minimumAppVersion: '0.1.0',
      minimumSchemaVersion: 1,
      objectives: const ['Compose safely'],
      packId: 'org.remath.composed',
      publisherKeyId: 'org.remath.publisher.primary',
      sha256: digest.bytes
          .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
          .join(),
      signature: 'AQID',
      title: 'Composed',
      version: '1.0.0',
    );
    await lifecycle.installer.install(release, _Source(bytes));
    final fallback = const ContentPackParser().parse(
      _pack.replaceFirst('org.remath.composed', 'org.remath.fallback'),
    );

    final loaded = await lifecycle.loadStartupPack(fallback);

    expect(loaded.id, release.packId);
    expect(
      (await lifecycle.backend.activation(release.packId)).awaitingFirstLoad,
      isFalse,
    );
  });

  test('startup recovers every pending pack before selecting one', () async {
    final database = sqlite3.openInMemory();
    addTearDown(database.close);
    var nextId = 0;
    final lifecycle = composeSqliteContentPackLifecycle(
      availableBytes: () async => 1024 * 1024,
      currentAppVersion: '0.1.0',
      database: database,
      idGenerator: () => 'multi-startup-${nextId++}',
      signatureVerifier: const _TrustedSignatureVerifier(),
    );
    final firstBytes = utf8.encode(_pack);
    final secondBytes = utf8.encode(_secondPack);
    await lifecycle.installer.install(
      await _releaseFor('org.remath.composed', firstBytes),
      _Source(firstBytes),
    );
    await lifecycle.installer.install(
      await _releaseFor('org.remath.secondary', secondBytes),
      _Source(secondBytes),
    );
    final fallback = const ContentPackParser().parse(
      _pack.replaceFirst('org.remath.composed', 'org.remath.fallback'),
    );

    final loaded = await lifecycle.loadStartupPack(fallback);

    expect(loaded.id, 'org.remath.secondary');
    expect(
      (await lifecycle.backend.activation('org.remath.composed'))
          .awaitingFirstLoad,
      isFalse,
    );
    expect(
      (await lifecycle.backend.activation('org.remath.secondary'))
          .awaitingFirstLoad,
      isFalse,
    );
  });

  test('startup uses bundled content when lifecycle opening fails', () async {
    final fallback = const ContentPackParser().parse(
      _pack.replaceFirst('org.remath.composed', 'org.remath.fallback'),
    );

    final startup = await loadContentPackForStartup(
      fallback: fallback,
      openLifecycle: () async => throw StateError('storage unavailable'),
    );

    expect(startup.pack, same(fallback));
    expect(startup.lifecycle, isNull);
  });

  test('startup closes failed lifecycle storage and uses bundled content', () async {
    final database = sqlite3.openInMemory();
    var nextId = 0;
    final lifecycle = composeSqliteContentPackLifecycle(
      availableBytes: () async => 1024 * 1024,
      closeDatabase: database.close,
      currentAppVersion: '0.1.0',
      database: database,
      idGenerator: () => 'failed-startup-${nextId++}',
      signatureVerifier: const _TrustedSignatureVerifier(),
    );
    final bytes = utf8.encode(_pack);
    await lifecycle.installer.install(
      await _releaseFor('org.remath.composed', bytes),
      _Source(bytes),
    );
    database
      ..execute('DROP TRIGGER content_pack_chunks_update_staging')
      ..execute(
        'UPDATE content_pack_object_chunks SET content = ?',
        [utf8.encode('not valid content')],
      );
    final fallback = const ContentPackParser().parse(
      _pack.replaceFirst('org.remath.composed', 'org.remath.fallback'),
    );

    final startup = await loadContentPackForStartup(
      fallback: fallback,
      openLifecycle: () async => lifecycle,
    );

    expect(startup.pack, same(fallback));
    expect(startup.lifecycle, isNull);
    expect(
      () => database.select('SELECT 1'),
      throwsA(isA<SqliteException>()),
    );
  });
}

Future<ContentPackRelease> _releaseFor(String packId, List<int> bytes) async {
  final digest = await Sha256().hash(bytes);
  return ContentPackRelease(
    compressedSizeBytes: bytes.length,
    dependencies: const [],
    description: 'Production-composed pack.',
    installedSizeBytes: bytes.length,
    language: 'en-GB',
    license: 'CC-BY-SA-4.0',
    manifestVersion: 1,
    minimumAppVersion: '0.1.0',
    minimumSchemaVersion: 1,
    objectives: const ['Compose safely'],
    packId: packId,
    publisherKeyId: 'org.remath.publisher.primary',
    sha256: digest.bytes
        .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
        .join(),
    signature: 'AQID',
    title: 'Composed',
    version: '1.0.0',
  );
}

const _pack = '''
{
  "schemaVersion": 1,
  "id": "org.remath.composed",
  "version": "1.0.0",
  "title": "Composed",
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

const _secondPack = '''
{
  "schemaVersion": 1,
  "id": "org.remath.secondary",
  "version": "1.0.0",
  "title": "Secondary",
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

final class _Source implements ContentPackArchiveSource {
  const _Source(this.bytes);

  final List<int> bytes;

  @override
  Stream<List<int>> openRead() => Stream.value(bytes);
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
