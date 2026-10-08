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
  const archiveBytes = [1, 2, 3, 4];

  test('stages and verifies a complete pack before atomic activation', () async {
    final events = <String>[];
    final store = _MemoryInstallStore(
      activeVersions: {release.packId: '1.0.0'},
      events: events,
    );
    final installer = ContentPackInstaller(
      store: store,
      verifier: _RecordingVerifier(events),
    );

    final outcome = await installer.install(release, archiveBytes);

    expect(outcome, ContentPackInstallOutcome.activated);
    expect(events, ['stage', 'verify', 'activate']);
    expect(await store.activeVersion(release.packId), release.version);
    expect(store.hasStagedRelease, isFalse);
  });

  test('verification failure discards staging and preserves active pack', () async {
    final events = <String>[];
    final store = _MemoryInstallStore(
      activeVersions: {release.packId: '1.0.0'},
      events: events,
    );
    final installer = ContentPackInstaller(
      store: store,
      verifier: _RecordingVerifier(events, shouldFail: true),
    );

    await expectLater(
      installer.install(release, archiveBytes),
      throwsA(isA<StateError>()),
    );

    expect(events, ['stage', 'verify', 'discard']);
    expect(await store.activeVersion(release.packId), '1.0.0');
    expect(store.hasStagedRelease, isFalse);
  });

  test('installing the active version is idempotent and performs no writes', () async {
    final events = <String>[];
    final store = _MemoryInstallStore(
      activeVersions: {release.packId: release.version},
      events: events,
    );
    final installer = ContentPackInstaller(
      store: store,
      verifier: _RecordingVerifier(events),
    );

    final outcome = await installer.install(release, archiveBytes);

    expect(outcome, ContentPackInstallOutcome.alreadyActive);
    expect(events, isEmpty);
    expect(store.hasStagedRelease, isFalse);
  });
}

final class _MemoryInstallStore implements ContentPackInstallStore {
  _MemoryInstallStore({
    required Map<String, String> activeVersions,
    required this.events,
  }) : _activeVersions = activeVersions;

  final Map<String, String> _activeVersions;
  final List<String> events;
  ContentPackRelease? _stagedRelease;

  bool get hasStagedRelease => _stagedRelease != null;

  @override
  Future<String?> activeVersion(String packId) async => _activeVersions[packId];

  @override
  Future<void> activateStaged(ContentPackRelease release) async {
    events.add('activate');
    if (_stagedRelease != release) {
      throw StateError('Only a complete staged release can be activated.');
    }
    _activeVersions[release.packId] = release.version;
    _stagedRelease = null;
  }

  @override
  Future<void> discardStaged(ContentPackRelease release) async {
    events.add('discard');
    _stagedRelease = null;
  }

  @override
  Future<void> stage(ContentPackRelease release, List<int> archiveBytes) async {
    events.add('stage');
    _stagedRelease = release;
  }
}

final class _RecordingVerifier implements ContentPackPayloadVerifier {
  _RecordingVerifier(this.events, {this.shouldFail = false});

  final List<String> events;
  final bool shouldFail;

  @override
  Future<void> verify(ContentPackRelease release, List<int> archiveBytes) async {
    events.add('verify');
    if (shouldFail) {
      throw StateError('The staged archive failed verification.');
    }
  }
}
