import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:remath/src/features/learning/application/content_pack_installer.dart';
import 'package:remath/src/features/learning/domain/content_pack_release.dart';

void main() {
  const release = ContentPackRelease(
    compressedSizeBytes: 4,
    dependencies: [],
    description: 'Original algebra lessons and practice.',
    installedSizeBytes: 16,
    language: 'en-GB',
    license: 'CC-BY-SA-4.0',
    manifestVersion: 1,
    minimumAppVersion: '0.1.0',
    minimumSchemaVersion: 3,
    objectives: ['Collect like terms'],
    packId: 'org.remath.algebra.foundation',
    publisherKeyId: 'org.remath.publisher.primary',
    sha256: 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
    signature: 'c2lnbmF0dXJl',
    title: 'Algebra foundation',
    version: '2.0.0',
  );

  test('verifies the bounded bytes read back from staging', () async {
    final events = <String>[];
    final store = _MemoryInstallStore(
      activeVersions: {release.packId: '1.0.0'},
      events: events,
      stagedBytes: const [9, 8, 7, 6],
    );
    final integrityVerifier = _RecordingVerifier(events);
    final installer = ContentPackInstaller(
      guard: _RecordingGuard(events),
      store: store,
      verifier: ContentPackActivationVerifier(
        contentVerifier: _RecordingVerifier(events, label: 'content'),
        integrityVerifier: integrityVerifier,
      ),
    );

    final outcome = await installer.install(
      release,
      _ChunkedArchiveSource(const [
        [1, 2],
        [3, 4],
      ]),
    );

    expect(outcome, ContentPackInstallOutcome.activated);
    expect(events, ['guard', 'stage:2', 'verify', 'content', 'activate']);
    expect(integrityVerifier.verifiedBytes, [9, 8, 7, 6]);
    expect(await store.activeVersion(release.packId), release.version);
    expect(store.hasStagedRelease, isFalse);
  });

  test(
    'verification failure discards staging and preserves active pack',
    () async {
      final events = <String>[];
      final store = _MemoryInstallStore(
        activeVersions: {release.packId: '1.0.0'},
        events: events,
      );
      final installer = ContentPackInstaller(
        guard: _RecordingGuard(events),
        store: store,
        verifier: ContentPackActivationVerifier(
          contentVerifier: _RecordingVerifier(events, label: 'content'),
          integrityVerifier: _RecordingVerifier(events, shouldFail: true),
        ),
      );

      await expectLater(
        installer.install(
          release,
          _ChunkedArchiveSource(const [
            [1, 2, 3, 4],
          ]),
        ),
        throwsA(isA<StateError>()),
      );

      expect(events, ['guard', 'stage:1', 'verify', 'discard']);
      expect(await store.activeVersion(release.packId), '1.0.0');
      expect(store.hasStagedRelease, isFalse);
    },
  );

  test(
    'installing the active version is idempotent and performs no writes',
    () async {
      final events = <String>[];
      final store = _MemoryInstallStore(
        activeVersions: {release.packId: release.version},
        events: events,
      );
      final installer = ContentPackInstaller(
        guard: _RecordingGuard(events),
        store: store,
        verifier: ContentPackActivationVerifier(
          contentVerifier: _RecordingVerifier(events, label: 'content'),
          integrityVerifier: _RecordingVerifier(events),
        ),
      );

      final outcome = await installer.install(
        release,
        _ChunkedArchiveSource(const [
          [1, 2, 3, 4],
        ]),
      );

      expect(outcome, ContentPackInstallOutcome.alreadyActive);
      expect(events, isEmpty);
      expect(store.hasStagedRelease, isFalse);
    },
  );

  test('concurrent duplicate installs share one staged operation', () async {
    final events = <String>[];
    final verificationStarted = Completer<void>();
    final finishVerification = Completer<void>();
    final store = _MemoryInstallStore(activeVersions: {}, events: events);
    final installer = ContentPackInstaller(
      guard: _RecordingGuard(events),
      store: store,
      verifier: ContentPackActivationVerifier(
        contentVerifier: _RecordingVerifier(events, label: 'content'),
        integrityVerifier: _RecordingVerifier(
          events,
          verificationStarted: verificationStarted,
          finishVerification: finishVerification,
        ),
      ),
    );

    final first = installer.install(
      release,
      _ChunkedArchiveSource(const [
        [1, 2, 3, 4],
      ]),
    );
    await verificationStarted.future;
    final duplicate = installer.install(
      release,
      _ChunkedArchiveSource(const [
        [4, 3, 2, 1],
      ]),
    );
    finishVerification.complete();

    expect(await first, ContentPackInstallOutcome.activated);
    expect(await duplicate, ContentPackInstallOutcome.activated);
    expect(events, ['guard', 'stage:1', 'verify', 'content', 'activate']);
  });

  test(
    'concurrent versions serialize before activating the newer one',
    () async {
      final events = <String>[];
      final verificationStarted = Completer<void>();
      final finishVerification = Completer<void>();
      final store = _MemoryInstallStore(activeVersions: {}, events: events);
      final installer = ContentPackInstaller(
        guard: _RecordingGuard(events),
        store: store,
        verifier: ContentPackActivationVerifier(
          contentVerifier: _RecordingVerifier(events, label: 'content'),
          integrityVerifier: _RecordingVerifier(
            events,
            verificationStarted: verificationStarted,
            finishVerification: finishVerification,
          ),
        ),
      );

      final first = installer.install(
        release,
        _ChunkedArchiveSource(const [
          [1, 2, 3, 4],
        ]),
      );
      await verificationStarted.future;
      final newer = installer.install(
        _releaseWithVersion(release, '3.0.0'),
        _ChunkedArchiveSource(const [
          [4, 3, 2, 1],
        ]),
      );
      finishVerification.complete();

      expect(await first, ContentPackInstallOutcome.activated);
      expect(await newer, ContentPackInstallOutcome.activated);
      expect(await store.activeVersion(release.packId), '3.0.0');
      expect(events.where((event) => event == 'activate'), hasLength(2));
    },
  );

  test('unsafe release compatibility fails before staging', () async {
    final events = <String>[];
    final installer = ContentPackInstaller(
      guard: _RecordingGuard(events, shouldFail: true),
      store: _MemoryInstallStore(activeVersions: {}, events: events),
      verifier: ContentPackActivationVerifier(
        contentVerifier: _RecordingVerifier(events, label: 'content'),
        integrityVerifier: _RecordingVerifier(events),
      ),
    );

    await expectLater(
      installer.install(
        release,
        _ChunkedArchiveSource(const [
          [1, 2, 3, 4],
        ]),
      ),
      throwsA(isA<StateError>()),
    );

    expect(events, ['guard']);
  });

  test(
    'installation freezes release metadata before asynchronous work',
    () async {
      final dependencies = <ContentPackDependency>[];
      final objectives = <String>['Collect like terms'];
      final mutableRelease = ContentPackRelease(
        compressedSizeBytes: release.compressedSizeBytes,
        dependencies: dependencies,
        description: release.description,
        installedSizeBytes: release.installedSizeBytes,
        language: release.language,
        license: release.license,
        manifestVersion: release.manifestVersion,
        minimumAppVersion: release.minimumAppVersion,
        minimumSchemaVersion: release.minimumSchemaVersion,
        objectives: objectives,
        packId: release.packId,
        publisherKeyId: release.publisherKeyId,
        sha256: release.sha256,
        signature: release.signature,
        title: release.title,
        version: release.version,
      );
      final guardEntered = Completer<void>();
      final releaseGuard = Completer<void>();
      final events = <String>[];
      final store = _MemoryInstallStore(activeVersions: {}, events: events);
      final installer = ContentPackInstaller(
        guard: _RecordingGuard(
          events,
          entered: guardEntered,
          release: releaseGuard,
        ),
        store: store,
        verifier: ContentPackActivationVerifier(
          contentVerifier: _RecordingVerifier(events, label: 'content'),
          integrityVerifier: _RecordingVerifier(events),
        ),
      );

      final installing = installer.install(
        mutableRelease,
        _ChunkedArchiveSource(const [
          [1, 2, 3, 4],
        ]),
      );
      await guardEntered.future;
      dependencies.add(
        const ContentPackDependency(
          minimumVersion: '99.0.0',
          packId: 'org.remath.changed',
        ),
      );
      objectives[0] = 'Changed after installation began';
      releaseGuard.complete();

      expect(await installing, ContentPackInstallOutcome.activated);
      expect(store.activatedRelease!.dependencies, isEmpty);
      expect(store.activatedRelease!.objectives, ['Collect like terms']);
      expect(
        () => store.activatedRelease!.objectives[0] = 'mutate',
        throwsUnsupportedError,
      );
    },
  );
}

ContentPackRelease _releaseWithVersion(
  ContentPackRelease release,
  String version,
) => ContentPackRelease(
  compressedSizeBytes: release.compressedSizeBytes,
  dependencies: release.dependencies,
  description: release.description,
  installedSizeBytes: release.installedSizeBytes,
  language: release.language,
  license: release.license,
  manifestVersion: release.manifestVersion,
  minimumAppVersion: release.minimumAppVersion,
  minimumSchemaVersion: release.minimumSchemaVersion,
  objectives: release.objectives,
  packId: release.packId,
  publisherKeyId: release.publisherKeyId,
  sha256: release.sha256,
  signature: release.signature,
  title: release.title,
  version: version,
);

final class _RecordingGuard implements ContentPackInstallGuard {
  _RecordingGuard(
    this.events, {
    this.entered,
    this.release,
    this.shouldFail = false,
  });

  final List<String> events;
  final Completer<void>? entered;
  final Completer<void>? release;
  final bool shouldFail;

  @override
  Future<void> validate(ContentPackRelease release) async {
    events.add('guard');
    entered?.complete();
    await this.release?.future;
    if (shouldFail) {
      throw StateError('Release compatibility failed.');
    }
  }
}

final class _ChunkedArchiveSource implements ContentPackArchiveSource {
  const _ChunkedArchiveSource(this.chunks);

  final List<List<int>> chunks;

  @override
  Stream<List<int>> openRead() => Stream.fromIterable(chunks);
}

final class _MemoryStagedArchive implements ContentPackStagedArchive {
  const _MemoryStagedArchive(this.bytes);

  final List<int> bytes;

  @override
  int get lengthBytes => bytes.length;

  @override
  String get sealId => 'memory-seal';

  @override
  String get sha256 =>
      '0000000000000000000000000000000000000000000000000000000000000000';

  @override
  Stream<List<int>> openRead() => Stream.value(bytes);
}

final class _MemoryInstallStore implements ContentPackInstallStore {
  _MemoryInstallStore({
    required Map<String, String> activeVersions,
    required this.events,
    this.stagedBytes,
  }) : _activeVersions = activeVersions;

  final Map<String, String> _activeVersions;
  final List<String> events;
  final List<int>? stagedBytes;
  ContentPackRelease? _stagedRelease;
  _MemoryStagedArchive? _stagedArchive;
  ContentPackRelease? activatedRelease;

  bool get hasStagedRelease => _stagedRelease != null;

  @override
  Future<String?> activeVersion(String packId) async => _activeVersions[packId];

  @override
  Future<void> activateStaged(
    ContentPackRelease release,
    ContentPackStagedArchive archive,
  ) async {
    events.add('activate');
    if (_stagedRelease != release || _stagedArchive != archive) {
      throw StateError('Only the verified staged release can be activated.');
    }
    _activeVersions[release.packId] = release.version;
    activatedRelease = release;
    _stagedRelease = null;
    _stagedArchive = null;
  }

  @override
  Future<void> discardStaged(
    ContentPackRelease release,
    ContentPackStagedArchive archive,
  ) async {
    events.add('discard');
    _stagedRelease = null;
    _stagedArchive = null;
  }

  @override
  Future<ContentPackStagedArchive> stage(
    ContentPackRelease release,
    ContentPackArchiveSource archive,
  ) async {
    final received = <int>[];
    var chunkCount = 0;
    await for (final chunk in archive.openRead()) {
      chunkCount++;
      received.addAll(chunk);
    }
    events.add('stage:$chunkCount');
    _stagedRelease = release;
    return _stagedArchive = _MemoryStagedArchive(
      List.unmodifiable(stagedBytes ?? received),
    );
  }
}

final class _RecordingVerifier implements ContentPackPayloadVerifier {
  _RecordingVerifier(
    this.events, {
    this.label = 'verify',
    this.shouldFail = false,
    this.verificationStarted,
    this.finishVerification,
  });

  final List<String> events;
  final String label;
  final bool shouldFail;
  final Completer<void>? verificationStarted;
  final Completer<void>? finishVerification;
  List<int>? verifiedBytes;

  @override
  Future<void> verify(
    ContentPackRelease release,
    ContentPackStagedArchive archive,
  ) async {
    events.add(label);
    verifiedBytes = await archive.openRead().expand((chunk) => chunk).toList();
    if (verificationStarted case final started? when !started.isCompleted) {
      started.complete();
    }
    await finishVerification?.future;
    if (shouldFail) {
      throw StateError('The staged archive failed verification.');
    }
  }
}
