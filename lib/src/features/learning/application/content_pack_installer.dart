import '../domain/content_pack_release.dart';

enum ContentPackInstallOutcome { activated, alreadyActive }

abstract interface class ContentPackInstallStore {
  Future<String?> activeVersion(String packId);

  Future<void> stage(ContentPackRelease release, List<int> archiveBytes);

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
  ) {
    throw UnimplementedError(
      'CP-006 transactional installation is not implemented.',
    );
  }
}
