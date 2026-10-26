import 'package:cryptography/cryptography.dart';

import 'content_pack_archive_verifier.dart';
import 'sqlite_publisher_trust_store.dart';

final class Ed25519ContentPackSignatureVerifier
    implements ContentPackSignatureVerifier {
  const Ed25519ContentPackSignatureVerifier({required this.trustStore});

  final SqlitePublisherTrustStore trustStore;

  @override
  Future<bool> verify({
    required String publisherKeyId,
    required List<int> signedPayload,
    required List<int> signature,
  }) async {
    final publicKey = trustStore.uniquelyTrustedPublicKey(
      keyId: publisherKeyId,
    );
    if (publicKey == null) return false;
    return Ed25519().verify(
      signedPayload,
      signature: Signature(
        signature,
        publicKey: SimplePublicKey(publicKey, type: KeyPairType.ed25519),
      ),
    );
  }
}
