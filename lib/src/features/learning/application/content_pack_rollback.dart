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
  ) async {
    final activeVersion = await store.activeVersion(packId);
    if (activeVersion != version) {
      return ContentPackRuntimeResult(
        activeVersion: activeVersion,
        outcome: ContentPackRuntimeOutcome.alreadyRecovered,
      );
    }

    try {
      await loader.load(packId, version);
      return ContentPackRuntimeResult(
        activeVersion: version,
        outcome: ContentPackRuntimeOutcome.ready,
      );
    } on Object {
      final previousVersion = await store.retainedPreviousVersion(packId);
      await store.restorePrevious(packId);
      await store.recordFailure(
        packId,
        'Content pack $packId version $version failed its first load. '
        'Restored verified version $previousVersion.',
      );
      return ContentPackRuntimeResult(
        activeVersion: previousVersion,
        outcome: ContentPackRuntimeOutcome.rolledBack,
      );
    }
  }
}
