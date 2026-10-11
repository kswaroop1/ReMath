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
    ContentPackStagedArchive archive,
  ) => throw UnimplementedError(
    'Bounded archive verification is not implemented',
  );
}
