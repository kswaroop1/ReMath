/// Explicit local trust decisions; content metadata cannot onboard itself.
final class PublisherTrustStore {
  void enroll({
    required String publisherId,
    required String keyId,
    required List<int> publicKey,
  }) => throw UnimplementedError('SP-006 publisher onboarding is not implemented');

  bool isTrusted({
    required String publisherId,
    required String keyId,
    required List<int> publicKey,
  }) => false;
}
