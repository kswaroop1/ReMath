import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:remath/src/features/learning/application/content_pack_installer.dart';
import 'package:remath/src/features/learning/data/content_pack_install_store.dart';
import 'package:remath/src/features/learning/domain/content_pack_release.dart';

void main() {
  test(
    'staging rejects an oversized stream before persisting overflow',
    () async {
      final backend = _MemoryBackend(availableBytes: 100);
      final store = TransactionalContentPackInstallStore(backend: backend);

      await expectLater(
        store.stage(
          _release(compressedSizeBytes: 4),
          _ArchiveSource(const [
            [1, 2, 3],
            [4, 5],
          ]),
        ),
        throwsA(isA<ContentPackStagingException>()),
      );

      expect(backend.writtenBytes, [1, 2, 3]);
      expect(backend.abortCount, 1);
      expect(backend.reservedBytes, 0);
    },
  );

  test('staging preserves its failure when abort also fails', () async {
    final backend = _MemoryBackend(availableBytes: 100)
      ..abortFailure = StateError('abort interrupted');
    final store = TransactionalContentPackInstallStore(backend: backend);

    await expectLater(
      store.stage(
        _release(compressedSizeBytes: 4),
        _ArchiveSource(const [
          [1, 2, 3],
          [4, 5],
        ]),
      ),
      throwsA(
        isA<ContentPackStagingException>().having(
          (error) => error.message,
          'message',
          contains('exceeds its declared 4 byte limit'),
        ),
      ),
    );

    expect(backend.abortCount, 1);
  });

  test(
    'capacity is reserved before bytes from concurrent packs are accepted',
    () async {
      final backend = _MemoryBackend(availableBytes: 35);
      final store = TransactionalContentPackInstallStore(backend: backend);
      final firstWrite = Completer<void>();
      final releaseFirst = Completer<void>();
      backend.firstWrite = firstWrite;
      backend.releaseFirst = releaseFirst;

      final first = store.stage(
        _release(packId: 'org.remath.pack.one'),
        _ArchiveSource(const [
          [1, 2, 3, 4],
        ]),
      );
      await firstWrite.future;
      await expectLater(
        store.stage(
          _release(packId: 'org.remath.pack.two'),
          _ArchiveSource(const [
            [5, 6, 7, 8],
          ]),
        ),
        throwsA(isA<ContentPackStagingException>()),
      );
      releaseFirst.complete();
      final staged = await first;

      expect(staged.lengthBytes, 4);
      expect(staged.sha256, isNotEmpty);
      expect(staged.sealId, isNotEmpty);
      expect(backend.maximumReservedBytes, 20);
      await store.discardStaged(_release(), staged);
      expect(backend.reservedBytes, 0);
    },
  );

  test(
    'activation commits the exact sealed object and release atomically',
    () async {
      final backend = _MemoryBackend(availableBytes: 100);
      final store = TransactionalContentPackInstallStore(backend: backend);
      final release = _release();
      final staged = await store.stage(
        release,
        _ArchiveSource(const [
          [1, 2, 3, 4],
        ]),
      );

      await store.activateStaged(
        release,
        staged,
        isExplicitVersionChoice: false,
      );

      expect(backend.activatedSealId, staged.sealId);
      expect(backend.activatedDependencies, release.dependencies);
    },
  );

  test('staging hashes the same frozen bytes that it writes', () async {
    final backend = _MemoryBackend(availableBytes: 100);
    final store = TransactionalContentPackInstallStore(backend: backend);
    final writeStarted = Completer<void>();
    final releaseWrite = Completer<void>();
    final mutableChunk = <int>[1, 2, 3, 4];
    backend.firstWrite = writeStarted;
    backend.releaseFirst = releaseWrite;

    final staging = store.stage(_release(), _ArchiveSource([mutableChunk]));
    await writeStarted.future;
    mutableChunk[0] = 9;
    releaseWrite.complete();

    final staged = await staging;
    expect(backend.writtenBytes, [1, 2, 3, 4]);
    expect(
      staged.sha256,
      '9f64a747e1b97f131fabb6b447296c9b6f0201e79fb3c5356e6c77e89b6a806a',
    );
  });

  test('staging bounds persisted rows for empty and tiny chunks', () async {
    final backend = _MemoryBackend(availableBytes: 100);
    final store = TransactionalContentPackInstallStore(backend: backend);

    final staged = await store.stage(
      _release(),
      _ArchiveSource(const [
        [],
        [1],
        [],
        [2],
        [3],
        [4],
        [],
      ]),
    );

    expect(staged.lengthBytes, 4);
    expect(backend.writtenBytes, [1, 2, 3, 4]);
    expect(backend.addCount, 1);
  });
}

ContentPackRelease _release({
  int compressedSizeBytes = 4,
  String packId = 'org.remath.pack.one',
}) => ContentPackRelease(
  compressedSizeBytes: compressedSizeBytes,
  dependencies: const [
    ContentPackDependency(
      minimumVersion: '1.0.0',
      packId: 'org.remath.foundation',
    ),
  ],
  description: 'Original pack.',
  installedSizeBytes: 16,
  language: 'en-GB',
  license: 'CC-BY-SA-4.0',
  manifestVersion: 1,
  minimumAppVersion: '0.1.0',
  minimumSchemaVersion: 3,
  objectives: const ['Learn safely'],
  packId: packId,
  publisherKeyId: 'org.remath.publisher.primary',
  sha256: '9f64a747e1b97f131fabb6b447296c9b6f0201e79fb3c5356e6c77e89b6a806a',
  signature: 'AQID',
  title: 'Pack',
  version: '2.0.0',
);

final class _ArchiveSource implements ContentPackArchiveSource {
  const _ArchiveSource(this.chunks);

  final List<List<int>> chunks;

  @override
  Stream<List<int>> openRead() => Stream.fromIterable(chunks);
}

final class _MemoryBackend implements ContentPackInstallationBackend {
  _MemoryBackend({required this.availableBytes});

  int availableBytes;
  int addCount = 0;
  int abortCount = 0;
  Object? abortFailure;
  List<ContentPackDependency>? activatedDependencies;
  String? activatedSealId;
  Completer<void>? firstWrite;
  int maximumReservedBytes = 0;
  Completer<void>? releaseFirst;
  int reservedBytes = 0;
  final List<int> writtenBytes = [];

  @override
  Future<String?> activeVersion(String packId) async => null;

  @override
  Future<ContentPackInstallOutcome> activateAtomically({
    required bool isExplicitVersionChoice,
    required ContentPackRelease release,
    required ContentPackSealedObject sealed,
  }) async {
    activatedSealId = sealed.sealId;
    activatedDependencies = release.dependencies;
    return ContentPackInstallOutcome.activated;
  }

  @override
  Future<void> discard(ContentPackSealedObject sealed) async {
    reservedBytes -= sealed.reservedBytes;
  }

  @override
  Future<void> retryPendingDiscards() async {}

  @override
  Future<ContentPackStagingSink> reserve({
    required String packId,
    required int requiredBytes,
    required String version,
  }) async {
    if (requiredBytes > availableBytes - reservedBytes) {
      throw const ContentPackStagingException(
        'Insufficient reserved capacity.',
      );
    }
    reservedBytes += requiredBytes;
    maximumReservedBytes = reservedBytes > maximumReservedBytes
        ? reservedBytes
        : maximumReservedBytes;
    return _MemorySink(this, requiredBytes);
  }
}

final class _MemorySink implements ContentPackStagingSink {
  _MemorySink(this.backend, this.reservedBytes);

  final _MemoryBackend backend;
  final int reservedBytes;
  final List<int> bytes = [];

  @override
  Future<void> abort() async {
    backend.abortCount++;
    backend.reservedBytes -= reservedBytes;
    final failure = backend.abortFailure;
    if (failure != null) {
      throw failure;
    }
  }

  @override
  Future<void> add(List<int> chunk) async {
    backend.addCount++;
    bytes.addAll(chunk);
    backend.writtenBytes.addAll(chunk);
    backend.firstWrite?.complete();
    await backend.releaseFirst?.future;
  }

  @override
  Future<ContentPackSealedObject> seal({
    required int lengthBytes,
    required String sha256,
  }) async => _MemorySealedObject(
    bytes: List.unmodifiable(bytes),
    reservedBytes: reservedBytes,
    sealId: '$sha256:$lengthBytes',
  );
}

final class _MemorySealedObject implements ContentPackSealedObject {
  const _MemorySealedObject({
    required this.bytes,
    required this.reservedBytes,
    required this.sealId,
  });

  final List<int> bytes;

  @override
  final int reservedBytes;

  @override
  final String sealId;

  @override
  Stream<List<int>> openRead() => Stream.value(bytes);
}
