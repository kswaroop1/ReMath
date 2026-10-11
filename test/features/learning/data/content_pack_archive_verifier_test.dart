import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:remath/src/features/learning/application/content_pack_installer.dart';
import 'package:remath/src/features/learning/data/content_pack_archive_verifier.dart';
import 'package:remath/src/features/learning/domain/content_pack_release.dart';

void main() {
  const archiveBytes = [1, 2, 3, 4];
  test('verifies length, digest, and publisher signature', () async {
    final signatures = _RecordingSignatureVerifier();
    final verifier = ContentPackArchiveVerifier(signatureVerifier: signatures);

    await verifier.verify(_release(), _StagedArchive([archiveBytes]));

    expect(signatures.calls, 1);
    expect(signatures.publisherKeyId, 'org.remath.publisher.primary');
    final signedRelease =
        jsonDecode(utf8.decode(signatures.signedPayload!))
            as Map<String, Object?>;
    expect(signedRelease['sha256'], _release().sha256);
    expect(signedRelease['version'], _release().version);
    expect(signatures.signature, [1, 2, 3]);
  });

  test(
    'signature binds install-decision metadata to the archive digest',
    () async {
      final original = _RecordingSignatureVerifier();
      final changed = _RecordingSignatureVerifier();

      await ContentPackArchiveVerifier(
        signatureVerifier: original,
      ).verify(_release(), _StagedArchive([archiveBytes]));
      await ContentPackArchiveVerifier(signatureVerifier: changed).verify(
        _release(title: 'Tampered title', version: '9.9.9'),
        _StagedArchive([archiveBytes]),
      );

      expect(changed.signedPayload, isNot(original.signedPayload));
    },
  );

  test(
    'rejects payload length mismatch before signature verification',
    () async {
      final signatures = _RecordingSignatureVerifier();
      final verifier = ContentPackArchiveVerifier(
        signatureVerifier: signatures,
      );

      await expectLater(
        verifier.verify(
          _release(compressedSizeBytes: 5),
          _StagedArchive([archiveBytes]),
        ),
        throwsA(_verificationFailure('archive length')),
      );
      expect(signatures.calls, 0);
    },
  );

  test('rejects digest mismatch before signature verification', () async {
    final signatures = _RecordingSignatureVerifier();
    final verifier = ContentPackArchiveVerifier(signatureVerifier: signatures);

    await expectLater(
      verifier.verify(
        _release(
          sha256:
              '0000000000000000000000000000000000000000000000000000000000000000',
        ),
        _StagedArchive([archiveBytes]),
      ),
      throwsA(_verificationFailure('SHA-256')),
    );
    expect(signatures.calls, 0);
  });

  test('rejects malformed or untrusted publisher signatures', () async {
    final signatures = _RecordingSignatureVerifier(isTrusted: false);
    final verifier = ContentPackArchiveVerifier(signatureVerifier: signatures);

    await expectLater(
      verifier.verify(_release(), _StagedArchive([archiveBytes])),
      throwsA(_verificationFailure('publisher signature')),
    );
    await expectLater(
      verifier.verify(
        _release(signature: '%%%'),
        _StagedArchive([archiveBytes]),
      ),
      throwsA(_verificationFailure('publisher signature')),
    );
  });
}

Matcher _verificationFailure(String messageFragment) =>
    isA<ContentPackVerificationException>().having(
      (error) => error.message,
      'message',
      contains(messageFragment),
    );

ContentPackRelease _release({
  int compressedSizeBytes = 4,
  String sha256 =
      '9f64a747e1b97f131fabb6b447296c9b6f0201e79fb3c5356e6c77e89b6a806a',
  String signature = 'AQID',
  String title = 'Algebra foundation',
  String version = '2.0.0',
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
  title: title,
  version: version,
);

final class _RecordingSignatureVerifier
    implements ContentPackSignatureVerifier {
  _RecordingSignatureVerifier({this.isTrusted = true});

  final bool isTrusted;
  int calls = 0;
  String? publisherKeyId;
  List<int>? signedPayload;
  List<int>? signature;

  @override
  Future<bool> verify({
    required String publisherKeyId,
    required List<int> signedPayload,
    required List<int> signature,
  }) async {
    calls += 1;
    this.publisherKeyId = publisherKeyId;
    this.signedPayload = signedPayload;
    this.signature = signature;
    return isTrusted;
  }
}

final class _StagedArchive implements ContentPackStagedArchive {
  const _StagedArchive(this.chunks);

  final List<List<int>> chunks;

  @override
  Stream<List<int>> openRead() => Stream.fromIterable(chunks);
}
