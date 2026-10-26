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
    return false;
  }
}
