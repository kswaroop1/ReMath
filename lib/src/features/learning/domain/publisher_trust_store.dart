/// Explicit local trust decisions; content metadata cannot onboard itself.
final class PublisherTrustStore {
  final _keys = <(String, String), List<int>>{};

  void enroll({
    required String publisherId,
    required String keyId,
    required List<int> publicKey,
  }) {
    if (publicKey.length != 32 ||
        publicKey.any((byte) => byte < 0 || byte > 255)) {
      throw ArgumentError('An Ed25519 public key requires 32 bytes.');
    }
    if (_keys.containsKey((publisherId, keyId))) {
      if (!isTrusted(
        publisherId: publisherId,
        keyId: keyId,
        publicKey: publicKey,
      )) {
        throw StateError('An enrolled key identity cannot be replaced.');
      }
      return;
    }
    _keys[(publisherId, keyId)] = List<int>.unmodifiable(publicKey);
  }

  bool isTrusted({
    required String publisherId,
    required String keyId,
    required List<int> publicKey,
  }) {
    final trusted = _keys[(publisherId, keyId)];
    if (trusted == null || trusted.length != publicKey.length) return false;
    for (var index = 0; index < trusted.length; index++) {
      if (trusted[index] != publicKey[index]) return false;
    }
    return true;
  }
}
