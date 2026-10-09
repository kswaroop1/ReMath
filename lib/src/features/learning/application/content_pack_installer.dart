import '../domain/content_pack_release.dart';

enum ContentPackInstallOutcome { activated, alreadyActive }

abstract interface class ContentPackInstallStore {
  Future<String?> activeVersion(String packId);

  Future<void> stage(ContentPackRelease release, List<int> archiveBytes);

  /// Atomically replaces the active pointer and consumes the staged release.
  Future<void> activateStaged(ContentPackRelease release);

  Future<void> discardStaged(ContentPackRelease release);
}

abstract interface class ContentPackPayloadVerifier {
  Future<void> verify(ContentPackRelease release, List<int> archiveBytes);
}

final class ContentPackInstaller {
  const ContentPackInstaller({required this.store, required this.verifier});

  final ContentPackInstallStore store;
  final ContentPackPayloadVerifier verifier;

  Future<ContentPackInstallOutcome> install(
    ContentPackRelease release,
    List<int> archiveBytes,
  ) async {
    if (await store.activeVersion(release.packId) == release.version) {
      return ContentPackInstallOutcome.alreadyActive;
    }

    try {
      await store.stage(release, archiveBytes);
      await verifier.verify(release, archiveBytes);
      await store.activateStaged(release);
      return ContentPackInstallOutcome.activated;
    } catch (_) {
      await store.discardStaged(release);
      rethrow;
    }
  }
}
