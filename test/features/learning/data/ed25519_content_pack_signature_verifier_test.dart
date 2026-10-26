import 'package:flutter_test/flutter_test.dart';
import 'package:remath/src/features/learning/data/ed25519_content_pack_signature_verifier.dart';
import 'package:remath/src/features/learning/data/sqlite_publisher_trust_store.dart';
import 'package:sqlite3/sqlite3.dart';

List<int> hexBytes(String hex) => [
  for (var index = 0; index < hex.length; index += 2)
    int.parse(hex.substring(index, index + 2), radix: 16),
];

void main() {
  test('malformed signatures are denied without throwing', () async {
    final database = sqlite3.openInMemory();
    addTearDown(database.close);
    final store = SqlitePublisherTrustStore(database: database);
    store.enroll(
      publisherId: 'publisher.rfc',
      keyId: 'key.rfc',
      publicKey: hexBytes(
        'd75a980182b10ab7d54bfed3c964073a'
        '0ee172f3daa62325af021a68f707511a',
      ),
    );
    final verifier = Ed25519ContentPackSignatureVerifier(trustStore: store);
    for (final length in [0, 63, 65]) {
      expect(
        await verifier.verify(
          publisherKeyId: 'key.rfc',
          signedPayload: [],
          signature: List<int>.filled(length, 0),
        ),
        isFalse,
      );
    }
  });

  test('trusted publisher verifies the published Ed25519 vector', () async {
    final database = sqlite3.openInMemory();
    addTearDown(database.close);
    final store = SqlitePublisherTrustStore(database: database);
    // RFC 8032 section 7.1, TEST 1: public key and signature only.
    // https://www.rfc-editor.org/rfc/rfc8032.txt
    store.enroll(
      publisherId: 'publisher.rfc',
      keyId: 'key.rfc',
      publicKey: hexBytes(
        'd75a980182b10ab7d54bfed3c964073a'
        '0ee172f3daa62325af021a68f707511a',
      ),
    );
    final verifier = Ed25519ContentPackSignatureVerifier(trustStore: store);
    expect(
      await verifier.verify(
        publisherKeyId: 'key.rfc',
        signedPayload: [],
        signature: hexBytes(
          'e5564300c360ac729086e2cc806e828a'
          '84877f1eb8e5d974d873e06522490155'
          '5fb8821590a33bacc61e39701cf9b46b'
          'd25bf5f0595bbe24655141438e7a100b',
        ),
      ),
      isTrue,
    );
  });
}
