import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:remath/src/features/learning/data/content_pack_archive_verifier.dart';
import 'package:remath/src/features/learning/data/ed25519_content_pack_signature_verifier.dart';
import 'package:remath/src/features/learning/data/open_content_pack_lifecycle_native.dart';
import 'package:remath/src/features/learning/data/sqlite_publisher_trust_store.dart';
import 'package:sqlite3/sqlite3.dart';

List<int> hexBytes(String hex) => [
  for (var index = 0; index < hex.length; index += 2)
    int.parse(hex.substring(index, index + 2), radix: 16),
];

void main() {
  test('final authorization requires the verified key to remain trusted', () async {
    final database = sqlite3.openInMemory();
    addTearDown(database.close);
    final store = SqlitePublisherTrustStore(database: database);
    final publicKey = hexBytes(
      'd75a980182b10ab7d54bfed3c964073a'
      '0ee172f3daa62325af021a68f707511a',
    );
    final signature = hexBytes(
      'e5564300c360ac729086e2cc806e828a'
      '84877f1eb8e5d974d873e06522490155'
      '5fb8821590a33bacc61e39701cf9b46b'
      'd25bf5f0595bbe24655141438e7a100b',
    );
    store.enroll(
      publisherId: 'publisher.rfc',
      keyId: 'key.rfc',
      publicKey: publicKey,
    );
    final verifier = Ed25519ContentPackSignatureVerifier(trustStore: store);
    void validate() => verifier.validateAuthorization(
      publisherKeyId: 'key.rfc',
      signedPayload: [],
      signature: signature,
    );
    expect(validate, throwsA(isA<ContentPackVerificationException>()));
    expect(
      await verifier.verify(
        publisherKeyId: 'key.rfc',
        signedPayload: [],
        signature: signature,
      ),
      isTrue,
    );
    expect(validate, returnsNormally);
    expect(
      () => verifier.validateAuthorization(
        publisherKeyId: 'key.rfc',
        signedPayload: [1],
        signature: signature,
      ),
      throwsA(isA<ContentPackVerificationException>()),
    );
    store.revoke(publisherId: 'publisher.rfc', keyId: 'key.rfc');
    expect(validate, throwsA(isA<ContentPackVerificationException>()));
  });

  test(
    'native verification reads durable trust and revocation after restart',
    () async {
      final directory = Directory.systemTemp.createTempSync('remath-verify-');
      addTearDown(() => directory.deleteSync(recursive: true));
      final path = '${directory.path}/trust.sqlite';
      final publicKey = hexBytes(
        'd75a980182b10ab7d54bfed3c964073a'
        '0ee172f3daa62325af021a68f707511a',
      );
      final signature = hexBytes(
        'e5564300c360ac729086e2cc806e828a'
        '84877f1eb8e5d974d873e06522490155'
        '5fb8821590a33bacc61e39701cf9b46b'
        'd25bf5f0595bbe24655141438e7a100b',
      );
      final first = sqlite3.open(path);
      try {
        SqlitePublisherTrustStore(database: first).enroll(
          publisherId: 'publisher.rfc',
          keyId: 'key.rfc',
          publicKey: publicKey,
        );
      } finally {
        first.close();
      }
      final second = sqlite3.open(path);
      try {
        expect(
          await composeContentPackSignatureVerifier(database: second).verify(
            publisherKeyId: 'key.rfc',
            signedPayload: [],
            signature: signature,
          ),
          isTrue,
        );
        SqlitePublisherTrustStore(
          database: second,
        ).revoke(publisherId: 'publisher.rfc', keyId: 'key.rfc');
      } finally {
        second.close();
      }
      final third = sqlite3.open(path);
      addTearDown(third.close);
      expect(
        await composeContentPackSignatureVerifier(database: third).verify(
          publisherKeyId: 'key.rfc',
          signedPayload: [],
          signature: signature,
        ),
        isFalse,
      );
    },
  );

  test('native verifier composition reads explicitly enrolled trust', () async {
    final database = sqlite3.openInMemory();
    addTearDown(database.close);
    SqlitePublisherTrustStore(database: database).enroll(
      publisherId: 'publisher.rfc',
      keyId: 'key.rfc',
      publicKey: hexBytes(
        'd75a980182b10ab7d54bfed3c964073a'
        '0ee172f3daa62325af021a68f707511a',
      ),
    );
    final verifier = composeContentPackSignatureVerifier(database: database);
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

  test(
    'wrong and ambiguous publisher keys cannot verify a signature',
    () async {
      final database = sqlite3.openInMemory();
      addTearDown(database.close);
      final store = SqlitePublisherTrustStore(database: database);
      final signature = hexBytes(
        'e5564300c360ac729086e2cc806e828a'
        '84877f1eb8e5d974d873e06522490155'
        '5fb8821590a33bacc61e39701cf9b46b'
        'd25bf5f0595bbe24655141438e7a100b',
      );
      // RFC 8032 TEST 2 public key cannot verify TEST 1's signature.
      store.enroll(
        publisherId: 'publisher.other',
        keyId: 'key.wrong',
        publicKey: hexBytes(
          '3d4017c3e843895a92b70aa74d1b7ebc'
          '9c982ccf2ec4968cc0cd55f12af4660c',
        ),
      );
      final verifier = Ed25519ContentPackSignatureVerifier(trustStore: store);
      expect(
        await verifier.verify(
          publisherKeyId: 'key.wrong',
          signedPayload: [],
          signature: signature,
        ),
        isFalse,
      );
      final publicKey = hexBytes(
        'd75a980182b10ab7d54bfed3c964073a'
        '0ee172f3daa62325af021a68f707511a',
      );
      for (final publisher in ['publisher.one', 'publisher.two']) {
        store.enroll(
          publisherId: publisher,
          keyId: 'key.ambiguous',
          publicKey: publicKey,
        );
      }
      expect(
        await verifier.verify(
          publisherKeyId: 'key.ambiguous',
          signedPayload: [],
          signature: signature,
        ),
        isFalse,
      );
    },
  );

  test('out-of-range signature values are denied without throwing', () async {
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
    for (final value in [-1, 256]) {
      final signature = List<int>.filled(64, 0);
      signature[0] = value;
      expect(
        await verifier.verify(
          publisherKeyId: 'key.rfc',
          signedPayload: [],
          signature: signature,
        ),
        isFalse,
      );
    }
  });

  test('tampering and loss of publisher trust deny valid signatures', () async {
    final database = sqlite3.openInMemory();
    addTearDown(database.close);
    final store = SqlitePublisherTrustStore(database: database);
    final publicKey = hexBytes(
      'd75a980182b10ab7d54bfed3c964073a'
      '0ee172f3daa62325af021a68f707511a',
    );
    final signature = hexBytes(
      'e5564300c360ac729086e2cc806e828a'
      '84877f1eb8e5d974d873e06522490155'
      '5fb8821590a33bacc61e39701cf9b46b'
      'd25bf5f0595bbe24655141438e7a100b',
    );
    final verifier = Ed25519ContentPackSignatureVerifier(trustStore: store);
    expect(
      await verifier.verify(
        publisherKeyId: 'key.rfc',
        signedPayload: [],
        signature: signature,
      ),
      isFalse,
    );
    store.enroll(
      publisherId: 'publisher.rfc',
      keyId: 'key.rfc',
      publicKey: publicKey,
    );
    expect(
      await verifier.verify(
        publisherKeyId: 'key.rfc',
        signedPayload: [1],
        signature: signature,
      ),
      isFalse,
    );
    final altered = [...signature];
    altered[0] ^= 1;
    expect(
      await verifier.verify(
        publisherKeyId: 'key.rfc',
        signedPayload: [],
        signature: altered,
      ),
      isFalse,
    );
    store.revoke(publisherId: 'publisher.rfc', keyId: 'key.rfc');
    expect(
      await verifier.verify(
        publisherKeyId: 'key.rfc',
        signedPayload: [],
        signature: signature,
      ),
      isFalse,
    );
  });

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
