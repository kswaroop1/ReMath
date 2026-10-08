import 'package:flutter_test/flutter_test.dart';
import 'package:remath/src/features/learning/data/content_pack_release_parser.dart';

void main() {
  test('catalogue manifest exposes the complete install decision', () {
    final release = const ContentPackReleaseParser().parse('''
      {
        "manifestVersion": 1,
        "packId": "org.remath.algebra.foundation",
        "version": "2.1.0",
        "title": "Algebra foundation",
        "description": "Original algebra lessons and practice.",
        "language": "en-GB",
        "license": "CC-BY-SA-4.0",
        "minimumAppVersion": "0.1.0",
        "minimumSchemaVersion": 3,
        "compressedSizeBytes": 2048,
        "installedSizeBytes": 8192,
        "sha256": "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
        "publisherKeyId": "org.remath.publisher.primary",
        "signature": "c2lnbmF0dXJl",
        "dependencies": [
          {
            "packId": "org.remath.arithmetic.foundation",
            "minimumVersion": "1.4.0"
          }
        ],
        "objectives": ["Collect like terms", "Solve linear equations"]
      }
    ''');

    expect(release.manifestVersion, 1);
    expect(release.packId, 'org.remath.algebra.foundation');
    expect(release.version, '2.1.0');
    expect(release.title, 'Algebra foundation');
    expect(release.description, 'Original algebra lessons and practice.');
    expect(release.language, 'en-GB');
    expect(release.license, 'CC-BY-SA-4.0');
    expect(release.minimumAppVersion, '0.1.0');
    expect(release.minimumSchemaVersion, 3);
    expect(release.compressedSizeBytes, 2048);
    expect(release.installedSizeBytes, 8192);
    expect(release.sha256, hasLength(64));
    expect(release.publisherKeyId, 'org.remath.publisher.primary');
    expect(release.signature, 'c2lnbmF0dXJl');
    expect(release.dependencies, hasLength(1));
    expect(
      release.dependencies.single.packId,
      'org.remath.arithmetic.foundation',
    );
    expect(release.dependencies.single.minimumVersion, '1.4.0');
    expect(release.objectives, [
      'Collect like terms',
      'Solve linear equations',
    ]);
  });
}
