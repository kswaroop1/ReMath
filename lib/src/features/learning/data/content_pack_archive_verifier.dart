import 'dart:convert';

import 'package:cryptography/cryptography.dart';

import '../application/content_pack_installer.dart';
import '../domain/content_pack_release.dart';

abstract interface class ContentPackSignatureVerifier {
  Future<bool> verify({
    required String publisherKeyId,
    required List<int> payloadDigest,
    required List<int> signature,
  });
}

final class ContentPackVerificationException implements Exception {
  const ContentPackVerificationException(this.message);

  final String message;

  @override
  String toString() => message;
}

final class ContentPackArchiveVerifier implements ContentPackPayloadVerifier {
  const ContentPackArchiveVerifier({required this.signatureVerifier});

  final ContentPackSignatureVerifier signatureVerifier;

  @override
  Future<void> verify(
    ContentPackRelease release,
    List<int> archiveBytes,
  ) async {
    if (archiveBytes.length != release.compressedSizeBytes) {
      throw const ContentPackVerificationException(
        'The archive length does not match its manifest.',
      );
    }

    final digest = await Sha256().hash(archiveBytes);
    final actualSha256 = digest.bytes
        .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
        .join();
    if (actualSha256 != release.sha256) {
      throw const ContentPackVerificationException(
        'The archive SHA-256 does not match its manifest.',
      );
    }

    late final List<int> signature;
    try {
      signature = base64Decode(release.signature);
    } on FormatException {
      throw const ContentPackVerificationException(
        'The publisher signature is malformed.',
      );
    }
    final isTrusted = await signatureVerifier.verify(
      publisherKeyId: release.publisherKeyId,
      payloadDigest: digest.bytes,
      signature: signature,
    );
    if (!isTrusted) {
      throw const ContentPackVerificationException(
        'The publisher signature is not trusted.',
      );
    }
  }
}
