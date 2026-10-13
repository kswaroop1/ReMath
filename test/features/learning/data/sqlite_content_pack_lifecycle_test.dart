import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:remath/src/features/learning/application/content_pack_installer.dart';
import 'package:remath/src/features/learning/application/content_pack_remover.dart';
import 'package:remath/src/features/learning/data/content_pack_archive_verifier.dart';
import 'package:remath/src/features/learning/data/content_pack_install_guard.dart';
import 'package:remath/src/features/learning/data/content_pack_install_store.dart';
import 'package:remath/src/features/learning/data/content_pack_lifecycle.dart';
import 'package:remath/src/features/learning/data/sqlite_content_pack_installation_backend.dart';
import 'package:remath/src/features/learning/domain/content_pack_release.dart';
import 'package:remath/src/features/learning/domain/content_pack_retention.dart';
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
      final versionTwoActivation = await backend.activation(versionTwo.packId);
      await backend.confirmFirstLoad(
        expectedActivationId: versionTwoActivation.activationId,
        packId: versionTwo.packId,
      );

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
      final versionOneActivation = await backend.activation(versionOne.packId);
      await backend.confirmFirstLoad(
        expectedActivationId: versionOneActivation.activationId,
        packId: versionOne.packId,
      );
      await backend.pinActive(
        versionTwo.packId,
        expectedState: await backend.retentionState(versionTwo.packId),
      );
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

  test('startup recovers abandoned reservations as cleanup work', () async {
    final directory = await Directory.systemTemp.createTemp('remath-pack-');
    addTearDown(() => directory.delete(recursive: true));
    final path = '${directory.path}/lifecycle.sqlite3';
    var database = sqlite3.open(path);
    var nextId = 0;
    final interrupted = SqliteContentPackInstallationBackend(
      availableBytes: () async => 1024 * 1024,
      database: database,
      idGenerator: () => 'orphan-${nextId++}',
    );
    final reservation = await interrupted.reserve(
      packId: 'org.remath.pack.one',
      requiredBytes: 64,
      version: '1.0.0',
    );
    await reservation.add(const [1, 2, 3]);
    await reservation.seal(lengthBytes: 3, sha256: 'sealed-digest');
    database.close();

    database = sqlite3.open(path);
    addTearDown(database.close);
    final recovered = SqliteContentPackInstallationBackend(
      availableBytes: () async => 1024 * 1024,
      database: database,
      idGenerator: () => 'recovered-${nextId++}',
    );

    expect(await recovered.pendingCleanupCount(), 1);
    await recovered.retryPendingDiscards();
    expect(await recovered.pendingCleanupCount(), 0);
  });

  test('restart ownership uses a process-unique identity', () async {
    final directory = await Directory.systemTemp.createTemp(
      'remath-pack-owner-',
    );
    addTearDown(() => directory.delete(recursive: true));
    final path = '${directory.path}/lifecycle.sqlite3';
    var database = sqlite3.open(path);
    var nextId = 0;
    final interrupted = SqliteContentPackInstallationBackend(
      availableBytes: () async => 1024 * 1024,
      database: database,
      idGenerator: () => 'process-a-object-${nextId++}',
      ownerIdGenerator: () => 'process-a-owner',
    );
    await interrupted.reserve(
      packId: 'org.remath.pack.one',
      requiredBytes: 64,
      version: '1.0.0',
    );
    expect(
      database
          .select('SELECT owner_id FROM content_pack_objects')
          .single['owner_id'],
      'process-a-owner',
    );
    database.close();

    database = sqlite3.open(path);
    addTearDown(database.close);
    final recovered = SqliteContentPackInstallationBackend(
      availableBytes: () async => 1024 * 1024,
      database: database,
      idGenerator: () => 'process-b-object-${nextId++}',
      ownerIdGenerator: () => 'process-b-owner',
    );

    expect(await recovered.pendingCleanupCount(), 1);
  });

  test('startup does not reclaim another live backend reservation', () async {
    final database = sqlite3.openInMemory();
    addTearDown(database.close);
    var nextId = 0;
    final first = SqliteContentPackInstallationBackend(
      availableBytes: () async => 1024 * 1024,
      database: database,
      idGenerator: () => 'live-${nextId++}',
    );
    final reservation = await first.reserve(
      packId: 'org.remath.pack.one',
      requiredBytes: 64,
      version: '1.0.0',
    );
    await reservation.add(const [1, 2]);

    final second = SqliteContentPackInstallationBackend(
      availableBytes: () async => 1024 * 1024,
      database: database,
      idGenerator: () => 'live-${nextId++}',
    );
    await reservation.add(const [3]);
    final sealed = await reservation.seal(
      lengthBytes: 3,
      sha256: 'live-digest',
    );

    expect(await second.pendingCleanupCount(), 0);
    expect(await sealed.openRead().expand((chunk) => chunk).toList(), const [
      1,
      2,
      3,
    ]);
  });

  test(
    'active pack storage remains charged against the durable budget',
    () async {
      final database = sqlite3.openInMemory();
      addTearDown(database.close);
      var nextId = 0;
      final backend = SqliteContentPackInstallationBackend(
        availableBytes: () async => 100,
        database: database,
        idGenerator: () => 'capacity-${nextId++}',
      );
      final release = await _release('1.0.0');
      final reservation = await backend.reserve(
        packId: release.packId,
        requiredBytes: 60,
        version: release.version,
      );
      await reservation.add(const [1]);
      final sealed = await reservation.seal(
        lengthBytes: 1,
        sha256: release.sha256,
      );
      await backend.activateAtomically(
        isExplicitVersionChoice: false,
        release: release,
        sealed: sealed,
      );

      await expectLater(
        backend.reserve(
          packId: 'org.remath.pack.two',
          requiredBytes: 41,
          version: '1.0.0',
        ),
        throwsA(isA<ContentPackStagingException>()),
      );
    },
  );

  test('staging appends chunks once and sealed bytes are immutable', () async {
    final database = sqlite3.openInMemory();
    addTearDown(database.close);
    final backend = SqliteContentPackInstallationBackend(
      availableBytes: () async => 1024 * 1024,
      database: database,
      idGenerator: () => 'chunked',
    );
    final reservation = await backend.reserve(
      packId: 'org.remath.pack.one',
      requiredBytes: 64,
      version: '1.0.0',
    );
    await reservation.add(const [1, 2]);
    await reservation.add(const [3]);
    await reservation.add(const [4, 5]);
    final sealed = await reservation.seal(
      lengthBytes: 5,
      sha256: 'sealed-digest',
    );

    expect(
      database
          .select('SELECT COUNT(*) AS count FROM content_pack_object_chunks')
          .single['count'],
      3,
    );
    expect(
      database
          .select('SELECT length(content) AS length FROM content_pack_objects')
          .single['length'],
      0,
    );
    expect(
      () => database.execute(
        'UPDATE content_pack_object_chunks SET content = ? WHERE seal_id = ?',
        [
          Uint8List.fromList(const [9]),
          sealed.sealId,
        ],
      ),
      throwsA(isA<SqliteException>()),
    );
    expect(await sealed.openRead().expand((chunk) => chunk).toList(), const [
      1,
      2,
      3,
      4,
      5,
    ]);
  });

  test(
    'staging chunks are append-only before their digest is trusted',
    () async {
      final database = sqlite3.openInMemory();
      addTearDown(database.close);
      final backend = SqliteContentPackInstallationBackend(
        availableBytes: () async => 1024 * 1024,
        database: database,
        idGenerator: () => 'append-only',
      );
      final reservation = await backend.reserve(
        packId: 'org.remath.pack.one',
        requiredBytes: 64,
        version: '1.0.0',
      );
      await reservation.add(const [1, 2, 3]);

      expect(
        () => database.execute(
          'UPDATE content_pack_object_chunks SET content = ?',
          [
            Uint8List.fromList(const [9, 9, 9]),
          ],
        ),
        throwsA(isA<SqliteException>()),
      );
      final sealed = await reservation.seal(
        lengthBytes: 3,
        sha256: 'original-digest',
      );
      expect(await sealed.openRead().expand((chunk) => chunk).toList(), const [
        1,
        2,
        3,
      ]);
    },
  );

  test(
    'staging chunks cannot be deleted before their digest is trusted',
    () async {
      final database = sqlite3.openInMemory();
      addTearDown(database.close);
      final backend = SqliteContentPackInstallationBackend(
        availableBytes: () async => 1024 * 1024,
        database: database,
        idGenerator: () => 'delete-protected',
      );
      final reservation = await backend.reserve(
        packId: 'org.remath.pack.one',
        requiredBytes: 64,
        version: '1.0.0',
      );
      await reservation.add(const [1, 2, 3]);

      expect(
        () => database.execute('DELETE FROM content_pack_object_chunks'),
        throwsA(isA<SqliteException>()),
      );
      final sealed = await reservation.seal(
        lengthBytes: 3,
        sha256: 'original-digest',
      );
      expect(await sealed.openRead().expand((chunk) => chunk).toList(), const [
        1,
        2,
        3,
      ]);
    },
  );

  test('staging parent cannot be deleted before cleanup is recorded', () async {
    final database = sqlite3.openInMemory();
    addTearDown(database.close);
    final backend = SqliteContentPackInstallationBackend(
      availableBytes: () async => 1024 * 1024,
      database: database,
      idGenerator: () => 'parent-delete-protected',
    );
    final reservation = await backend.reserve(
      packId: 'org.remath.pack.one',
      requiredBytes: 64,
      version: '1.0.0',
    );
    await reservation.add(const [1, 2, 3]);

    expect(
      () => database.execute('DELETE FROM content_pack_objects'),
      throwsA(isA<SqliteException>()),
    );
    final sealed = await reservation.seal(
      lengthBytes: 3,
      sha256: 'original-digest',
    );
    expect(await sealed.openRead().expand((chunk) => chunk).toList(), const [
      1,
      2,
      3,
    ]);
  });

  test('sealed objects reject chunks moved from live staging', () async {
    final database = sqlite3.openInMemory();
    addTearDown(database.close);
    var nextId = 0;
    final backend = SqliteContentPackInstallationBackend(
      availableBytes: () async => 1024 * 1024,
      database: database,
      idGenerator: () => 'move-${nextId++}',
    );
    final target = await backend.reserve(
      packId: 'org.remath.pack.target',
      requiredBytes: 64,
      version: '1.0.0',
    );
    await target.add(const [1]);
    final sealed = await target.seal(lengthBytes: 1, sha256: 'target-digest');
    final source = await backend.reserve(
      packId: 'org.remath.pack.source',
      requiredBytes: 64,
      version: '1.0.0',
    );
    await source.add(const [2]);

    expect(
      () => database.execute(
        'UPDATE content_pack_object_chunks SET seal_id = ?, sequence = 99 '
        'WHERE seal_id != ?',
        [sealed.sealId, sealed.sealId],
      ),
      throwsA(isA<SqliteException>()),
    );
    expect(await sealed.openRead().expand((chunk) => chunk).toList(), const [
      1,
    ]);
  });

  test('sealed parent cannot be reopened for chunk mutation', () async {
    final database = sqlite3.openInMemory();
    addTearDown(database.close);
    final backend = SqliteContentPackInstallationBackend(
      availableBytes: () async => 1024 * 1024,
      database: database,
      idGenerator: () => 'immutable-parent',
    );
    final reservation = await backend.reserve(
      packId: 'org.remath.pack.one',
      requiredBytes: 64,
      version: '1.0.0',
    );
    await reservation.add(const [1, 2, 3]);
    final sealed = await reservation.seal(
      lengthBytes: 3,
      sha256: 'sealed-digest',
    );

    expect(
      () => database.execute(
        "UPDATE content_pack_objects SET state = 'staging' WHERE seal_id = ?",
        [sealed.sealId],
      ),
      throwsA(isA<SqliteException>()),
    );
    expect(await sealed.openRead().expand((chunk) => chunk).toList(), const [
      1,
      2,
      3,
    ]);
  });

  test(
    'a newer update waits for the current first load to be confirmed',
    () async {
      final database = sqlite3.openInMemory();
      addTearDown(database.close);
      var nextId = 0;
      final backend = SqliteContentPackInstallationBackend(
        availableBytes: () async => 1024 * 1024,
        database: database,
        idGenerator: () => 'checkpoint-${nextId++}',
      );
      final installer = composeContentPackInstaller(
        backend: backend,
        environment: _Environment(backend),
        signatureVerifier: const _TrustedSignatureVerifier(),
      );
      await installer.install(
        await _release('1.0.0'),
        _Source(utf8.encode(_pack('1.0.0'))),
      );
      final first = await backend.activation('org.remath.pack.one');
      await backend.confirmFirstLoad(
        expectedActivationId: first.activationId,
        packId: 'org.remath.pack.one',
      );
      await installer.install(
        await _release('2.0.0'),
        _Source(utf8.encode(_pack('2.0.0'))),
      );
      final second = await backend.activation('org.remath.pack.one');

      await expectLater(
        installer.install(
          await _release('3.0.0'),
          _Source(utf8.encode(_pack('3.0.0'))),
        ),
        throwsA(
          isA<ContentPackActivationException>().having(
            (error) => error.outcome,
            'outcome',
            ContentPackRetentionOutcome.blockedPendingConfirmation,
          ),
        ),
      );
      final rollback = await backend.rollbackFailedActivation(
        expectedActivationId: second.activationId,
        message: 'Version 2 failed.',
        packId: 'org.remath.pack.one',
      );
      expect(rollback.activeVersion, '1.0.0');
    },
  );

  test(
    'a dependant cannot activate against an unconfirmed dependency',
    () async {
      final database = sqlite3.openInMemory();
      addTearDown(database.close);
      var nextId = 0;
      final backend = SqliteContentPackInstallationBackend(
        availableBytes: () async => 1024 * 1024,
        database: database,
        idGenerator: () => 'pending-dependency-${nextId++}',
      );
      final installer = composeContentPackInstaller(
        backend: backend,
        environment: _Environment(backend),
        signatureVerifier: const _TrustedSignatureVerifier(),
      );
      final dependency = await _release(
        '1.0.0',
        packId: 'org.remath.pack.dependency',
      );
      await installer.install(
        dependency,
        _Source(utf8.encode(_pack('1.0.0', packId: dependency.packId))),
      );
      final dependant = await _release(
        '1.0.0',
        packId: 'org.remath.pack.dependant',
        dependencies: const [
          ContentPackDependency(
            packId: 'org.remath.pack.dependency',
            minimumVersion: '1.0.0',
          ),
        ],
      );

      await expectLater(
        installer.install(
          dependant,
          _Source(utf8.encode(_pack('1.0.0', packId: dependant.packId))),
        ),
        throwsA(
          isA<ContentPackActivationException>().having(
            (error) => error.outcome,
            'outcome',
            ContentPackRetentionOutcome.blockedPendingConfirmation,
          ),
        ),
      );
      final pending = await backend.activation(dependency.packId);
      await backend.rollbackFailedActivation(
        expectedActivationId: pending.activationId,
        message: 'Dependency failed.',
        packId: dependency.packId,
      );
      expect(await backend.activeVersion(dependant.packId), isNull);
    },
  );

  test(
    'activation rejects a downgrade required by an active dependant',
    () async {
      final database = sqlite3.openInMemory();
      addTearDown(database.close);
      var nextId = 0;
      final backend = SqliteContentPackInstallationBackend(
        availableBytes: () async => 1024 * 1024,
        database: database,
        idGenerator: () => 'dependency-${nextId++}',
      );
      final installer = composeContentPackInstaller(
        backend: backend,
        environment: _Environment(backend),
        signatureVerifier: const _TrustedSignatureVerifier(),
      );
      final dependency = await _release(
        '2.0.0',
        packId: 'org.remath.pack.dependency',
      );
      await installer.install(
        dependency,
        _Source(
          utf8.encode(_pack('2.0.0', packId: 'org.remath.pack.dependency')),
        ),
      );
      final dependencyActivation = await backend.activation(dependency.packId);
      await backend.confirmFirstLoad(
        expectedActivationId: dependencyActivation.activationId,
        packId: dependency.packId,
      );
      final dependant = await _release(
        '1.0.0',
        packId: 'org.remath.pack.dependant',
        dependencies: const [
          ContentPackDependency(
            packId: 'org.remath.pack.dependency',
            minimumVersion: '2.0.0',
          ),
        ],
      );
      await installer.install(
        dependant,
        _Source(
          utf8.encode(_pack('1.0.0', packId: 'org.remath.pack.dependant')),
        ),
      );
      final dependantActivation = await backend.activation(dependant.packId);
      await backend.confirmFirstLoad(
        expectedActivationId: dependantActivation.activationId,
        packId: dependant.packId,
      );
      final downgrade = await _release(
        '1.0.0',
        packId: 'org.remath.pack.dependency',
      );

      await expectLater(
        installer.install(
          downgrade,
          _Source(
            utf8.encode(_pack('1.0.0', packId: 'org.remath.pack.dependency')),
          ),
          isExplicitVersionChoice: true,
        ),
        throwsA(
          isA<ContentPackActivationException>().having(
            (error) => error.outcome,
            'outcome',
            ContentPackRetentionOutcome.blockedDependent,
          ),
        ),
      );
      expect(await backend.activeVersion(dependency.packId), '2.0.0');
    },
  );

  test('durable unpin permits a later safe removal', () async {
    final database = sqlite3.openInMemory();
    addTearDown(database.close);
    var nextId = 0;
    final backend = SqliteContentPackInstallationBackend(
      availableBytes: () async => 1024 * 1024,
      database: database,
      idGenerator: () => 'unpin-${nextId++}',
    );
    final installer = composeContentPackInstaller(
      backend: backend,
      environment: _Environment(backend),
      signatureVerifier: const _TrustedSignatureVerifier(),
    );
    final release = await _release('1.0.0');
    await installer.install(release, _Source(utf8.encode(_pack('1.0.0'))));
    await backend.pinActive(
      release.packId,
      expectedState: await backend.retentionState(release.packId),
    );

    final pinned = await backend.retentionState(release.packId);
    final unpinned = await backend.unpinActive(
      release.packId,
      expectedState: pinned,
    );
    final removed = await backend.removeActiveIfAllowed(
      expectedState: unpinned.state,
      packId: release.packId,
    );

    expect(unpinned.state.pinnedVersion, isNull);
    expect(removed.outcome, ContentPackRemovalCommitOutcome.removed);
    expect(await backend.activeVersion(release.packId), isNull);
  });

  test('repeating a durable unpin reports an unchanged state', () async {
    final database = sqlite3.openInMemory();
    addTearDown(database.close);
    var nextId = 0;
    final backend = SqliteContentPackInstallationBackend(
      availableBytes: () async => 1024 * 1024,
      database: database,
      idGenerator: () => 'repeat-unpin-${nextId++}',
    );
    final installer = composeContentPackInstaller(
      backend: backend,
      environment: _Environment(backend),
      signatureVerifier: const _TrustedSignatureVerifier(),
    );
    final release = await _release('1.0.0');
    await installer.install(release, _Source(utf8.encode(_pack('1.0.0'))));
    await backend.pinActive(
      release.packId,
      expectedState: await backend.retentionState(release.packId),
    );
    final first = await backend.unpinActive(
      release.packId,
      expectedState: await backend.retentionState(release.packId),
    );

    final repeated = await backend.unpinActive(
      release.packId,
      expectedState: first.state,
    );

    expect(first.outcome, ContentPackRetentionOutcome.changed);
    expect(repeated.outcome, ContentPackRetentionOutcome.unchanged);
    expect(repeated.state.pinnedVersion, isNull);
  });

  test('stale unpin cannot clear a newer activation pin', () async {
    final database = sqlite3.openInMemory();
    addTearDown(database.close);
    var nextId = 0;
    final backend = SqliteContentPackInstallationBackend(
      availableBytes: () async => 1024 * 1024,
      database: database,
      idGenerator: () => 'unpin-cas-${nextId++}',
    );
    final installer = composeContentPackInstaller(
      backend: backend,
      environment: _Environment(backend),
      signatureVerifier: const _TrustedSignatureVerifier(),
    );
    final firstRelease = await _release('1.0.0');
    await installer.install(firstRelease, _Source(utf8.encode(_pack('1.0.0'))));
    final firstActivation = await backend.activation(firstRelease.packId);
    await backend.confirmFirstLoad(
      expectedActivationId: firstActivation.activationId,
      packId: firstRelease.packId,
    );
    await backend.pinActive(
      firstRelease.packId,
      expectedState: await backend.retentionState(firstRelease.packId),
    );
    final stale = await backend.retentionState(firstRelease.packId);
    await installer.install(
      await _release('2.0.0'),
      _Source(utf8.encode(_pack('2.0.0'))),
      isExplicitVersionChoice: true,
    );

    final result = await backend.unpinActive(
      firstRelease.packId,
      expectedState: stale,
    );

    expect(result.outcome, ContentPackRetentionOutcome.staleState);
    expect(result.state.pinnedVersion, '2.0.0');
  });

  test('stale pin cannot pin a newer activation', () async {
    final database = sqlite3.openInMemory();
    addTearDown(database.close);
    var nextId = 0;
    final backend = SqliteContentPackInstallationBackend(
      availableBytes: () async => 1024 * 1024,
      database: database,
      idGenerator: () => 'pin-cas-${nextId++}',
    );
    final installer = composeContentPackInstaller(
      backend: backend,
      environment: _Environment(backend),
      signatureVerifier: const _TrustedSignatureVerifier(),
    );
    final firstRelease = await _release('1.0.0');
    await installer.install(firstRelease, _Source(utf8.encode(_pack('1.0.0'))));
    final firstActivation = await backend.activation(firstRelease.packId);
    await backend.confirmFirstLoad(
      expectedActivationId: firstActivation.activationId,
      packId: firstRelease.packId,
    );
    final stale = await backend.retentionState(firstRelease.packId);
    await installer.install(
      await _release('2.0.0'),
      _Source(utf8.encode(_pack('2.0.0'))),
    );

    final result = await backend.pinActive(
      firstRelease.packId,
      expectedState: stale,
    );

    expect(result.outcome, ContentPackRetentionOutcome.staleState);
    expect(result.state.installedVersion, '2.0.0');
    expect(result.state.pinnedVersion, isNull);
  });

  test('confirmation retires the previous rollback object', () async {
    final database = sqlite3.openInMemory();
    addTearDown(database.close);
    var nextId = 0;
    final backend = SqliteContentPackInstallationBackend(
      availableBytes: () async => 1024 * 1024,
      database: database,
      idGenerator: () => 'confirm-${nextId++}',
    );
    final installer = composeContentPackInstaller(
      backend: backend,
      environment: _Environment(backend),
      signatureVerifier: const _TrustedSignatureVerifier(),
    );
    await installer.install(
      await _release('1.0.0'),
      _Source(utf8.encode(_pack('1.0.0'))),
    );
    final first = await backend.activation('org.remath.pack.one');
    await backend.confirmFirstLoad(
      expectedActivationId: first.activationId,
      packId: 'org.remath.pack.one',
    );
    await installer.install(
      await _release('2.0.0'),
      _Source(utf8.encode(_pack('2.0.0'))),
    );
    final second = await backend.activation('org.remath.pack.one');

    await backend.confirmFirstLoad(
      expectedActivationId: second.activationId,
      packId: 'org.remath.pack.one',
    );

    expect(
      database
          .select(
            "SELECT COUNT(*) AS count FROM content_pack_objects WHERE state = 'retained'",
          )
          .single['count'],
      0,
    );
    final active = database
        .select('SELECT previous_seal_id FROM content_pack_active')
        .single;
    expect(active['previous_seal_id'], isNull);
  });

  test('retired pack versions do not retain dependency snapshots', () async {
    final database = sqlite3.openInMemory();
    addTearDown(database.close);
    var nextId = 0;
    final backend = SqliteContentPackInstallationBackend(
      availableBytes: () async => 1024 * 1024,
      database: database,
      idGenerator: () => 'dependency-cleanup-${nextId++}',
    );
    final installer = composeContentPackInstaller(
      backend: backend,
      environment: _Environment(backend),
      signatureVerifier: const _TrustedSignatureVerifier(),
    );
    const dependencyPackId = 'org.remath.pack.foundation';
    final dependency = await _release('1.0.0', packId: dependencyPackId);
    await installer.install(
      dependency,
      _Source(utf8.encode(_pack('1.0.0', packId: dependencyPackId))),
    );
    await backend.confirmFirstLoad(
      expectedActivationId: (await backend.activation(
        dependencyPackId,
      )).activationId,
      packId: dependencyPackId,
    );
    const dependencies = [
      ContentPackDependency(minimumVersion: '1.0.0', packId: dependencyPackId),
    ];

    for (final version in const ['1.0.0', '2.0.0']) {
      final release = await _release(version, dependencies: dependencies);
      await installer.install(release, _Source(utf8.encode(_pack(version))));
      await backend.confirmFirstLoad(
        expectedActivationId: (await backend.activation(
          release.packId,
        )).activationId,
        packId: release.packId,
      );
    }
    final failed = await _release('3.0.0', dependencies: dependencies);
    await installer.install(failed, _Source(utf8.encode(_pack('3.0.0'))));
    await backend.rollbackFailedActivation(
      expectedActivationId: (await backend.activation(
        failed.packId,
      )).activationId,
      message: 'Version 3 failed.',
      packId: failed.packId,
    );
    await backend.removeActiveIfAllowed(
      expectedState: await backend.retentionState(failed.packId),
      packId: failed.packId,
    );

    expect(
      database
          .select(
            'SELECT version FROM content_pack_dependencies WHERE pack_id = ?',
            [failed.packId],
          )
          .map((row) => row['version']),
      isEmpty,
    );
  });

  test('duplicate sealed activation is an atomic no-op', () async {
    final database = sqlite3.openInMemory();
    addTearDown(database.close);
    var nextId = 0;
    final backend = SqliteContentPackInstallationBackend(
      availableBytes: () async => 1024 * 1024,
      database: database,
      idGenerator: () => 'duplicate-${nextId++}',
    );
    final store = TransactionalContentPackInstallStore(backend: backend);
    final release = await _release('1.0.0');
    final first = await store.stage(
      release,
      _Source(utf8.encode(_pack('1.0.0'))),
    );
    final duplicate = await store.stage(
      release,
      _Source(utf8.encode(_pack('1.0.0'))),
    );
    await store.activateStaged(release, first, isExplicitVersionChoice: false);
    final before = await backend.activation(release.packId);

    final outcome = await store.activateStaged(
      release,
      duplicate,
      isExplicitVersionChoice: false,
    );
    final after = await backend.activation(release.packId);

    expect(outcome, ContentPackInstallOutcome.alreadyActive);
    expect(after.activationId, before.activationId);
    expect(
      database
          .select('SELECT COUNT(*) AS count FROM content_pack_objects')
          .single['count'],
      1,
    );
  });

  test('activation rejects a cycle in active pack dependencies', () async {
    final database = sqlite3.openInMemory();
    addTearDown(database.close);
    var nextId = 0;
    final backend = SqliteContentPackInstallationBackend(
      availableBytes: () async => 1024 * 1024,
      database: database,
      idGenerator: () => 'cycle-${nextId++}',
    );
    final installer = composeContentPackInstaller(
      backend: backend,
      environment: _Environment(backend),
      signatureVerifier: const _TrustedSignatureVerifier(),
    );
    const packA = 'org.remath.pack.a';
    const packB = 'org.remath.pack.b';
    final firstA = await _release('1.0.0', packId: packA);
    await installer.install(
      firstA,
      _Source(utf8.encode(_pack('1.0.0', packId: packA))),
    );
    await backend.confirmFirstLoad(
      expectedActivationId: (await backend.activation(packA)).activationId,
      packId: packA,
    );
    final releaseB = await _release(
      '1.0.0',
      packId: packB,
      dependencies: const [
        ContentPackDependency(minimumVersion: '1.0.0', packId: packA),
      ],
    );
    await installer.install(
      releaseB,
      _Source(utf8.encode(_pack('1.0.0', packId: packB))),
    );
    await backend.confirmFirstLoad(
      expectedActivationId: (await backend.activation(packB)).activationId,
      packId: packB,
    );
    final cyclicA = await _release(
      '2.0.0',
      packId: packA,
      dependencies: const [
        ContentPackDependency(minimumVersion: '1.0.0', packId: packB),
      ],
    );

    await expectLater(
      installer.install(
        cyclicA,
        _Source(utf8.encode(_pack('2.0.0', packId: packA))),
      ),
      throwsA(
        isA<ContentPackStagingException>().having(
          (error) => error.message,
          'message',
          contains('dependency cycle'),
        ),
      ),
    );
    expect(await backend.activeVersion(packA), '1.0.0');
  });

  test('removal rejects an ABA replacement at the same version', () async {
    final database = sqlite3.openInMemory();
    addTearDown(database.close);
    var nextId = 0;
    final backend = SqliteContentPackInstallationBackend(
      availableBytes: () async => 1024 * 1024,
      database: database,
      idGenerator: () => 'aba-${nextId++}',
    );
    final installer = composeContentPackInstaller(
      backend: backend,
      environment: _Environment(backend),
      signatureVerifier: const _TrustedSignatureVerifier(),
    );
    final release = await _release('1.0.0');
    await installer.install(release, _Source(utf8.encode(_pack('1.0.0'))));
    final stale = await backend.retentionState(release.packId);
    await backend.removeActiveIfAllowed(
      expectedState: stale,
      packId: release.packId,
    );
    await installer.install(release, _Source(utf8.encode(_pack('1.0.0'))));

    final result = await backend.removeActiveIfAllowed(
      expectedState: stale,
      packId: release.packId,
    );

    expect(result.outcome, ContentPackRemovalCommitOutcome.staleState);
    expect(await backend.activeVersion(release.packId), '1.0.0');
  });

  test(
    'sqlite rollback restores, deactivates, and exposes failure status',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'remath-rollback-',
      );
      addTearDown(() => directory.delete(recursive: true));
      final path = '${directory.path}/lifecycle.sqlite3';
      var database = sqlite3.open(path);
      var nextId = 0;
      var backend = SqliteContentPackInstallationBackend(
        availableBytes: () async => 1024 * 1024,
        database: database,
        idGenerator: () => 'rollback-${nextId++}',
      );
      final installer = composeContentPackInstaller(
        backend: backend,
        environment: _Environment(backend),
        signatureVerifier: const _TrustedSignatureVerifier(),
      );
      await installer.install(
        await _release('1.0.0'),
        _Source(utf8.encode(_pack('1.0.0'))),
      );
      final first = await backend.activation('org.remath.pack.one');
      await backend.confirmFirstLoad(
        expectedActivationId: first.activationId,
        packId: 'org.remath.pack.one',
      );
      await installer.install(
        await _release('2.0.0'),
        _Source(utf8.encode(_pack('2.0.0'))),
      );
      final update = await backend.activation('org.remath.pack.one');

      final restored = await backend.rollbackFailedActivation(
        expectedActivationId: update.activationId,
        message: 'Payload-safe failure.',
        packId: 'org.remath.pack.one',
      );
      expect(restored.restored, isTrue);
      expect(restored.activeVersion, '1.0.0');

      final other = await _release('1.0.0', packId: 'org.remath.pack.other');
      await installer.install(
        other,
        _Source(utf8.encode(_pack('1.0.0', packId: 'org.remath.pack.other'))),
      );
      final pending = await backend.activation(other.packId);
      final deactivated = await backend.rollbackFailedActivation(
        expectedActivationId: pending.activationId,
        message: 'First install failed.',
        packId: other.packId,
      );
      expect(deactivated.restored, isTrue);
      expect(deactivated.activeVersion, isNull);
      expect(await backend.activeVersion(other.packId), isNull);

      database.close();
      database = sqlite3.open(path);
      addTearDown(database.close);
      backend = SqliteContentPackInstallationBackend(
        availableBytes: () async => 1024 * 1024,
        database: database,
        idGenerator: () => 'reopened-${nextId++}',
      );
      final failure = await backend.latestFailure('org.remath.pack.one');
      expect(await backend.activeVersion('org.remath.pack.one'), '1.0.0');
      expect(await backend.activeVersion(other.packId), isNull);
      expect(failure?.message, 'Payload-safe failure.');
      await backend.acknowledgeFailure(
        failureId: failure!.failureId,
        packId: failure.packId,
      );
      expect(await backend.latestFailure('org.remath.pack.one'), isNull);
    },
  );
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

Future<ContentPackRelease> _release(
  String version, {
  List<ContentPackDependency> dependencies = const [],
  String packId = 'org.remath.pack.one',
}) async {
  final bytes = utf8.encode(_pack(version, packId: packId));
  final digest = await Sha256().hash(bytes);
  return ContentPackRelease(
    compressedSizeBytes: bytes.length,
    dependencies: dependencies,
    description: 'Original pack.',
    installedSizeBytes: bytes.length,
    language: 'en-GB',
    license: 'CC-BY-SA-4.0',
    manifestVersion: 1,
    minimumAppVersion: '0.1.0',
    minimumSchemaVersion: 1,
    objectives: const ['Learn safely'],
    packId: packId,
    publisherKeyId: 'org.remath.publisher.primary',
    sha256: digest.bytes
        .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
        .join(),
    signature: 'AQID',
    title: 'Pack',
    version: version,
  );
}

String _pack(String version, {String packId = 'org.remath.pack.one'}) =>
    '''
{
  "schemaVersion": 1,
  "id": "$packId",
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
