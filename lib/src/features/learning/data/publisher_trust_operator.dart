import 'sqlite_publisher_trust_store.dart';

/// Explicit local operator boundary, never invoked by pack metadata.
final class PublisherTrustOperator {
  const PublisherTrustOperator({required this.trustStore});

  final SqlitePublisherTrustStore trustStore;

  void enroll({
    required bool confirmed,
    required String publisherId,
    required String keyId,
    required List<int> publicKey,
  }) {
    if (!confirmed) {
      throw StateError('Explicit operator confirmation is required.');
    }
    trustStore.enroll(
      publisherId: publisherId,
      keyId: keyId,
      publicKey: publicKey,
    );
  }
}
