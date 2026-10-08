import 'package:flutter_test/flutter_test.dart';
import 'package:remath/src/features/learning/data/content_pack_archive_verifier.dart';
import 'package:remath/src/features/learning/domain/content_pack_release.dart';

void main() {
  const archiveBytes = [1, 2, 3, 4];
  const digest = [
    159,
    100,
    167,
    71,
    225,
    185,
    127,
    19,
    31,
    171,
    182,
    180,
    71,
    41,
    108,
    155,
    111,
    2,
    1,
    231,
    159,
    179,
    197,
    53,
    110,
    108,
    119,
    232,
    155,
    106,
    128,
    106,
  ];

  test('verifies length, digest, and publisher signature', () async {
    final signatures = _RecordingSignatureVerifier();
    final verifier = ContentPackArchiveVerifier(
      signatureVerifier: signatures,
    );

    await verifier.verify(_release(), archiveBytes);

    expect(signatures.calls, 1);
    expect(signatures.publisherKeyId, 'org.remath.publisher.primary');
    expect(signatures.payloadDigest, digest);
    expect(signatures.signature, [1, 2, 3]);
  });

  test('rejects payload length mismatch before signature verification', () async {
    final signatures = _RecordingSignatureVerifier();
    final verifier = ContentPackArchiveVerifier(
      signatureVerifier: signatures,
    );

    await expectLater(
      verifier.verify(_release(compressedSizeBytes: 5), archiveBytes),
      throwsA(_verificationFailure('archive length')),
    );
    expect(signatures.calls, 0);
  });

  test('rejects digest mismatch before signature verification', () async {
    final signatures = _RecordingSignatureVerifier();
    final verifier = ContentPackArchiveVerifier(
      signatureVerifier: signatures,
    );

    await expectLater(
      verifier.verify(
        _release(
          sha256:
              '0000000000000000000000000000000000000000000000000000000000000000',
        ),
        archiveBytes,
      ),
      throwsA(_verificationFailure('SHA-256')),
    );
    expect(signatures.calls, 0);
  });

  test('rejects malformed or untrusted publisher signatures', () async {
    final signatures = _RecordingSignatureVerifier(isTrusted: false);
    final verifier = ContentPackArchiveVerifier(
      signatureVerifier: signatures,
    );

    await expectLater(
      verifier.verify(_release(), archiveBytes),
      throwsA(_verificationFailure('publisher signature')),
    );
    await expectLater(
      verifier.verify(_release(signature: '%%%'), archiveBytes),
      throwsA(_verificationFailure('publisher signature')),
    );
  });
}

Matcher _verificationFailure(String messageFragment) => isA<ContentPackVerificationException>()
    .having((error) => error.message, 'message', contains(messageFragment));

ContentPackRelease _release({
  int compressedSizeBytes = 4,
  String sha256 = '9f64a747e1b97f131fabb6b447296c9b6f0201e79fb3c5356e6c77e89b6a806a',
  String signature = 'AQID',
}) => ContentPackRelease(
  compressedSizeBytes: compressedSizeBytes,
  dependencies: const [],
  description: 'Original algebra lessons and practice.',
  installedSizeBytes: 16,
  language: 'en-GB',
  license: 'CC-BY-SA-4.0',
  manifestVersion: 1,
  minimumAppVersion: '0.1.0',
  minimumSchemaVersion: 3,
  objectives: const ['Collect like terms'],
  packId: 'org.remath.algebra.foundation',
  publisherKeyId: 'org.remath.publisher.primary',
  sha256: sha256,
  signature: signature,
  title: 'Algebra foundation',
  version: '2.0.0',
);

final class _RecordingSignatureVerifier implements ContentPackSignatureVerifier {
  _RecordingSignatureVerifier({this.isTrusted = true});

  final bool isTrusted;
  int calls = 0;
  String? publisherKeyId;
  List<int>? payloadDigest;
  List<int>? signature;

  @override
  Future<bool> verify({
    required String publisherKeyId,
    required List<int> payloadDigest,
    required List<int> signature,
  }) async {
    calls += 1;
    this.publisherKeyId = publisherKeyId;
    this.payloadDigest = payloadDigest;
    this.signature = signature;
    return isTrusted;
  }
}
