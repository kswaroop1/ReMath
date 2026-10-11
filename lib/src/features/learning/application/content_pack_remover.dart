import '../domain/content_pack_retention.dart';

abstract interface class ContentPackAvailabilityStore {
  /// Atomically compares [expectedState], checks pins and active dependants,
  /// and removes the pack only when all three conditions still permit it.
  Future<ContentPackRemovalCommit> removeActiveIfAllowed({
    required ContentPackRetentionState expectedState,
    required String packId,
  });
}

enum ContentPackRemovalCommitOutcome {
  removed,
  staleState,
  blockedPinned,
  blockedDependent,
}

final class ContentPackRemovalCommit {
  const ContentPackRemovalCommit({required this.outcome, required this.state});

  final ContentPackRemovalCommitOutcome outcome;
  final ContentPackRetentionState state;
}

final class ContentPackRemover {
  const ContentPackRemover({
    required this.availabilityStore,
    this.retentionPolicy = const ContentPackRetentionPolicy(),
  });

  final ContentPackAvailabilityStore availabilityStore;
  final ContentPackRetentionPolicy retentionPolicy;

  Future<ContentPackRetentionTransition> remove(
    String packId,
    ContentPackRetentionState state,
  ) async {
    final transition = retentionPolicy.remove(state);
    if (transition.outcome == ContentPackRetentionOutcome.changed) {
      final commit = await availabilityStore.removeActiveIfAllowed(
        expectedState: state,
        packId: packId,
      );
      return switch (commit.outcome) {
        ContentPackRemovalCommitOutcome.removed => transition,
        ContentPackRemovalCommitOutcome.staleState =>
          ContentPackRetentionTransition(
            outcome: ContentPackRetentionOutcome.staleState,
            state: commit.state,
          ),
        ContentPackRemovalCommitOutcome.blockedPinned =>
          ContentPackRetentionTransition(
            outcome: ContentPackRetentionOutcome.blockedPinned,
            state: commit.state,
          ),
        ContentPackRemovalCommitOutcome.blockedDependent =>
          ContentPackRetentionTransition(
            outcome: ContentPackRetentionOutcome.blockedDependent,
            state: commit.state,
          ),
      };
    }
    return transition;
  }
}
