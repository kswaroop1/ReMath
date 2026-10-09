import 'package:flutter_test/flutter_test.dart';
import 'package:remath/src/features/learning/data/content_pack_release_validator.dart';
import 'package:remath/src/features/learning/domain/content_pack_release.dart';

void main() {
  const validator = ContentPackReleaseValidator();

  test('validator reports every unsafe release contract together', () {
    const release = ContentPackRelease(
      compressedSizeBytes: 0,
      dependencies: [
        ContentPackDependency(minimumVersion: 'one', packId: 'invalid'),
        ContentPackDependency(minimumVersion: '1.0.0', packId: 'invalid'),
        ContentPackDependency(
          minimumVersion: '1.0.0',
          packId: 'org.remath.unsafe',
        ),
      ],
      description: 'Unsafe release',
      installedSizeBytes: -1,
      language: 'not a language',
      license: 'Proprietary',
      manifestVersion: 99,
      minimumAppVersion: 'next',
      minimumSchemaVersion: 99,
      objectives: ['', ''],
      packId: 'org.remath.unsafe',
      publisherKeyId: 'INVALID',
      sha256: 'ABC',
      signature: 'not base64!',
      title: 'Unsafe',
      version: 'one',
    );

    final issues = validator.validate(release);

    expect(issues, contains(contains('manifestVersion')));
    expect(issues, contains(contains('semantic versioning')));
    expect(issues, contains(contains('minimum app version')));
    expect(issues, contains(contains('schemaVersion')));
    expect(issues, contains(contains('language')));
    expect(issues, contains(contains('licence')));
    expect(issues, contains(contains('compressed size')));
    expect(issues, contains(contains('installed size')));
    expect(issues, contains(contains('SHA-256')));
    expect(issues, contains(contains('publisher key')));
    expect(issues, contains(contains('signature')));
    expect(issues, contains(contains('dependency id')));
    expect(issues, contains(contains('dependency version')));
    expect(issues, contains(contains('Duplicate dependency')));
    expect(issues, contains(contains('cannot depend on itself')));
    expect(issues, contains(contains('objective')));
    expect(() => issues.add('mutate'), throwsUnsupportedError);
  });

  test('compatible release metadata is accepted', () {
    const release = ContentPackRelease(
      compressedSizeBytes: 2048,
      dependencies: [
        ContentPackDependency(
          minimumVersion: '1.4.0',
          packId: 'org.remath.arithmetic.foundation',
        ),
      ],
      description: 'Original algebra lessons and practice.',
      installedSizeBytes: 8192,
      language: 'en-GB',
      license: 'CC-BY-SA-4.0',
      manifestVersion: 1,
      minimumAppVersion: '0.1.0',
      minimumSchemaVersion: 3,
      objectives: ['Collect like terms'],
      packId: 'org.remath.algebra.foundation',
      publisherKeyId: 'org.remath.publisher.primary',
      sha256:
          'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
      signature: 'c2lnbmF0dXJl',
      title: 'Algebra foundation',
      version: '2.1.0',
    );

    expect(validator.validate(release), isEmpty);
  });
}
