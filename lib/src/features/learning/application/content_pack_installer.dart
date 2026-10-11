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

final class ContentPackInstaller {
  ContentPackInstaller({required this.store, required this.verifier});

  final ContentPackInstallStore store;
  final ContentPackPayloadVerifier verifier;

  Future<ContentPackInstallOutcome> install(
    ContentPackRelease release,
    ContentPackArchiveSource archive,
  ) => throw UnimplementedError('Bounded staged installation is not implemented');
}
