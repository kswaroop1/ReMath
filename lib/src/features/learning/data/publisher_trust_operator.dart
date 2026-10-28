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
    throw UnimplementedError('SP-006 operator confirmation is not implemented');
  }
}
