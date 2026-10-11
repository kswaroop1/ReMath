import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:remath/src/features/learning/application/content_pack_installer.dart';
import 'package:remath/src/features/learning/data/content_pack_archive_verifier.dart';
import 'package:remath/src/features/learning/data/content_pack_payload_verifier.dart';
import 'package:remath/src/features/learning/domain/content_pack_release.dart';

void main() {
  test('parses and validates staged curriculum before activation', () async {
    await const ParsedContentPackPayloadVerifier().verify(
      _release(),
      _StagedArchive(utf8.encode(_validPack)),
    );
  });

  test('rejects malformed, invalid, or mismatched staged curriculum', () async {
    final verifier = const ParsedContentPackPayloadVerifier();

    await expectLater(
      verifier.verify(_release(), _StagedArchive(utf8.encode('{'))),
      throwsA(isA<ContentPackPayloadException>()),
    );
    await expectLater(
      verifier.verify(
        _release(),
        _StagedArchive(utf8.encode(_validPack.replaceFirst('skills', 'bad'))),
      ),
      throwsA(isA<ContentPackPayloadException>()),
    );
    await expectLater(
      verifier.verify(
        _release(version: '9.0.0'),
        _StagedArchive(utf8.encode(_validPack)),
      ),
      throwsA(
        isA<ContentPackPayloadException>().having(
          (error) => error.issues,
          'issues',
          contains(contains('version')),
        ),
      ),
    );
  });

  test('reports every release mismatch in staged curriculum', () async {
    await expectLater(
      const ParsedContentPackPayloadVerifier().verify(
        _release(
          license: 'CC-BY-4.0',
          minimumSchemaVersion: 2,
          packId: 'org.remath.pack.changed',
          version: '9.0.0',
        ),
        _StagedArchive(utf8.encode(_validPack)),
      ),
      throwsA(
        isA<ContentPackPayloadException>().having(
          (error) => error.issues,
          'issues',
          hasLength(4),
        ),
      ),
    );
  });

  test('production verifier composes authenticity and content checks', () async {
    final signatures = _TrustedSignatureVerifier();
    final verifier = ProductionContentPackVerifier(
      signatureVerifier: signatures,
    );

    await verifier.verify(
      _release(),
      _StagedArchive(utf8.encode(_validPack)),
    );

    expect(signatures.calls, 1);
  });
}

const _validPack = '''
{
  "schemaVersion": 1,
  "id": "org.remath.pack.one",
  "version": "2.0.0",
  "title": "Pack",
  "license": "CC-BY-SA-4.0",
  "skills": [{"id":"arithmetic.addition","title":"Addition"}],
  "templates": [{
    "id":"arithmetic.addition.template",
    "version":1,
    "skillId":"arithmetic.addition",
    "operation":"addition",
    "minimumOperand":0,
    "maximumOperand":10,
    "fluentTargetSeconds":10
  }]
}
''';

ContentPackRelease _release({
  String license = 'CC-BY-SA-4.0',
  int minimumSchemaVersion = 1,
  String packId = 'org.remath.pack.one',
  String version = '2.0.0',
}) => ContentPackRelease(
  compressedSizeBytes: utf8.encode(_validPack).length,
  dependencies: const [],
  description: 'Original pack.',
  installedSizeBytes: utf8.encode(_validPack).length,
  language: 'en-GB',
  license: license,
  manifestVersion: 1,
  minimumAppVersion: '0.1.0',
  minimumSchemaVersion: minimumSchemaVersion,
  objectives: const ['Learn safely'],
  packId: packId,
  publisherKeyId: 'org.remath.publisher.primary',
  sha256: '0000000000000000000000000000000000000000000000000000000000000000',
  signature: 'AQID',
  title: 'Pack',
  version: version,
);

final class _TrustedSignatureVerifier implements ContentPackSignatureVerifier {
  int calls = 0;

  @override
  Future<bool> verify({
    required String publisherKeyId,
    required List<int> signedPayload,
    required List<int> signature,
  }) async {
    calls++;
    return true;
  }
}

final class _StagedArchive implements ContentPackStagedArchive {
  _StagedArchive(this.bytes);

  final List<int> bytes;

  @override
  int get lengthBytes => bytes.length;

  @override
  String get sealId => 'sealed';

  @override
  String get sha256 =>
      '0000000000000000000000000000000000000000000000000000000000000000';

  @override
  Stream<List<int>> openRead() => Stream.value(bytes);
}
