import 'dart:convert';

import '../application/content_pack_installer.dart';
import '../domain/content_pack_release.dart';

abstract interface class ContentPackSignatureVerifier {
  Future<bool> verify({
    required String publisherKeyId,
    required List<int> signedPayload,
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
    ContentPackStagedArchive archive,
  ) async {
    if (archive.lengthBytes != release.compressedSizeBytes) {
      throw const ContentPackVerificationException(
        'The archive length does not match its manifest.',
      );
    }

    if (archive.sha256 != release.sha256) {
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
      signedPayload: _signedReleasePayload(release),
      signature: signature,
    );
    if (!isTrusted) {
      throw const ContentPackVerificationException(
        'The publisher signature is not trusted.',
      );
    }
  }

  List<int> _signedReleasePayload(ContentPackRelease release) {
    final dependencies = [...release.dependencies]
      ..sort((left, right) {
        final idComparison = left.packId.compareTo(right.packId);
        return idComparison != 0
            ? idComparison
            : left.minimumVersion.compareTo(right.minimumVersion);
      });
    return utf8.encode(
      jsonEncode({
        'compressedSizeBytes': release.compressedSizeBytes,
        'dependencies': [
          for (final dependency in dependencies)
            {
              'minimumVersion': dependency.minimumVersion,
              'packId': dependency.packId,
            },
        ],
        'description': release.description,
        'installedSizeBytes': release.installedSizeBytes,
        'language': release.language,
        'license': release.license,
        'manifestVersion': release.manifestVersion,
        'minimumAppVersion': release.minimumAppVersion,
        'minimumSchemaVersion': release.minimumSchemaVersion,
        'objectives': release.objectives,
        'packId': release.packId,
        'publisherKeyId': release.publisherKeyId,
        'sha256': release.sha256,
        'title': release.title,
        'version': release.version,
      }),
    );
  }
}
