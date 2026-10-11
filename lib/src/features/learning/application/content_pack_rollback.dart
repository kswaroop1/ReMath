enum ContentPackRuntimeOutcome { ready, rolledBack, alreadyRecovered }

abstract interface class ContentPackRollbackStore {
  Future<String?> activeVersion(String packId);

  /// Atomically compares the active version, restores the retained version
  /// (or deactivates a first installation), and records [message].
  Future<ContentPackRollbackTransition> rollbackFailedActivation({
    required String expectedFailedVersion,
    required String message,
    required String packId,
  });
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

final class ContentPackRollbackTransition {
  const ContentPackRollbackTransition({
    required this.activeVersion,
    required this.restored,
  });

  final String? activeVersion;
  final bool restored;
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
      final transition = await store.rollbackFailedActivation(
        expectedFailedVersion: version,
        message:
            'Content pack $packId version $version failed its first load. '
            'Restored prior verified content when available.',
        packId: packId,
      );
      return ContentPackRuntimeResult(
        activeVersion: transition.activeVersion,
        outcome: transition.restored
            ? ContentPackRuntimeOutcome.rolledBack
            : ContentPackRuntimeOutcome.alreadyRecovered,
      );
    }
  }
}
