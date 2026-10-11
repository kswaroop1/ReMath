import '../domain/content_pack_release.dart';

enum ContentPackInstallOutcome { activated, alreadyActive }

abstract interface class ContentPackArchiveSource {
  Stream<List<int>> openRead();
}

abstract interface class ContentPackStagedArchive {
  Stream<List<int>> openRead();
}

abstract interface class ContentPackInstallStore {
  Future<String?> activeVersion(String packId);

  Future<ContentPackStagedArchive> stage(
    ContentPackRelease release,
    ContentPackArchiveSource archive,
  );

  /// Atomically replaces the active pointer and consumes [archive].
  Future<void> activateStaged(
    ContentPackRelease release,
    ContentPackStagedArchive archive,
  );

  Future<void> discardStaged(
    ContentPackRelease release,
    ContentPackStagedArchive archive,
  );
}

abstract interface class ContentPackPayloadVerifier {
  Future<void> verify(
    ContentPackRelease release,
    ContentPackStagedArchive archive,
  );
}

final class ContentPackActivationVerifier
    implements ContentPackPayloadVerifier {
  const ContentPackActivationVerifier({
    required this.contentVerifier,
    required this.integrityVerifier,
  });

  final ContentPackPayloadVerifier contentVerifier;
  final ContentPackPayloadVerifier integrityVerifier;

  @override
  Future<void> verify(
    ContentPackRelease release,
    ContentPackStagedArchive archive,
  ) async {
    await integrityVerifier.verify(release, archive);
    await contentVerifier.verify(release, archive);
  }
}

abstract interface class ContentPackInstallGuard {
  Future<void> validate(ContentPackRelease release);
}

final class ContentPackInstaller {
  ContentPackInstaller({
    required this.guard,
    required this.store,
    required this.verifier,
  });

  final ContentPackInstallGuard guard;
  final ContentPackInstallStore store;
  final ContentPackActivationVerifier verifier;
  final Map<String, Future<ContentPackInstallOutcome>> _inFlight = {};
  final Map<String, String> _inFlightVersions = {};

  Future<ContentPackInstallOutcome> install(
    ContentPackRelease release,
    ContentPackArchiveSource archive,
  ) {
    final existing = _inFlight[release.packId];
    if (existing != null) {
      if (_inFlightVersions[release.packId] == release.version) {
        return existing;
      }
      return existing
          .then<void>((_) {}, onError: (_) {})
          .then((_) => install(release, archive));
    }

    late final Future<ContentPackInstallOutcome> tracked;
    tracked = _install(release, archive).whenComplete(() {
      if (identical(_inFlight[release.packId], tracked)) {
        _inFlight.remove(release.packId);
        _inFlightVersions.remove(release.packId);
      }
    });
    _inFlight[release.packId] = tracked;
    _inFlightVersions[release.packId] = release.version;
    return tracked;
  }

  Future<ContentPackInstallOutcome> _install(
    ContentPackRelease release,
    ContentPackArchiveSource archive,
  ) async {
    if (await store.activeVersion(release.packId) == release.version) {
      return ContentPackInstallOutcome.alreadyActive;
    }

    await guard.validate(release);
    final staged = await store.stage(release, archive);
    try {
      await verifier.verify(release, staged);
      await store.activateStaged(release, staged);
      return ContentPackInstallOutcome.activated;
    } catch (_) {
      await store.discardStaged(release, staged);
      rethrow;
    }
  }
}
