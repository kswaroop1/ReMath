enum ContentPackRuntimeOutcome { ready, rolledBack, alreadyRecovered }

abstract interface class ContentPackRollbackStore {
  Future<String?> activeVersion(String packId);

  Future<String> retainedPreviousVersion(String packId);

  Future<void> restorePrevious(String packId);

  Future<void> recordFailure(String packId, String message);
}

abstract interface class ContentPackRuntimeLoader {
  Future<void> load(String packId, String version);
}

final class ContentPackRuntimeResult {
  const ContentPackRuntimeResult({
    required this.activeVersion,
    required this.outcome,
  });

  final String? activeVersion;
  final ContentPackRuntimeOutcome outcome;
}

final class ContentPackRollbackCoordinator {
  const ContentPackRollbackCoordinator({
    required this.loader,
    required this.store,
  });

  final ContentPackRuntimeLoader loader;
  final ContentPackRollbackStore store;

  Future<ContentPackRuntimeResult> verifyFirstLoad(
    String packId,
    String version,
  ) {
    throw UnimplementedError('CP-013 runtime rollback is not implemented.');
  }
}
