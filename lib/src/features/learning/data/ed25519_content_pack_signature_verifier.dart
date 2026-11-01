import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:cryptography/dart.dart';

import 'content_pack_archive_verifier.dart';
import 'sqlite_publisher_trust_store.dart';

const _maximumPendingAuthorizations = 32;

final class Ed25519ContentPackSignatureVerifier
    implements ContentPackSignatureVerifier {
  Ed25519ContentPackSignatureVerifier({required this.trustStore});

  final SqlitePublisherTrustStore trustStore;
  final Map<String, List<int>> _authorizations = {};

  /// Retained UTF-8 identity and public-key bytes, excluding runtime overhead.
  int get retainedAuthorizationBytes => _authorizations.entries.fold(
    0,
    (total, entry) => total + utf8.encode(entry.key).length + entry.value.length,
  );

  void validateAuthorization({
    required String publisherKeyId,
    required List<int> signedPayload,
    required List<int> signature,
  }) {
    final identity = _authorizationIdentity(publisherKeyId, signedPayload, signature);
    final authorized = _authorizations[identity];
    final current = trustStore.uniquelyTrustedPublicKey(keyId: publisherKeyId);
    if (authorized == null ||
        current == null ||
        current.length != authorized.length) {
      throw const ContentPackVerificationException('Authorization is stale.');
    }
    for (var index = 0; index < authorized.length; index++) {
      if (current[index] != authorized[index]) {
        throw const ContentPackVerificationException('Authorization is stale.');
      }
    }
  }

  @override
  Future<bool> verify({
    required String publisherKeyId,
    required List<int> signedPayload,
    required List<int> signature,
  }) async {
    if (signature.length != 64) return false;
    final publicKey = trustStore.uniquelyTrustedPublicKey(
      keyId: publisherKeyId,
    );
    if (publicKey == null) return false;
    final verified = await Ed25519().verify(
      signedPayload,
      signature: Signature(
        signature,
        publicKey: SimplePublicKey(publicKey, type: KeyPairType.ed25519),
      ),
    );
    if (verified) {
      final identity = _authorizationIdentity(publisherKeyId, signedPayload, signature);
      _authorizations[identity] = List<int>.unmodifiable(publicKey);
      if (_authorizations.length > _maximumPendingAuthorizations) {
        _authorizations.remove(_authorizations.keys.first);
      }
    }
    return verified;
  }
}

String _authorizationIdentity(
  String publisherKeyId,
  List<int> signedPayload,
  List<int> signature,
) => base64Encode(
  const DartSha256().hashSync(
    utf8.encode(jsonEncode([publisherKeyId, signedPayload, signature])),
  ).bytes,
);
