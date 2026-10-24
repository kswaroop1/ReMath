enum ContentPackRuntimeOutcome { ready, rolledBack, alreadyRecovered }

abstract interface class ContentPackRollbackStore {
  Future<ContentPackRuntimeActivation> activation(String packId);

  /// Atomically confirms [expectedActivationId] is still pending and marks its
  /// first runtime load complete. Returns the current pointer when it changed.
  Future<ContentPackRuntimeConfirmation> confirmFirstLoad({
    required String expectedActivationId,
    required String packId,
  });

  /// Atomically compares the pending activation, restores the retained version
  /// (or deactivates a first installation), and records [message]. A confirmed
  /// activation must never be restored by this operation.
  Future<ContentPackRollbackTransition> rollbackFailedActivation({
    required String expectedActivationId,
    required String message,
    required String packId,
  });
}

final class ContentPackFailureStatus {
  const ContentPackFailureStatus({
    required this.failureId,
    required this.message,
    required this.packId,
  });

  final String failureId;
  final String message;
  final String packId;
}

abstract interface class ContentPackFailureStatusStore {
  Future<ContentPackFailureStatus?> latestFailure(String packId);

  Future<void> acknowledgeFailure({
    required String failureId,
    required String packId,
  });
}

final class ContentPackRuntimeActivation {
  const ContentPackRuntimeActivation({
    required this.activationId,
    required this.activeVersion,
    required this.awaitingFirstLoad,
  });

  final String activationId;
  final String? activeVersion;
  final bool awaitingFirstLoad;
}

final class ContentPackRuntimeConfirmation {
  const ContentPackRuntimeConfirmation({
    required this.activeVersion,
    required this.confirmed,
  });

  final String? activeVersion;
  final bool confirmed;
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

  Future<ContentPackRuntimeResult> recoverPendingFirstLoad(
    String packId,
  ) async {
    while (true) {
      final activation = await store.activation(packId);
      final version = activation.activeVersion;
      if (version == null || !activation.awaitingFirstLoad) {
        return ContentPackRuntimeResult(
          activeVersion: version,
          outcome: ContentPackRuntimeOutcome.alreadyRecovered,
        );
      }
      final result = await verifyFirstLoad(packId, version);
      final current = await store.activation(packId);
      if (!current.awaitingFirstLoad) return result;
    }
  }

  Future<ContentPackRuntimeResult> verifyFirstLoad(
    String packId,
    String version,
  ) async {
    final activation = await store.activation(packId);
    if (activation.activeVersion != version || !activation.awaitingFirstLoad) {
      return ContentPackRuntimeResult(
        activeVersion: activation.activeVersion,
        outcome: ContentPackRuntimeOutcome.alreadyRecovered,
      );
    }

    try {
      await loader.load(packId, version);
    } on Object {
      final transition = await store.rollbackFailedActivation(
        expectedActivationId: activation.activationId,
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

    final confirmation = await store.confirmFirstLoad(
      expectedActivationId: activation.activationId,
      packId: packId,
    );
    return ContentPackRuntimeResult(
      activeVersion: confirmation.activeVersion,
      outcome: confirmation.confirmed
          ? ContentPackRuntimeOutcome.ready
          : ContentPackRuntimeOutcome.alreadyRecovered,
    );
  }
}
