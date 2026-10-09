import '../domain/content_pack_retention.dart';

abstract interface class ContentPackAvailabilityStore {
  Future<void> removeActive(String packId);
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
      await availabilityStore.removeActive(packId);
    }
    return transition;
  }
}
