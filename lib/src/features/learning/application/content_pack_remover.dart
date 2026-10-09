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
  ) {
    throw UnimplementedError(
      'CP-012 progress-preserving removal is not implemented.',
    );
  }
}
